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
  appKey: "7be38c1d-c0d9-4067-aba9-f0380dc68088",
  secretKey: "r1gDV0F2eO1EyfMMrs19",
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
        credentials: {
          username: reservedTicket.username,
          password: reservedTicket.password
        }
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

    return res.json({
      success: true,
      transaction: {
        id: doc.id,
        status: tx.status,
        amount: tx.amount,
        freemopayReference: tx.freemopayReference || null,
        credentials: tx.credentials || null,
        ticketTypeName: tx.ticketTypeName || null,
        updatedAt: tx.updatedAt?.toDate?.()?.toISOString?.() || null,
      },
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
  await txnRef.update({
    status: "completed",
    updatedAt: now(),
    providerStatus: status,
    webhookReceived: true,
    providerMessage: message || null,
    freemopayReference: reference || tx.freemopayReference || null,
    ticketTypeName: tx.ticketTypeName || null
  });
  return res.status(200).send("");
}

if (String(status).toUpperCase() === "FAILED" || String(status).toUpperCase() === "EXPIRED") {
  // ✅ Libérer le ticket réservé
  if (tx.reservedTicketId) {
    await db.collection("tickets").doc(tx.reservedTicketId).update({
      status: "available",
      reservedAt: admin.firestore.FieldValue.delete()
    });
  }

  await txnRef.update({
    status: "failed",
    updatedAt: now(),
    providerStatus: status,
    webhookReceived: true,
    providerMessage: message || null
  });
  return res.status(200).send("");
}
  } catch (e) {
    logger.error("handleFreemopayWebhook error", e);
    return res.status(200).send(""); // éviter retries agressifs
  }
});



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

    // Chercher tickets réservés expirés
    const snap = await db.collection("tickets")
      .where("status", "==", "reserved")
      .where("reservedAt", "<", limitTs)
      .limit(50)
      .get();

    if (snap.empty) return logger.info("✅ Aucun ticket réservé expiré");

    const batch = db.batch();
    for (const doc of snap.docs) {
      const data = doc.data();

      // Libération du ticket
      batch.update(doc.ref, {
        status: "available",
        reservedAt: admin.firestore.FieldValue.delete(),
      });

      // Marquer transaction associée comme expirée si trouvée
      const txnSnap = await db.collection("transactions")
        .where("reservedTicketId", "==", doc.id)
        .where("status", "in", ["created", "pending"])
        .limit(1)
        .get();

      if (!txnSnap.empty) {
        batch.update(txnSnap.docs[0].ref, {
          status: "expired",
          updatedAt: nowTs,
          providerMessage: "Paiement non complété dans le délai imparti",
        });
      }
    }

    await batch.commit();
    logger.info(`♻️ ${snap.size} tickets libérés`);
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
