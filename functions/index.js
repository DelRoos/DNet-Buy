/**
 * Cloud Functions Freemopay — version optimisée (a→e)
 * - Réservation après paiement
 * - Réponse immédiate (déclenchement Freemopay via trigger Firestore)
 * - Lectures Firestore parallélisées
 * - .select() pour limiter les données
 * - Cache mémoire plans (TTL 5 min)
 */
const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ maxInstances: 10 });

/* ================== CONFIG ================== */
const PROJECT_ID = "dnet-29b02";
const REGION = "us-central1";
const FREEMOPAY_CONFIG = {
  baseUrl: "https://api-v2.freemopay.com",
  appKey: "0c96c26a-ffe5-490d-a150-ecf97545be9d",
  secretKey: "2uM2OeqnuMeo9fc1E6oB",
  timeout: 5000,
};
const WEBHOOK_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/handleFreemopayWebhook`;

/* ================== UTILS ================== */
const now = () => admin.firestore.Timestamp.now();

function formatCameroonPhone(phoneNumber) {
  if (!phoneNumber) throw new Error("Numéro de téléphone requis");
  let formatted = phoneNumber.replace(/\D/g, "");
  if (phoneNumber.startsWith("+237")) formatted = phoneNumber.substring(1);
  else if (formatted.startsWith("00237")) formatted = formatted.substring(2);
  else if (!formatted.startsWith("237")) {
    if (formatted.startsWith("0")) formatted = formatted.substring(1);
    formatted = `237${formatted}`;
  }
  if (formatted.length !== 12 || !formatted.startsWith("237")) {
    throw new Error(`Format de numéro invalide: ${phoneNumber} -> ${formatted}`);
  }
  return formatted;
}

function validateFreemopayConfig() {
  if (!FREEMOPAY_CONFIG.appKey) throw new Error("App Key manquante");
  if (!FREEMOPAY_CONFIG.secretKey) throw new Error("Secret Key manquante");
}

function getBasicAuthHeader() {
  const token = Buffer.from(
    `${FREEMOPAY_CONFIG.appKey}:${FREEMOPAY_CONFIG.secretKey}`
  ).toString("base64");
  return `Basic ${token}`;
}

async function callFreemopay(endpoint, payload, timeoutMs = FREEMOPAY_CONFIG.timeout) {
  const url = `${FREEMOPAY_CONFIG.baseUrl}${endpoint}`;
  const headers = { Authorization: getBasicAuthHeader(), "Content-Type": "application/json" };
  logger.info("➡️ Freemopay call", { url, payload: { ...payload, secretKey: undefined } });
  const resp = await axios.post(url, payload, { headers, timeout: timeoutMs });
  logger.info("⬅️ Freemopay response", { status: resp.status, data: resp.data });
  return resp.data;
}

/* ================== FORMATAGE DUREE ================== */
function formatValidityDuration(hours) {
  if (hours < 24) return `${hours}h`;
  if (hours < 168) {
    const d = Math.floor(hours / 24); return `${d} jour${d > 1 ? "s" : ""}`;
  }
  if (hours < 720) {
    const w = Math.floor(hours / 168); return `${w} semaine${w > 1 ? "s" : ""}`;
  }
  const m = Math.floor(hours / 720); return `${m} mois`;
}

/* ================== CACHE PLANS (TTL 5 min) ================== */
const planCache = new Map(); // key: planId -> {data, exp:number}
const PLAN_TTL_MS = 5 * 60 * 1000;

async function getPlanCached(planId) {
  const hit = planCache.get(planId);
  if (hit && Date.now() < hit.exp) return hit.data;

  const FieldPath = admin.firestore.FieldPath;
  const qs = await db.collection("ticket_types")
    .where(FieldPath.documentId(), "==", planId)
    .select("price", "isActive", "name", "validityHours")
    .limit(1)
    .get();

  if (qs.empty) throw new HttpsError("not-found", "Forfait introuvable");
  const data = qs.docs[0].data();

  planCache.set(planId, { data, exp: Date.now() + PLAN_TTL_MS });
  return data;
}

async function reserveTicketForPlan(planId) {
  const snap = await db.collection("tickets")
    .where("ticketTypeId", "==", planId)
    .where("status", "==", "available")
    .limit(1)
    .get();

  if (snap.empty) return null;

  const doc = snap.docs[0];
  await doc.ref.update({
    status: "reserved",
    reservedAt: now(),
  });

  return { id: doc.id, ...doc.data() };
}



/* ================== API PUBLIQUE DES FORFAITS ================== */
exports.getPublicTicketTypes = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");

  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { zoneId, publicKey } = req.query;
    if (!zoneId) return res.status(400).json({ error: "Zone ID requis" });

    const zoneDoc = await db.collection("zones").doc(zoneId).get();
    if (!zoneDoc.exists) return res.status(404).json({ error: "Zone non trouvée" });

    const zone = zoneDoc.data();
    if (!zone.isActive) return res.status(403).json({ error: "Zone non accessible publiquement" });
    if (zone.publicAccessKey && publicKey !== zone.publicAccessKey) {
      return res.status(403).json({ error: "Clé d'accès invalide" });
    }

    const ticketTypesSnapshot = await db.collection("ticket_types")
      .where("zoneId", "==", zoneId)
      .where("isActive", "==", true)
      .orderBy("price", "asc")
      .get();

    const plans = await Promise.all(ticketTypesSnapshot.docs.map(async (doc) => {
      const data = doc.data();
      // simple ping dispo (limité)
      const availableTicketsSnapshot = await db.collection("tickets")
        .where("ticketTypeId", "==", doc.id).where("status", "==", "available").limit(1).get();

      const isAvailable = !availableTicketsSnapshot.empty;
      return {
        id: doc.id,
        name: data.name,
        description: data.description,
        price: data.price,
        formattedPrice: `${Number(data.price).toLocaleString()} F`,
        validityHours: data.validityHours,
        validityText: formatValidityDuration(data.validityHours),
        isAvailable,
        rateLimit: data.rateLimit || null,
        hasPromotion: !!(data.originalPrice && data.originalPrice > data.price),
        originalPrice: data.originalPrice || null,
      };
    }));

    const availablePlans = plans.filter(p => p.isAvailable);
    return res.json({
      success: true,
      zone: { id: zoneId, name: zone.name, description: zone.description, location: zone.location, routerType: zone.routerType },
      plans: availablePlans,
      totalPlans: availablePlans.length,
      lastUpdated: new Date().toISOString(),
    });
  } catch (e) {
    logger.error("getPublicTicketTypes error", e);
    return res.status(500).json({ success: false, error: "Erreur interne du serveur" });
  }
});

/* ============================================================
   INIT PAYMENT — Réponse immédiate (b) + parallélisation (c) + cache (e)
   Note: pas de réservation ici (a)
   ============================================================ */
  exports.initiatePublicPayment = onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });

    try {
      validateFreemopayConfig();
      const { planId, phoneNumber } = req.body || {};
      if (!planId || !phoneNumber) return res.status(400).json({ error: "planId et phoneNumber sont requis" });

      const phone = formatCameroonPhone(phoneNumber);
      const planData = await getPlanCached(planId);
      if (!planData.isActive) throw new HttpsError("failed-precondition", "Forfait inactif");

      // ✅ Réservation ticket
      const reservedTicket = await reserveTicketForPlan(planId);
      if (!reservedTicket) return res.status(409).json({ error: "Aucun ticket disponible" });

      // ✅ ID transaction
      const txnRef = db.collection("transactions").doc();
      const txnId = txnRef.id;

await txnRef.set({
  createdAt: now(),
  updatedAt: now(),
  status: "created",
  provider: "freemopay",
  amount: planData.price,
  currency: "XAF",
  planId,
  phone,
  externalId: txnId,
  freemopayReference: null,
  webhookReceived: false,
  reservedTicketId: reservedTicket.id,
  planName: planData.name,
  ticketTypeName: formatValidityDuration(planData.validityHours),
});

      return res.json({
        success: true,
        transactionId: txnId,
        amount: planData.price,
        status: "created",
      });
    } catch (err) {
      logger.error("initiatePublicPayment error", err);
      return res.status(500).json({ error: err.message || "Erreur interne" });
    }
  });

/* ===================================================================
   TRIGGER: quand une transaction est créée -> appel Freemopay (b)
   =================================================================== */
exports.onTransactionCreated = onDocumentCreated("transactions/{transactionId}", async (event) => {
  try {
    const txnId = event.params.transactionId;
    const tx = event.data?.data();
    if (!tx || tx.status !== "created") return;

    // Init paiement
    const payload = {
      amount: tx.amount,
      externalId: tx.externalId || txnId,   // chez nous: = txnId
      callback: WEBHOOK_URL,
      payer: tx.phone,
    };
    const data = await callFreemopay("/api/v2/payment", payload);

    await db.collection("transactions").doc(txnId).update({
      status: "pending",
      updatedAt: now(),
      freemopayReference: data.reference || null,
      providerInitResponse: data,
    });

    // ✅ Fast path: 2s plus tard on regarde si le statut est déjà final
    if (data.reference) {
      setTimeout(async () => {
        try {
          const st = await getPaymentStatusByReference(data.reference);
          const s = String(st?.status || "").toUpperCase();
          if (s === "SUCCESS" || s === "FAILED") {
            // Simule le webhook pour finaliser immédiatement
            const fakeReq = { body: { status: s, reference: data.reference, externalId: txnId, message: st?.message || null } };
            const fakeRes = { status: () => ({ send: () => {} }) };
            await exports.handleFreemopayWebhook.run(fakeReq, fakeRes); // gcf v2: appelle la même logique
          }
        } catch (_) { /* ignore: si PENDING, le webhook finira le job */ }
      }, 2000);
    }
  } catch (e) {
    logger.error("onTransactionCreated error", e);
    if (event?.params?.transactionId) {
      await db.collection("transactions").doc(event.params.transactionId).update({
        status: "failed",
        updatedAt: now(),
        providerStatus: "INIT_FAILED",
      });
    }
  }
});


/* ===========================================
   CHECK TRANSACTION — poll depuis le frontend
   =========================================== */
// ✅ NOUVELLE VERSION SÉCURISÉE
exports.checkTransactionStatus = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { transactionId } = req.query;
    if (!transactionId) return res.status(400).json({ error: "transactionId requis" });

    const doc = await db.collection("transactions").doc(String(transactionId)).get();
    if (!doc.exists) return res.status(404).json({ error: "Transaction introuvable" });
    
    const tx = doc.data();

    // ✅ SÉCURITÉ : Données de base toujours accessibles
    const responseData = {
      id: doc.id,
      status: tx.status,
      amount: tx.amount,
      freemopayReference: tx.freemopayReference || null,
      ticketTypeName: tx.ticketTypeName || null,
      updatedAt: tx.updatedAt?.toDate?.()?.toISOString?.() || null,
      planName: tx.planName || null
    };
    
    // ✅ SÉCURITÉ CRITIQUE : Credentials UNIQUEMENT si paiement réellement completed
    if (tx.status === "completed" && tx.credentials && tx.credentials.username && tx.credentials.password) {
      responseData.credentials = {
        username: tx.credentials.username,
        password: tx.credentials.password
      };
      logger.info(`Credentials fournis pour transaction ${transactionId}`);
    } else {
      // ✅ Log de sécurité
      if (tx.status !== "completed") {
        logger.info(`Credentials non fournis - statut: ${tx.status} pour transaction ${transactionId}`);
      }
    }

    return res.json({
      success: true,
      transaction: responseData,
    });
  } catch (e) {
    logger.error("checkTransactionStatus error", e);
    return res.status(500).json({ error: "Erreur interne" });
  }
});

/* ==================================================================
   WEBHOOK Freemopay — délivrance ticket (a) (pas de réservation avant)
   ================================================================== */
exports.handleFreemopayWebhook = onRequest(async (req, res) => {
  const t0 = Date.now();
  const logStep = (msg) => logger.info(`⏱ [handleFreemopayWebhook] ${msg} — ${Date.now() - t0} ms écoulées`);

  try {
    logStep("Webhook reçu");

    const { status, reference, externalId, message } = req.body || {};
    if (!status || (!externalId && !reference)) {
      return res.status(400).send("Missing status or ID");
    }

    let txnRef = null, snap = null;

    // 🔹 1) Lecture directe par externalId (doc.get)
    if (externalId) {
      txnRef = db.collection("transactions").doc(String(externalId));
      snap = await txnRef.get();
    }
    logStep("Lecture transaction par externalId");

    // 🔹 2) Fallback par reference si pas trouvé
    if ((!snap || !snap.exists) && reference) {
      const byRef = await db.collection("transactions")
        .where("freemopayReference", "==", reference)
        .limit(1)
        .get();
      if (!byRef.empty) {
        snap = byRef.docs[0];
        txnRef = snap.ref;
      }
    }

    if (!snap || !snap.exists) return res.status(404).send("transaction not found");
    const tx = snap.data();

    // 🔹 3) Si déjà traité, on marque juste webhookReceived
    if (["completed", "failed", "expired"].includes(tx.status)) {
      await txnRef.update({ webhookReceived: true, updatedAt: now() });
      return res.status(200).send("");
    }

    const s = String(status).toUpperCase();

if (String(status).toUpperCase() === "SUCCESS") {
  logStep("Paiement réussi - génération des credentials");
  
  let credentials = null;
  let ticketUpdate = null;
  
  // ✅ Récupérer et valider le ticket réservé
  if (tx.reservedTicketId) {
    try {
      const ticketDoc = await db.collection("tickets").doc(tx.reservedTicketId).get();
      
      if (ticketDoc.exists) {
        const ticketData = ticketDoc.data();
        
        // ✅ Vérification de sécurité : ticket doit être "reserved"
        if (ticketData.status === "reserved") {
          credentials = {
            username: ticketData.username,
            password: ticketData.password
          };
          
          // ✅ Marquer le ticket comme utilisé de façon atomique
          ticketUpdate = {
            status: "used",
            usedAt: now(),
            transactionId: txnRef.id,
            // ✅ Supprimer la réservation
            reservedAt: admin.firestore.FieldValue.delete()
          };
          
          logStep("Credentials générés avec succès");
        } else {
          logger.warn(`Ticket ${tx.reservedTicketId} n'est pas dans le bon état: ${ticketData.status}`);
        }
      } else {
        logger.error(`Ticket réservé ${tx.reservedTicketId} introuvable`);
      }
    } catch (ticketError) {
      logger.error("Erreur lors de la récupération du ticket:", ticketError);
    }
  }
  
  // ✅ Mise à jour atomique avec batch
  const batch = db.batch();
  
  // Mise à jour de la transaction
  batch.update(txnRef, {
    status: "completed",
    updatedAt: now(),
    providerStatus: status,
    webhookReceived: true,
    providerMessage: message || null,
    freemopayReference: reference || tx.freemopayReference || null,
    ticketTypeName: tx.ticketTypeName || null,
    credentials: credentials, // ✅ Credentials générés ici UNIQUEMENT
    completedAt: now() // ✅ Timestamp de completion
  });
  
  // Mise à jour du ticket si nécessaire
  if (ticketUpdate && tx.reservedTicketId) {
    batch.update(db.collection("tickets").doc(tx.reservedTicketId), ticketUpdate);
  }
  
  await batch.commit();
  logStep("Transaction et ticket mis à jour avec succès");
  
  return res.status(200).send("");
}

