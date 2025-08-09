/**
 * Cloud Functions pour l'intégration Freemopay
 * Version corrigée avec le bon format de payload
 */
const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialisation de Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Options globales pour les fonctions (contrôle des coûts)
setGlobalOptions({ maxInstances: 10 });

// ===== CONFIGURATION FREEMOPAY (CORRIGÉE) =====
const FREEMOPAY_CONFIG = {
  baseUrl: "https://api-v2.freemopay.com",
  // ✅ CLÉS TESTÉES ET FONCTIONNELLES
  appKey: "7be38c1d-c0d9-4067-aba9-f0380dc68088",
  secretKey: "r1gDV0F2eO1EyfMMrs19",
  timeout: 5000, // 30 secondes
};

// URL de votre projet Firebase pour le webhook
const PROJECT_ID = "dnet-29b02"; // Remplacez par votre ID de projet
const WEBHOOK_URL = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/handleFreemopayWebhook`;

// ===== UTILITAIRES =====

/**
 * Nettoie et formate le numéro de téléphone camerounais
 */
function formatCameroonPhone(phoneNumber) {
  if (!phoneNumber) throw new Error("Numéro de téléphone requis");
  
  let formatted = phoneNumber;
  
  // Supprimer tous les caractères non numériques
  formatted = formatted.replace(/\D/g, '');
  
  // Si commence par +237, retirer le +
  if (phoneNumber.startsWith('+237')) {
    formatted = phoneNumber.substring(1); // Garde "237XXXXXXXX"
  }
  // Si commence par 00237, remplacer par 237
  else if (formatted.startsWith('00237')) {
    formatted = formatted.substring(2); // "237XXXXXXXX"
  }
  // Si ne commence pas par 237, l'ajouter
  else if (!formatted.startsWith('237')) {
    // Supprimer le 0 initial s'il existe
    if (formatted.startsWith('0')) {
      formatted = formatted.substring(1);
    }
    formatted = `237${formatted}`;
  }
  
  // Vérifier le format final
  if (formatted.length !== 12 || !formatted.startsWith('237')) {
    throw new Error(`Format de numéro invalide: ${phoneNumber} -> ${formatted}`);
  }
  
  logger.debug(`📱 Numéro formaté: ${phoneNumber} -> ${formatted}`);
  return formatted;
}

// ===== NOUVELLE FONCTION: API PUBLIQUE DES FORFAITS =====

exports.getPublicTicketTypes = onRequest(async (req, res) => {
  // Configuration CORS pour permettre l'accès depuis le hostpot
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== "GET") {
    logger.warn("⚠️ Méthode non autorisée pour getPublicTicketTypes", { method: req.method });
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  try {
    const { zoneId, publicKey } = req.query;

    if (!zoneId) {
      logger.error("❌ Zone ID manquant dans la requête");
      return res.status(400).json({ error: "Zone ID requis" });
    }

    logger.info("🔍 Récupération des forfaits publics", { 
      zoneId: zoneId,
      hasPublicKey: !!publicKey 
    });

    // === ÉTAPE 1: VÉRIFIER QUE LA ZONE EXISTE ET EST PUBLIQUE ===
    const zoneDoc = await db.collection('zones').doc(zoneId).get();

    if (!zoneDoc.exists) {
      logger.error(`❌ Zone non trouvée: ${zoneId}`);
      return res.status(404).json({ error: "Zone non trouvée" });
    }

    const zoneData = zoneDoc.data();

    // Vérifier l'accès public
    if (!zoneData.isActive) {
      logger.warn(`⚠️ Tentative d'accès à une zone privée: ${zoneId}`);
      return res.status(403).json({ error: "Zone non accessible publiquement" });
    }

    // Vérification optionnelle de la clé publique pour plus de sécurité
    if (zoneData.publicAccessKey && publicKey !== zoneData.publicAccessKey) {
      logger.warn(`⚠️ Clé publique invalide pour la zone: ${zoneId}`);
      return res.status(403).json({ error: "Clé d'accès invalide" });
    }

    // === ÉTAPE 2: RÉCUPÉRER LES FORFAITS ACTIFS ===
    const ticketTypesSnapshot = await db.collection('ticket_types')
      .where('zoneId', '==', zoneId)
      .where('isActive', '==', true)
      .orderBy('price', 'asc')
      .get();

    if (ticketTypesSnapshot.empty) {
      logger.info(`📭 Aucun forfait actif trouvé pour la zone: ${zoneId}`);
      return res.json({ 
        success: true,
        zone: {
          id: zoneData.id || zoneId,
          name: zoneData.name,
          description: zoneData.description
        },
        plans: [] 
      });
    }

    // === ÉTAPE 3: FORMATER LES DONNÉES POUR LE HOSTPOT ===
    const plans = await Promise.all(
      ticketTypesSnapshot.docs.map(async (doc) => {
        const data = doc.data();
        
        // Vérifier la disponibilité des tickets
        const availableTicketsSnapshot = await db.collection('tickets')
          .where('ticketTypeId', '==', doc.id)
          .where('status', '==', 'available')
          .limit(1)
          .get();

        const isAvailable = !availableTicketsSnapshot.empty;

        return {
          id: doc.id,
          name: data.name,
          description: data.description,
          price: data.price,
          formattedPrice: `${data.price.toLocaleString()} F`,
          validityHours: data.validityHours,
          validityText: formatValidityDuration(data.validityHours),
          downloadLimit: data.downloadLimit,
          uploadLimit: data.uploadLimit,
          sessionTimeLimit: data.sessionTimeLimit,
          isAvailable: isAvailable,
          ticketsAvailable: data.ticketsAvailable || 0,
          rateLimit: data.rateLimit || null,
          isActive: data.isActive,
          // Pour l'affichage des promotions
          originalPrice: data.originalPrice || null,
          hasPromotion: !!(data.originalPrice && data.originalPrice > data.price),
          createdAt: data.createdAt?.toDate()?.toISOString(),
        };
      })
    );

    // Filtrer les forfaits disponibles
    const availablePlans = plans.filter(plan => plan.isAvailable);

    logger.info(`✅ ${availablePlans.length} forfaits récupérés pour la zone ${zoneId}`);

    res.json({
      success: true,
      zone: {
        id: zoneId,
        name: zoneData.name,
        description: zoneData.description,
        location: zoneData.location,
        routerType: zoneData.routerType,
      },
      plans: availablePlans,
      totalPlans: availablePlans.length,
      lastUpdated: new Date().toISOString(),
    });

  } catch (error) {
    logger.error("🔥 Erreur lors de la récupération des forfaits publics", {
      error: error.toString(),
      stack: error.stack,
      zoneId: req.query.zoneId,
    });

    res.status(500).json({ 
      success: false,
      error: "Erreur interne du serveur" 
    });
  }
});