// ✅ NOUVEAU CODE FAILED/EXPIRED SÉCURISÉ
if (String(status).toUpperCase() === "FAILED" || String(status).toUpperCase() === "EXPIRED") {
  logStep("Paiement échoué - nettoyage des ressources");
  
  const batch = db.batch();
  
  // ✅ Libérer le ticket réservé
  if (tx.reservedTicketId) {
    batch.update(db.collection("tickets").doc(tx.reservedTicketId), {
      status: "available",
      reservedAt: admin.firestore.FieldValue.delete(),
      // ✅ Nettoyer toute trace de la transaction échouée
      transactionId: admin.firestore.FieldValue.delete()
    });
    logStep("Ticket libéré");
  }
  
  // ✅ Mise à jour sécurisée de la transaction
  batch.update(txnRef, {
    status: status.toLowerCase() === "expired" ? "expired" : "failed",
    updatedAt: now(),
    providerStatus: status,
    webhookReceived: true,
    providerMessage: message || "Paiement échoué ou expiré",
    failedAt: now(), // ✅ Timestamp d'échec
    // ✅ SÉCURITÉ : Supprimer toute trace de credentials
    credentials: admin.firestore.FieldValue.delete(),
    reservedTicketId: admin.firestore.FieldValue.delete() // ✅ Nettoyer la référence
  });
  
  await batch.commit();
  logStep("Nettoyage terminé");
  
  return res.status(200).send("");
}
  } catch (e) {
    logger.error("handleFreemopayWebhook error", e);
    return res.status(200).send(""); // éviter retries agressifs
  }
});


// ✅ FONCTION DE NETTOYAGE AMÉLIORÉE
exports.cleanExpiredReservations = onSchedule(
  {
    schedule: "every 5 minutes",
    region: "us-central1",
    timeZone: "Africa/Douala",
  },
  async () => {
    const nowTs = admin.firestore.Timestamp.now();
    const limitTs = admin.firestore.Timestamp.fromMillis(
      Date.now() - 10 * 60 * 1000
    ); // 10 min avant

    try {
      // ✅ 1) Nettoyer les tickets réservés expirés
      const expiredTicketsSnap = await db.collection("tickets")
        .where("status", "==", "reserved")
        .where("reservedAt", "<", limitTs)
        .limit(50)
        .get();

      // ✅ 2) Nettoyer les transactions orphelines (created/pending trop anciennes)
      const expiredTransactionsSnap = await db.collection("transactions")
        .where("status", "in", ["created", "pending"])
        .where("createdAt", "<", limitTs)
        .limit(50)
        .get();

      if (expiredTicketsSnap.empty && expiredTransactionsSnap.empty) {
        return logger.info("✅ Aucun élément expiré à nettoyer");
      }

      const batch = db.batch();
      let ticketsFreed = 0;
      let transactionsCleaned = 0;

      // ✅ Libérer les tickets expirés
      for (const ticketDoc of expiredTicketsSnap.docs) {
        batch.update(ticketDoc.ref, {
          status: "available",
          reservedAt: admin.firestore.FieldValue.delete(),
          transactionId: admin.firestore.FieldValue.delete()
        });
        ticketsFreed++;
      }

      // ✅ Marquer les transactions expirées
      for (const txDoc of expiredTransactionsSnap.docs) {
        const txData = txDoc.data();
        
        batch.update(txDoc.ref, {
          status: "expired",
          updatedAt: nowTs,
          expiredAt: nowTs,
          providerMessage: "Transaction expirée - délai dépassé",
          // ✅ SÉCURITÉ : Nettoyer les credentials potentiels
          credentials: admin.firestore.FieldValue.delete(),
          reservedTicketId: admin.firestore.FieldValue.delete()
        });
        transactionsCleaned++;
      }

      await batch.commit();
      logger.info(`♻️ Nettoyage terminé - ${ticketsFreed} tickets libérés, ${transactionsCleaned} transactions expirées`);
      
    } catch (error) {
      logger.error("Erreur lors du nettoyage automatique:", error);
    }
  }
);