// ===== FONCTION UTILITAIRE POUR FORMATER LA DURÉE =====
function formatValidityDuration(hours) {
  if (hours < 24) {
    return `${hours}h`;
  } else if (hours < 168) { // moins d'une semaine
    const days = Math.floor(hours / 24);
    return `${days} jour${days > 1 ? 's' : ''}`;
  } else if (hours < 720) { // moins d'un mois
    const weeks = Math.floor(hours / 168);
    return `${weeks} semaine${weeks > 1 ? 's' : ''}`;
  } else {
    const months = Math.floor(hours / 720);
    return `${months} mois`;
  }
}


/**
 * Valide la configuration Freemopay
 */
function validateFreemopayConfig() {
  if (!FREEMOPAY_CONFIG.appKey) {
    throw new Error("Configuration Freemopay: App Key manquante");
  }
  if (!FREEMOPAY_CONFIG.secretKey) {
    throw new Error("Configuration Freemopay: Secret Key manquante");
  }
}
// ====== UTILS FREEMOPAY ======
function getBasicAuthHeader() {
  const token = Buffer.from(`${FREEMOPAY_CONFIG.appKey}:${FREEMOPAY_CONFIG.secretKey}`).toString('base64');
  return `Basic ${token}`;
}

async function callFreemopay(endpoint, payload, timeoutMs = FREEMOPAY_CONFIG.timeout) {
  const url = `${FREEMOPAY_CONFIG.baseUrl}${endpoint}`;
  const headers = {
    'Authorization': getBasicAuthHeader(),
    'Content-Type': 'application/json',
  };
  logger.info('➡️ Appel Freemopay', { url, payload: { ...payload, secretKey: undefined } });
  const resp = await axios.post(url, payload, { headers, timeout: timeoutMs });
  logger.info('⬅️ Réponse Freemopay', { status: resp.status, data: resp.data });
  return resp.data;
}