async function getPaymentStatusByReference(reference) {
  const url = `${FREEMOPAY_CONFIG.baseUrl}/api/v2/payment/${reference}`;
  // --- Basic Auth (doc officielle) ---
  const auth = {
    username: FREEMOPAY_CONFIG.appKey,
    password: FREEMOPAY_CONFIG.secretKey
  };
  try {
    const resp = await axios.get(url, { auth, timeout: FREEMOPAY_CONFIG.timeout });
    return resp.data; // attendu: { status: "PENDING"|"SUCCESS"|"FAILED", reference: "...", ... }
  } catch (err) {
    // si rate limit, respecte Retry-After
    if (err?.response?.status === 429) {
      const ra = Number(err.response.headers["retry-after"] || 1);
      await new Promise(r => setTimeout(r, Math.min(ra, 5) * 1000));
    }
    throw err;
  }
}



/* ================== RÉCUPÉRER TICKETS PAR TÉLÉPHONE ================== */
exports.getUserTicketsByPhone = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { phoneNumber, limit = 20 } = req.query;
    if (!phoneNumber) return res.status(400).json({ error: "Numéro de téléphone requis" });

    // Formater le numéro de téléphone
    const formattedPhone = formatCameroonPhone(phoneNumber);
    
    // Récupérer les transactions réussies pour ce numéro (du plus récent au plus ancien)
    const transactionsSnapshot = await db.collection("transactions")
      .where("phone", "==", formattedPhone)
      .where("status", "==", "completed")
      .orderBy("completedAt", "desc")
      .limit(parseInt(limit))
      .get();

    if (transactionsSnapshot.empty) {
      return res.json({
        success: true,
        tickets: [],
        message: "Aucun ticket trouvé pour ce numéro"
      });
    }

    // Formater les données des tickets
    const tickets = transactionsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        transactionId: doc.id,
        planName: data.planName,
        ticketTypeName: data.ticketTypeName,
        amount: data.amount,
        formattedAmount: `${Number(data.amount).toLocaleString()} F`,
        credentials: data.credentials || null,
        completedAt: data.completedAt?.toDate?.()?.toISOString?.() || null,
        freemopayReference: data.freemopayReference || null,
        planId: data.planId || null
      };
    });

    return res.json({
      success: true,
      tickets,
      phoneNumber: formattedPhone,
      totalTickets: tickets.length
    });

  } catch (e) {
    logger.error("getUserTicketsByPhone error", e);
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});


/* ================== VENTE MANUELLE DE TICKETS ================== */
exports.manualTicketSale = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { ticketId, phoneNumber, description, adminUserId } = req.body || {};
    
    if (!ticketId || !phoneNumber || !adminUserId) {
      return res.status(400).json({ 
        error: "ticketId, phoneNumber et adminUserId sont requis" 
      });
    }

    // Formater le numéro de téléphone
    const formattedPhone = formatCameroonPhone(phoneNumber);
    
    // Vérifier que le ticket existe et est disponible
    const ticketDoc = await db.collection("tickets").doc(ticketId).get();
    if (!ticketDoc.exists) {
      return res.status(404).json({ error: "Ticket introuvable" });
    }

    const ticketData = ticketDoc.data();
    if (ticketData.status !== "available") {
      return res.status(400).json({ 
        error: `Ticket non disponible (statut: ${ticketData.status})` 
      });
    }

    // Récupérer les informations du type de ticket
    const ticketTypeDoc = await db.collection("ticket_types")
      .doc(ticketData.ticketTypeId)
      .get();
    
    if (!ticketTypeDoc.exists) {
      return res.status(404).json({ error: "Type de ticket introuvable" });
    }

    const ticketTypeData = ticketTypeDoc.data();
    
    // Créer une transaction simulée
    const transactionRef = db.collection("transactions").doc();
    const transactionId = transactionRef.id;

    // Utiliser un batch pour la cohérence des données
    const batch = db.batch();

    // 1. Créer la transaction simulée
    batch.set(transactionRef, {
      createdAt: now(),
      updatedAt: now(),
      completedAt: now(),
      status: "completed",
      provider: "manual_sale",
      amount: ticketTypeData.price,
      currency: "XAF",
      planId: ticketData.ticketTypeId,
      phone: formattedPhone,
      externalId: transactionId,
      freemopayReference: `MANUAL_${Date.now()}`,
      webhookReceived: true,
      planName: ticketTypeData.name,
      ticketTypeName: formatValidityDuration(ticketTypeData.validityHours),
      credentials: {
        username: ticketData.username,
        password: ticketData.password
      },
      // Données spécifiques à la vente manuelle
      isManualSale: true,
      adminUserId: adminUserId,
      saleDescription: description || "Vente manuelle",
      manualSaleAt: now(),
    });

    // 2. Marquer le ticket comme vendu
    batch.update(db.collection("tickets").doc(ticketId), {
      status: "used",
      usedAt: now(),
      soldAt: now(), // Ajouter soldAt pour les statistiques
      transactionId: transactionId,
      buyerPhone: formattedPhone,
      saleType: "manual",
      adminUserId: adminUserId,
      saleDescription: description || "Vente manuelle",
    });

    await batch.commit();

    logger.info("✅ Vente manuelle effectuée avec succès", {
      ticketId,
      transactionId,
      phoneNumber: formattedPhone,
      adminUserId,
      amount: ticketTypeData.price
    });

    return res.json({
      success: true,
      transactionId,
      ticket: {
        username: ticketData.username,
        password: ticketData.password,
        planName: ticketTypeData.name,
        amount: ticketTypeData.price,
        formattedAmount: `${Number(ticketTypeData.price).toLocaleString()} F`,
        phoneNumber: formattedPhone,
        saleDate: new Date().toISOString()
      }
    });

  } catch (e) {
    logger.error("manualTicketSale error", e);
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});