// Petite aide pour l’horodatage
const now = () => admin.firestore.Timestamp.now();

function addMinutes(ts, minutes) {
  return admin.firestore.Timestamp.fromMillis(ts.toMillis() + minutes * 60 * 1000);
}

// ====== RÉSERVATION TICKET ======
async function reserveOneTicketOrThrow(ticketTypeId, transactionId) {
  // On prend un ticket "available" au hasard (ou 1er)
  const snap = await db.collection('tickets')
    .where('ticketTypeId', '==', ticketTypeId)
    .where('status', '==', 'available')
    .limit(1)
    .get();

  if (snap.empty) {
    throw new HttpsError('failed-precondition', 'Aucun ticket disponible pour ce forfait.');
  }
  const doc = snap.docs[0];
  const expiresAt = addMinutes(now(), 10); // réservation 10 min

  await doc.ref.update({
    status: 'reserved',
    reservedBy: transactionId,
    reservedAt: now(),
    reservationExpiresAt: expiresAt,
  });

  return { id: doc.id, ...doc.data() };
}

async function releaseReservedTicket(transactionId) {
  const snap = await db.collection('tickets')
    .where('reservedBy', '==', transactionId)
    .where('status', '==', 'reserved')
    .limit(1)
    .get();
  if (snap.empty) return false;

  const doc = snap.docs[0];
  await doc.ref.update({
    status: 'available',
    reservedBy: admin.firestore.FieldValue.delete(),
    reservedAt: admin.firestore.FieldValue.delete(),
    reservationExpiresAt: admin.firestore.FieldValue.delete(),
  });
  return true;
}

async function deliverReservedTicket(transactionId) {
  const snap = await db.collection('tickets')
    .where('reservedBy', '==', transactionId)
    .where('status', '==', 'reserved')
    .limit(1)
    .get();

  if (snap.empty) {
    // En dernier recours, essaye d’en prendre un dispo
    logger.warn('⚠️ Aucun ticket réservé trouvé, tentative de délivrance depuis "available"', { transactionId });
    return null;
  }

  const doc = snap.docs[0];
  await doc.ref.update({
    status: 'sold',
    soldAt: now(),
  });
  return { id: doc.id, ...doc.data() };
}