/* ================== NOUVELLES APIS POUR LES TRANSACTIONS DE ZONE ================== */

// Fonction utilitaire pour récupérer les IDs des types de tickets d'une zone
async function getZoneTicketTypeIds(zoneId) {
  try {
    const ticketTypesSnapshot = await db.collection("ticket_types")
      .where("zoneId", "==", zoneId)
      .select()
      .get();
    return ticketTypesSnapshot.docs.map(doc => doc.id);
  } catch (error) {
    logger.error("getZoneTicketTypeIds error", error);
    return [];
  }
}

/* ================== API: RÉCUPÉRER LES TRANSACTIONS D'UNE ZONE ================== */
exports.getZoneTransactions = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { 
      zoneId, 
      statusFilter, 
      limit = 50, 
      page = 0,
      search,
      startDate,
      endDate,
      status
    } = req.query;
    if (!zoneId) return res.status(400).json({ error: "zoneId requis" });

    // Vérifier que la zone existe
    const zoneDoc = await db.collection("zones").doc(zoneId).get();
    if (!zoneDoc.exists) {
      return res.status(404).json({ error: "Zone non trouvée" });
    }

    // Récupérer les IDs des types de tickets de cette zone
    const ticketTypeIds = await getZoneTicketTypeIds(zoneId);
    if (ticketTypeIds.length === 0) {
      return res.json({
        success: true,
        transactions: [],
        zoneId,
        total: 0,
        message: "Aucun type de ticket trouvé pour cette zone"
      });
    }

    // Construire la requête Firestore avec filtres
    let query = db.collection("transactions")
      .where("planId", "in", ticketTypeIds);

    // Filtre par statut
    const currentStatus = status || statusFilter;
    if (currentStatus) {
      const validStatuses = ["created", "pending", "completed", "failed", "expired", "cancelled"];
      if (validStatuses.includes(currentStatus)) {
        query = query.where("status", "==", currentStatus);
      }
    }

    // Filtre par date
    if (startDate) {
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      query = query.where("createdAt", ">=", start);
    }
    if (endDate) {
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
      query = query.where("createdAt", "<=", end);
    }

    // Tri et pagination
    query = query.orderBy("createdAt", "desc");
    
    // Pagination
    const pageNum = parseInt(page) || 0;
    const limitNum = parseInt(limit) || 50;
    if (pageNum > 0) {
      query = query.offset(pageNum * limitNum);
    }
    query = query.limit(limitNum);

    const snapshot = await query.get();

    // Traiter les transactions
    let transactions = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        status: data.status,
        amount: data.amount,
        currency: data.currency || "XAF",
        phone: data.phone,
        createdAt: data.createdAt?.toDate?.()?.toISOString?.(),
        completedAt: data.completedAt?.toDate?.()?.toISOString?.(),
        updatedAt: data.updatedAt?.toDate?.()?.toISOString?.(),
        planId: data.planId,
        planName: data.planName,
        ticketTypeName: data.ticketTypeName,
        freemopayReference: data.freemopayReference,
        // Credentials uniquement si transaction completed
        credentials: data.status === "completed" ? data.credentials : null,
        isManualSale: data.isManualSale || false,
        saleDescription: data.saleDescription,
        adminUserId: data.adminUserId,
        externalId: data.externalId,
        provider: data.provider || "freemopay",
        providerMessage: data.providerMessage,
        reservedTicketId: data.reservedTicketId,
      };
    });

    // Filtre de recherche côté serveur (si la recherche Firestore n'est pas possible)
    if (search) {
      const searchLower = search.toLowerCase();
      transactions = transactions.filter(tx => 
        tx.phone?.toLowerCase().includes(searchLower) ||
        tx.id?.toLowerCase().includes(searchLower) ||
        tx.freemopayReference?.toLowerCase().includes(searchLower) ||
        tx.planName?.toLowerCase().includes(searchLower)
      );
    }

    return res.json({
      success: true,
      transactions,
      zoneId,
      total: transactions.length,
      page: pageNum,
      limit: limitNum,
      hasMore: transactions.length === limitNum,
      filters: {
        status: currentStatus || null,
        search: search || null,
        startDate: startDate || null,
        endDate: endDate || null
      }
    });

  } catch (e) {
    logger.error("getZoneTransactions error", e);
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});

/* ================== API: DÉTAILS COMPLETS D'UNE TRANSACTION ================== */
exports.getTransactionDetails = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { transactionId } = req.query;
    if (!transactionId) return res.status(400).json({ error: "transactionId requis" });

    const doc = await db.collection("transactions").doc(String(transactionId)).get();
    if (!doc.exists) {
      return res.status(404).json({ error: "Transaction introuvable" });
    }

    const tx = doc.data();

    // Récupérer les informations supplémentaires en parallèle
    const promises = [];
    
    // Informations du plan/type de ticket
    if (tx.planId) {
      promises.push(
        db.collection("ticket_types").doc(tx.planId).get()
          .then(planDoc => planDoc.exists ? { planDetails: planDoc.data() } : { planDetails: null })
          .catch(() => ({ planDetails: null }))
      );
    } else {
      promises.push(Promise.resolve({ planDetails: null }));
    }

    // Informations de la zone
    if (tx.planId) {
      promises.push(
        db.collection("ticket_types").doc(tx.planId).get()
          .then(async planDoc => {
            if (planDoc.exists && planDoc.data().zoneId) {
              const zoneDoc = await db.collection("zones").doc(planDoc.data().zoneId).get();
              return { zoneDetails: zoneDoc.exists ? zoneDoc.data() : null };
            }
            return { zoneDetails: null };
          })
          .catch(() => ({ zoneDetails: null }))
      );
    } else {
      promises.push(Promise.resolve({ zoneDetails: null }));
    }

    // Informations du ticket réservé/utilisé
    if (tx.reservedTicketId) {
      promises.push(
        db.collection("tickets").doc(tx.reservedTicketId).get()
          .then(ticketDoc => ticketDoc.exists ? { ticketDetails: ticketDoc.data() } : { ticketDetails: null })
          .catch(() => ({ ticketDetails: null }))
      );
    } else {
      promises.push(Promise.resolve({ ticketDetails: null }));
    }

    const [planInfo, zoneInfo, ticketInfo] = await Promise.all(promises);

    // Construire la réponse détaillée
    const detailedTransaction = {
      id: doc.id,
      status: tx.status,
      amount: tx.amount,
      currency: tx.currency || "XAF",
      phone: tx.phone,
      createdAt: tx.createdAt?.toDate?.()?.toISOString?.(),
      completedAt: tx.completedAt?.toDate?.()?.toISOString?.(),
      updatedAt: tx.updatedAt?.toDate?.()?.toISOString?.(),
      planId: tx.planId,
      planName: tx.planName,
      ticketTypeName: tx.ticketTypeName,
      freemopayReference: tx.freemopayReference,
      // Credentials UNIQUEMENT si transaction completed
      credentials: tx.status === "completed" ? tx.credentials : null,
      isManualSale: tx.isManualSale || false,
      saleDescription: tx.saleDescription,
      adminUserId: tx.adminUserId,
      externalId: tx.externalId,
      provider: tx.provider || "freemopay",
      providerMessage: tx.providerMessage,
      reservedTicketId: tx.reservedTicketId,
      
      // Informations détaillées supplémentaires
      planDetails: planInfo.planDetails,
      zoneDetails: zoneInfo.zoneDetails,
      ticketDetails: ticketInfo.ticketDetails,
    };

    return res.json({
      success: true,
      transaction: detailedTransaction
    });

  } catch (e) {
    logger.error("getTransactionDetails error", e);
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});

/* ================== API: STATISTIQUES DES TRANSACTIONS D'UNE ZONE ================== */
exports.getZoneTransactionStats = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "GET") return res.status(405).json({ error: "Method Not Allowed" });

  try {
    const { zoneId } = req.query;
    if (!zoneId) return res.status(400).json({ error: "zoneId requis" });

    // Vérifier que la zone existe
    const zoneDoc = await db.collection("zones").doc(zoneId).get();
    if (!zoneDoc.exists) {
      return res.status(404).json({ error: "Zone non trouvée" });
    }

    // Récupérer les IDs des types de tickets de cette zone
    const ticketTypeIds = await getZoneTicketTypeIds(zoneId);
    if (ticketTypeIds.length === 0) {
      return res.json({
        success: true,
        stats: {
          totalCount: 0,
          totalAmount: 0,
          statusCounts: {},
          statusAmounts: {}
        }
      });
    }

    // Récupérer toutes les transactions - stratégie sans index complexe
    let allTransactions = [];
    
    // Si peu de types de tickets, faire des requêtes séparées
    if (ticketTypeIds.length <= 10) {
      const promises = ticketTypeIds.map(planId => 
        db.collection("transactions")
          .where("planId", "==", planId)
          .get()
      );
      
      const snapshots = await Promise.all(promises);
      allTransactions = snapshots.flatMap(snap => snap.docs.map(doc => doc.data()));
    } else {
      // Pour beaucoup de types, faire des requêtes par batch de 10 (limite Firestore)
      const batches = [];
      for (let i = 0; i < ticketTypeIds.length; i += 10) {
        const batch = ticketTypeIds.slice(i, i + 10);
        batches.push(
          db.collection("transactions")
            .where("planId", "in", batch)
            .get()
        );
      }
      
      const snapshots = await Promise.all(batches);
      allTransactions = snapshots.flatMap(snap => snap.docs.map(doc => doc.data()));
    }

    // Calculer les statistiques générales
    let totalCount = 0;
    let totalAmount = 0;
    const statusCounts = {};
    const statusAmounts = {};
    
    // Initialiser les compteurs pour tous les statuts
    const allStatuses = ["created", "pending", "completed", "failed", "expired", "cancelled"];
    allStatuses.forEach(status => {
      statusCounts[status] = 0;
      statusAmounts[status] = 0;
    });

    // Traiter toutes les transactions
    allTransactions.forEach(data => {
      totalCount++;
      const amount = data.amount || 0;
      const status = data.status || "created";
      
      // Total général
      if (status === "completed") {
        totalAmount += amount;
      }
      
      // Compter par statut
      if (statusCounts.hasOwnProperty(status)) {
        statusCounts[status]++;
        if (status === "completed") {
          statusAmounts[status] += amount;
        }
      }
    });

    const stats = {
      totalCount,
      totalAmount,
      statusCounts,
      statusAmounts
    };

    return res.json({
      success: true,
      stats,
      zoneId
    });

  } catch (e) {
    logger.error("getZoneTransactionStats error", e);
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});