// ====== INIT PAYMENT (site -> CF -> Freemopay) ======
exports.initiatePayment = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(204).send('');

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    validateFreemopayConfig();

    const { planId, phoneNumber, externalId } = req.body || {};
    if (!planId || !phoneNumber) {
      return res.status(400).json({ error: 'planId et phoneNumber sont requis' });
    }

    const phone = formatCameroonPhone(phoneNumber);

    // 1) Vérifier le plan
    const planRef = db.collection('ticket_types').doc(planId);
    const planSnap = await planRef.get();
    if (!planSnap.exists) throw new HttpsError('not-found', 'Forfait introuvable');
    const plan = planSnap.data();
    if (!plan.isActive) throw new HttpsError('failed-precondition', 'Forfait inactif');
    if (typeof plan.price !== 'number') throw new HttpsError('failed-precondition', 'Prix invalide');

    // 2) Créer la transaction Firestore (idempotence via externalId si fourni)
    let txnRef;
    if (externalId) {
      const existing = await db.collection('transactions').where('externalId', '==', externalId).limit(1).get();
      if (!existing.empty) {
        const doc = existing.docs[0];
        const data = doc.data();
        // si déjà créée, renvoyer état actuel
        return res.json({
          success: true,
          transactionId: doc.id,
          status: data.status,
          freemopayReference: data.freemopayReference || null,
          amount: data.amount,
        });
      }
    }

    txnRef = await db.collection('transactions').add({
      createdAt: now(),
      updatedAt: now(),
      status: 'created',               // created | pending | completed | failed | expired
      provider: 'freemopay',
      amount: plan.price,
      currency: 'XAF',
      planId,
      phone,
      externalId: externalId || null,
      freemopayReference: null,
      webhookReceived: false,
    });
    const transactionId = txnRef.id;

    // 3) Réserver un ticket (si tu préfères réserver après SUCCESS, déplace ça dans le webhook)
    await reserveOneTicketOrThrow(planId, transactionId);

    // 4) Appel Freemopay
    // ⚠️ Selon ta config, la clé téléphone peut être `payer` (souvent) ou `receiver`.
    const payload = {
      amount: plan.price,
      externalId: externalId || transactionId,
      callback: WEBHOOK_URL,
      payer: phone, // <-- change en `receiver: phone` si ton endpoint l’exige
    };

    const data = await callFreemopay('/api/v2/payment', payload);
    // Réponse attendue: { reference: "...", status: "CREATED" | "PENDING", ... }

    await txnRef.update({
      status: 'pending',
      updatedAt: now(),
      freemopayReference: data.reference || null,
      providerInitResponse: data,
    });

    return res.json({
      success: true,
      transactionId,
      freemopayReference: data.reference || null,
      amount: plan.price,
    });
  } catch (err) {
    logger.error('❌ initiatePayment error', { error: err.toString(), stack: err.stack });
    return res.status(500).json({ error: err.message || 'Erreur interne' });
  }
});

// ====== CHECK TRANSACTION STATUS (site -> CF) ======
exports.checkTransactionStatus = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(204).send('');

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { transactionId } = req.query;
    if (!transactionId) return res.status(400).json({ error: 'transactionId requis' });

    const doc = await db.collection('transactions').doc(String(transactionId)).get();
    if (!doc.exists) return res.status(404).json({ error: 'Transaction introuvable' });

    const tx = doc.data();
    // Si SUCCESS et ticket délivré, renvoyer les credentials
    return res.json({
      success: true,
      transaction: {
        id: doc.id,
        status: tx.status,
        amount: tx.amount,
        freemopayReference: tx.freemopayReference || null,
        credentials: tx.credentials || null, // {username, password}
        ticketTypeName: tx.ticketTypeName || null,
        updatedAt: tx.updatedAt?.toDate?.()?.toISOString?.() || null,
      },
    });
  } catch (err) {
    logger.error('❌ checkTransactionStatus error', { error: err.toString() });
    return res.status(500).json({ error: 'Erreur interne' });
  }
});