/* ================== API: ANNULER UNE RÉSERVATION ================== */
exports.cancelTransactionReservation = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });

  const t0 = Date.now();
  const logStep = (msg) => logger.info(`⏱ [cancelTransactionReservation] ${msg} — ${Date.now() - t0} ms écoulées`);

  try {
    logStep("Début annulation de réservation");
    
    const { transactionId } = req.body || {};
    if (!transactionId) return res.status(400).json({ error: "transactionId requis" });

    // Récupérer la transaction
    const txnRef = db.collection("transactions").doc(String(transactionId));
    const txnDoc = await txnRef.get();
    
    if (!txnDoc.exists) {
      return res.status(404).json({ error: "Transaction introuvable" });
    }

    const txData = txnDoc.data();
    logStep("Transaction récupérée");

    // Vérifier que la transaction peut être annulée
    const cancellableStatuses = ["created", "pending"];
    if (!cancellableStatuses.includes(txData.status)) {
      return res.status(400).json({ 
        error: `Impossible d'annuler une transaction avec le statut: ${txData.status}`,
        currentStatus: txData.status
      });
    }

    // Vérifier qu'il y a un ticket réservé
    if (!txData.reservedTicketId) {
      return res.status(400).json({ 
        error: "Aucun ticket réservé trouvé pour cette transaction" 
      });
    }

    logStep("Validations passées");

    // Utiliser une transaction Firestore pour l'atomicité
    const result = await db.runTransaction(async (transaction) => {
      // Re-vérifier la transaction dans la transaction
      const currentTxn = await transaction.get(txnRef);
      if (!currentTxn.exists || !cancellableStatuses.includes(currentTxn.data().status)) {
        throw new Error("Transaction déjà modifiée ou ne peut plus être annulée");
      }

      const currentTxnData = currentTxn.data();

      // Récupérer le ticket réservé
      const ticketRef = db.collection("tickets").doc(currentTxnData.reservedTicketId);
      const ticketDoc = await transaction.get(ticketRef);
      
      if (!ticketDoc.exists) {
        throw new Error("Ticket réservé introuvable");
      }

      const ticketData = ticketDoc.data();
      
      // Vérifier que le ticket est bien réservé pour cette transaction
      if (ticketData.status !== "reserved") {
        throw new Error(`Ticket dans un état incorrect: ${ticketData.status}`);
      }

      // 1. Libérer le ticket
      transaction.update(ticketRef, {
        status: "available",
        reservedAt: admin.firestore.FieldValue.delete(),
        transactionId: admin.firestore.FieldValue.delete(),
        // Nettoyer toute trace de la transaction
        cancelledFromTransactionId: currentTxnData.externalId || transactionId,
        cancelledAt: admin.firestore.Timestamp.now(),
      });

      // 2. Marquer la transaction comme annulée
      transaction.update(txnRef, {
        status: "cancelled",
        updatedAt: admin.firestore.Timestamp.now(),
        cancelledAt: admin.firestore.Timestamp.now(),
        providerMessage: "Réservation annulée manuellement",
        // Supprimer la référence au ticket
        reservedTicketId: admin.firestore.FieldValue.delete(),
        // Conserver l'historique
        originalReservedTicketId: currentTxnData.reservedTicketId,
        // Supprimer les credentials potentiels
        credentials: admin.firestore.FieldValue.delete(),
      });

      return {
        ticketId: currentTxnData.reservedTicketId,
        transactionId: transactionId,
      };
    });

    logStep("Transaction Firestore terminée");

    logger.info("✅ Réservation annulée avec succès", {
      transactionId: transactionId,
      ticketId: result.ticketId,
      duration: Date.now() - t0
    });

    return res.json({
      success: true,
      message: "Réservation annulée avec succès",
      transactionId: transactionId,
      ticketId: result.ticketId,
      timestamp: new Date().toISOString(),
    });

  } catch (e) {
    logger.error("cancelTransactionReservation error", e);
    
    // Retourner des erreurs spécifiques
    if (e.message.includes("déjà modifiée")) {
      return res.status(409).json({ error: "Transaction déjà modifiée par un autre processus" });
    }
    
    if (e.message.includes("état incorrect")) {
      return res.status(409).json({ error: "Le ticket n'est plus dans l'état attendu" });
    }
    
    return res.status(500).json({ error: "Erreur interne du serveur" });
  }
});