// ====== WEBHOOK (Freemopay -> CF) ======
exports.handleFreemopayWebhook = onRequest(async (req, res) => {
  try {
    // Freemopay envoie un JSON comme:
    // { status: "SUCCESS" | "FAILED", reference: "...", amount: 100, transactionType: "DEPOSIT", externalId: "xxx", message: "..." }
    const body = req.body || {};
    logger.info('📩 Webhook Freemopay reçu', body);

    const { status, reference, amount, externalId, message } = body;
    if (!reference && !externalId) {
      logger.warn('Webhook sans reference/externalId');
      return res.status(400).send('missing reference');
    }

    // Retrouver la transaction par reference Freemopay ou externalId
    let txnSnap;
    if (reference) {
      txnSnap = await db.collection('transactions').where('freemopayReference', '==', reference).limit(1).get();
    }
    if ((!txnSnap || txnSnap.empty) && externalId) {
      txnSnap = await db.collection('transactions').where('externalId', '==', externalId).limit(1).get();
    }
    if (!txnSnap || txnSnap.empty) {
      logger.error('❌ Transaction introuvable pour webhook', { reference, externalId });
      return res.status(404).send('transaction not found');
    }

    const txnDoc = txnSnap.docs[0];
    const txnRef = txnDoc.ref;
    const txn = txnDoc.data();

    // Idempotence: si déjà finalisée, on confirme 200
    if (['completed', 'failed', 'expired'].includes(txn.status)) {
      logger.info('ℹ️ Webhook idempotent: transaction déjà finalisée', { id: txnDoc.id, status: txn.status });
      await txnRef.update({ webhookReceived: true, updatedAt: now() });
      return res.status(200).send('');
    }

    if (String(status).toUpperCase() === 'SUCCESS') {
      // Délivrer le ticket réservé
      const delivered = await deliverReservedTicket(txnDoc.id);

      let credentials = null;
      let ticketTypeName = null;

      if (delivered) {
        credentials = {
          username: delivered.username,
          password: delivered.password,
        };
        // récupérer le nom du forfait
        if (txn.planId) {
          const ttype = await db.collection('ticket_types').doc(txn.planId).get();
          ticketTypeName = ttype.exists ? (ttype.data().name || null) : null;
        }
      } else {
        // Aucun ticket réservé trouvé → tenter un ticket dispo
        const fallback = await db.collection('tickets')
          .where('ticketTypeId', '==', txn.planId)
          .where('status', '==', 'available')
          .limit(1)
          .get();
        if (!fallback.empty) {
          const doc = fallback.docs[0];
          await doc.ref.update({ status: 'sold', soldAt: now() });
          const data = doc.data();
          credentials = { username: data.username, password: data.password };
          const ttype = await db.collection('ticket_types').doc(txn.planId).get();
          ticketTypeName = ttype.exists ? (ttype.data().name || null) : null;
        } else {
          logger.error('❌ Paiement réussi mais aucun ticket disponible à délivrer', { id: txnDoc.id });
        }
      }

      await txnRef.update({
        status: 'completed',
        updatedAt: now(),
        providerStatus: status,
        webhookReceived: true,
        providerMessage: message || null,
        credentials: credentials || null,
        ticketTypeName: ticketTypeName || null,
      });

      return res.status(200).send('');
    } else if (String(status).toUpperCase() === 'FAILED') {
      // Libérer ticket réservé si existant
      await releaseReservedTicket(txnDoc.id);

      await txnRef.update({
        status: 'failed',
        updatedAt: now(),
        providerStatus: status,
        webhookReceived: true,
        providerMessage: message || null,
      });

      return res.status(200).send('');
    } else {
      logger.warn('Webhook status non géré', { status });
      await txnRef.update({
        updatedAt: now(),
        providerStatus: status || 'UNKNOWN',
        webhookReceived: true,
        providerMessage: message || null,
      });
      return res.status(200).send('');
    }
  } catch (err) {
    logger.error('🔥 Erreur webhook Freemopay', { error: err.toString(), stack: err.stack });
    // Toujours 200 pour éviter les retries infinis côté provider si nécessaire,
    // ou renvoyer 500 si vous voulez des retries (choix produit).
    return res.status(200).send('');
  }
});

// ====== (OPTIONNEL) DIRECT WITHDRAW / CASHOUT ======
exports.directWithdraw = onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' });

  try {
    validateFreemopayConfig();

    const { receiver, amount, externalId, callback } = req.body || {};
    if (!receiver || !amount) return res.status(400).json({ error: 'receiver et amount requis' });

    const phone = formatCameroonPhone(receiver);

    const payload = {
      receiver: phone,                  // pour withdraw, la doc parle bien de "receiver"
      amount: String(amount),
      externalId: externalId || `wd_${Date.now()}`,
      callback: callback || WEBHOOK_URL,
    };

    const data = await callFreemopay('/api/v2/payment/direct-withdraw', payload);

    return res.json({ success: true, ...data });
  } catch (err) {
    logger.error('❌ directWithdraw error', { error: err.toString() });
    return res.status(500).json({ error: err.message || 'Erreur interne' });
  }
});
