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
  timeout: 30000, // 30 secondes
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

// ===== FONCTION 1: INITIATION DU PAIEMENT =====

exports.initiatePublicPayment = onCall(async (request) => {
  logger.info("🚀 Démarrage de initiatePublicPayment", { 
    data: { 
      ticketTypeId: request.data?.ticketTypeId, 
      phoneNumber: request.data?.phoneNumber ? "***masked***" : null 
    } 
  });

  // Validation des entrées
  const { ticketTypeId, phoneNumber } = request.data || {};
  
  if (!ticketTypeId || !phoneNumber) {
    logger.error("❌ Données manquantes", { 
      hasTicketTypeId: !!ticketTypeId, 
      hasPhoneNumber: !!phoneNumber 
    });
    throw new HttpsError(
      "invalid-argument", 
      "Le type de ticket et le numéro de téléphone sont requis."
    );
  }

  // Validation de la configuration
  try {
    validateFreemopayConfig();
  } catch (configError) {
    logger.error("❌ Configuration Freemopay invalide", { error: configError.message });
    throw new HttpsError("failed-precondition", "Service de paiement non configuré");
  }

  let formattedPhone;
  try {
    formattedPhone = formatCameroonPhone(phoneNumber);
    logger.debug("✅ Numéro formaté avec succès");
  } catch (phoneError) {
    logger.error("❌ Numéro de téléphone invalide", { error: phoneError.message });
    throw new HttpsError("invalid-argument", phoneError.message);
  }

  let transactionRef;

  try {
    // === ÉTAPE 1: CRÉER LA TRANSACTION ET VÉRIFIER LA DISPONIBILITÉ ===
    transactionRef = await db.runTransaction(async (t) => {
      logger.debug(`🔍 Recherche d'un ticket disponible pour le type: ${ticketTypeId}`);
      
      // Vérifier le type de ticket existe
      const ticketTypeRef = db.collection("ticket_types").doc(ticketTypeId);
      const ticketTypeDoc = await t.get(ticketTypeRef);
      
      if (!ticketTypeDoc.exists) {
        logger.error(`❌ Type de ticket non trouvé: ${ticketTypeId}`);
        throw new HttpsError("not-found", "Le type de ticket n'existe pas.");
      }
      
      const ticketTypeData = ticketTypeDoc.data();
      
      // ✅ VÉRIFIER QU'IL Y A DES TICKETS RÉELLEMENT DISPONIBLES
      const availableTicketsQuery = await t.get(
        db.collection("tickets")
          .where("ticketTypeId", "==", ticketTypeId)
          .where("status", "==", "available")
          .limit(1)
      );

      if (availableTicketsQuery.empty) {
        logger.warn(`⚠️ Aucun ticket disponible pour le type: ${ticketTypeId}`);
        
        // Mettre à jour le compteur si incohérent
        t.update(ticketTypeRef, {
          ticketsAvailable: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        throw new HttpsError("out-of-range", "Désolé, ce forfait est momentanément épuisé.");
      }

      logger.info(`✅ ${availableTicketsQuery.docs.length} ticket(s) disponible(s) trouvé(s)`);

      // Créer la transaction
      const newTransactionRef = db.collection("transactions").doc();
      const transactionData = {
        ticketTypeId: ticketTypeId,
        ticketTypeName: ticketTypeData.name,
        phoneNumber: formattedPhone,
        amount: ticketTypeData.price,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        zoneId: ticketTypeData.zoneId,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 15 * 60 * 1000) // Expire dans 15 minutes
        ),
      };
      
      t.set(newTransactionRef, transactionData);
      logger.info(`📄 Transaction créée avec statut PENDING: ${newTransactionRef.id}`);
      
      return { ref: newTransactionRef, data: transactionData, ticketTypeData };
    });

    // === ÉTAPE 2: APPELER L'API FREEMOPAY (VERSION CORRIGÉE) ===
    const freemopayUrl = `${FREEMOPAY_CONFIG.baseUrl}/api/v2/payment`;

    // ✅ PAYLOAD CORRIGÉ selon le format qui fonctionne
    const payload = {
      payer: formattedPhone,                    // ✅ "payer" au lieu de "receiver"
      amount: transactionRef.data.amount.toString(), // ✅ String au lieu de number
      externalId: transactionRef.ref.id,
      description: `Achat ticket WiFi - ${transactionRef.ticketTypeData.name}`, // ✅ Description ajoutée
      callback: WEBHOOK_URL,
    };

    logger.info("📲 Appel de l'API Freemopay...", { 
      url: freemopayUrl, 
      payload: { 
        ...payload, 
        payer: "***masked***" 
      } 
    });

    let freemopayResponse;
    try {
      freemopayResponse = await axios.post(freemopayUrl, payload, {
        headers: {
          "Content-Type": "application/json",
        },
        // ✅ UTILISER auth PROPERTY COMME DANS LE CODE QUI MARCHE
        auth: {
          username: FREEMOPAY_CONFIG.appKey,
          password: FREEMOPAY_CONFIG.secretKey
        },
        timeout: FREEMOPAY_CONFIG.timeout,
      });
      
      logger.info("✅ Réponse de Freemopay reçue", { 
        status: freemopayResponse.status, 
        data: freemopayResponse.data 
      });

      // ✅ VÉRIFIER LA RÉPONSE SELON LE MODÈLE QUI FONCTIONNE
      if (freemopayResponse.data && freemopayResponse.data.status === 'SUCCESS') {
        // Succès immédiat (rare)
        logger.info("🎉 Paiement accepté immédiatement");
      } else if (freemopayResponse.data && freemopayResponse.data.reference) {
        // Paiement en attente (cas normal)
        logger.info("⏳ Paiement en attente de validation");
      } else {
        // Réponse inattendue
        logger.warn("⚠️ Réponse inattendue de Freemopay", freemopayResponse.data);
      }
      
    } catch (axiosError) {
      logger.error("❌ Erreur lors de l'appel Freemopay", {
        error: axiosError.message,
        status: axiosError.response?.status,
        statusText: axiosError.response?.statusText,
        data: axiosError.response?.data,
        headers: axiosError.response?.headers,
        code: axiosError.code,
      });

      // Marquer la transaction comme échouée
      await transactionRef.ref.update({
        status: "failed",
        failureReason: `Erreur API Freemopay: ${axiosError.response?.status} - ${axiosError.response?.data?.message || axiosError.message}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        errorDetails: {
          httpStatus: axiosError.response?.status,
          freemopayError: axiosError.response?.data,
          timestamp: new Date().toISOString(),
        }
      });

      // Erreurs spécifiques
      if (axiosError.code === 'ECONNABORTED') {
        throw new HttpsError("deadline-exceeded", "Le service de paiement ne répond pas. Veuillez réessayer.");
      } else if (axiosError.response) {
        const status = axiosError.response.status;
        const errorData = axiosError.response.data;
        
        if (status === 401) {
          throw new HttpsError("failed-precondition", "Clés API Freemopay invalides");
        } else if (status === 400) {
          throw new HttpsError("invalid-argument", `Données invalides: ${errorData?.message || 'Format incorrect'}`);
        } else if (status === 500) {
          throw new HttpsError("unavailable", `Erreur serveur Freemopay: ${errorData?.message || 'Service temporairement indisponible'}`);
        } else if (status >= 500) {
          throw new HttpsError("unavailable", "Service de paiement temporairement indisponible");
        }
      }
      
      throw new HttpsError("internal", "Erreur lors de l'initialisation du paiement");
    }

    // === ÉTAPE 3: METTRE À JOUR LA TRANSACTION AVEC LA RÉFÉRENCE FREEMOPAY ===
    await transactionRef.ref.update({
      freemopayReference: freemopayResponse.data.reference,
      freemopayStatus: freemopayResponse.data.status,
      freemopayMessage: freemopayResponse.data.message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("🎉 Paiement initié avec succès", { 
      transactionId: transactionRef.ref.id,
      freemopayReference: freemopayResponse.data.reference,
    });

    // Retourner l'ID de la transaction au client
    return { 
      success: true,
      transactionId: transactionRef.ref.id,
      freemopayReference: freemopayResponse.data.reference,
      amount: transactionRef.data.amount,
      message: "Paiement initié. Veuillez confirmer sur votre téléphone.",
    };

  } catch (error) {
    // Si la transaction a été créée mais a échoué après, la marquer comme échouée
    if (transactionRef?.ref) {
      try {
        await transactionRef.ref.update({
          status: "failed",
          failureReason: error.message || "Erreur inconnue",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        logger.error("❌ Erreur lors de la mise à jour de la transaction échouée", { 
          error: updateError.message 
        });
      }
    }

    if (error instanceof HttpsError) {
      throw error;
    }
    
    logger.error("❌ Erreur inattendue dans initiatePublicPayment", { 
      error: error.toString(),
      stack: error.stack,
    });
    throw new HttpsError("internal", "Une erreur interne est survenue. Veuillez réessayer.");
  }
});

// ===== FONCTION 2: WEBHOOK FREEMOPAY =====

exports.handleFreemopayWebhook = onRequest(async (req, res) => {
  // Configuration CORS pour permettre les requêtes de Freemopay
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== "POST") {
    logger.warn("⚠️ Webhook reçu avec une méthode non-POST", { method: req.method });
    return res.status(405).send("Method Not Allowed");
  }

  const webhookData = req.body;
  logger.info("🔔 Webhook Freemopay reçu !", { 
    body: {
      ...webhookData,
      // Masquer les données sensibles dans les logs
      externalId: webhookData.externalId || "missing",
      status: webhookData.status || "missing",
      amount: webhookData.amount || "missing",
    }
  });

  const { status, reference, externalId, message, amount } = webhookData;

  // Validation des données du webhook
  if (!externalId) {
    logger.error("❌ Webhook invalide: externalId manquant", { body: webhookData });
    return res.status(400).send("Invalid request: missing externalId");
  }

  if (!status) {
    logger.error("❌ Webhook invalide: status manquant", { body: webhookData });
    return res.status(400).send("Invalid request: missing status");
  }

  const transactionRef = db.collection("transactions").doc(externalId);

  try {
    // Vérifier que la transaction existe
    const transactionDoc = await transactionRef.get();
    if (!transactionDoc.exists) {
      logger.error(`❌ Transaction non trouvée: ${externalId}`);
      return res.status(404).send("Transaction not found");
    }

    const transactionData = transactionDoc.data();
    logger.debug(`📋 Transaction trouvée: ${externalId}`, { 
      currentStatus: transactionData.status,
      amount: transactionData.amount,
    });

    if (status === "SUCCESS") {
      logger.info(`✅ Traitement du succès pour la transaction ${externalId}`);
      
      await db.runTransaction(async (t) => {
        // Re-vérifier l'état de la transaction dans la transaction
        const freshTransactionDoc = await t.get(transactionRef);
        const freshData = freshTransactionDoc.data();
        
        if (freshData.status !== 'pending') {
          logger.warn(`Transaction ${externalId} n'est plus en attente. Statut actuel: ${freshData.status}`);
          return;
        }

        // Vérifier la cohérence du montant
        if (amount && amount !== freshData.amount) {
          logger.error(`❌ Montant incohérent pour ${externalId}`, {
            expected: freshData.amount,
            received: amount,
          });
          t.update(transactionRef, {
            status: "failed",
            failureReason: "Montant incohérent détecté",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            webhookData: webhookData,
          });
          return;
        }

        // Trouver et attribuer un ticket disponible
        const ticketTypeId = freshData.ticketTypeId;
        const ticketsRef = db.collection("tickets");
        const availableTicketQuery = await t.get(
          ticketsRef
            .where("ticketTypeId", "==", ticketTypeId)
            .where("status", "==", "available")
            .limit(1)
        );

        if (availableTicketQuery.empty) {
          logger.error(`❌ ERREUR CRITIQUE: Paiement réussi mais plus de tickets disponibles pour ${ticketTypeId}`);
          t.update(transactionRef, {
            status: "failed",
            failureReason: "Paiement réussi mais stock de tickets épuisé",
            requiresManualReview: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            webhookData: webhookData,
          });
          return;
        }

        const ticketToSellRef = availableTicketQuery.docs[0].ref;
        const ticketData = availableTicketQuery.docs[0].data();
        
        logger.info(`🎫 Attribution du ticket ${ticketToSellRef.id} à la transaction ${externalId}`);

        // Mettre à jour le ticket
        t.update(ticketToSellRef, {
          status: "sold",
          soldAt: admin.firestore.FieldValue.serverTimestamp(),
          buyerPhoneNumber: freshData.phoneNumber,
          transactionId: externalId,
          freemopayReference: reference,
        });

        // Mettre à jour la transaction
        t.update(transactionRef, {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          webhookData: webhookData,
          ticketId: ticketToSellRef.id,
          ticketCredentials: {
            username: ticketData.username,
            password: ticketData.password,
          },
        });

        // Mettre à jour les compteurs du type de ticket
        const ticketTypeRef = db.collection("ticket_types").doc(ticketTypeId);
        t.update(ticketTypeRef, {
          ticketsSold: admin.firestore.FieldValue.increment(1),
          ticketsAvailable: admin.firestore.FieldValue.increment(-1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(`🎉 Transaction complétée avec succès: ${externalId}`);
      });

    } else if (status === "FAILED") {
      logger.info(`❌ Traitement de l'échec pour la transaction ${externalId}`);
      
      await transactionRef.update({
        status: "failed",
        failureReason: message || "Le paiement a échoué",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        webhookData: webhookData,
      });
      
    } else {
      logger.warn(`⚠️ Statut inconnu reçu pour ${externalId}: ${status}`);
      
      await transactionRef.update({
        status: "unknown",
        lastWebhookData: webhookData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    logger.info(`🏁 Traitement du webhook terminé pour ${externalId}`);
    res.status(200).send("Webhook processed successfully");

  } catch (error) {
    logger.error(`🔥 Erreur lors du traitement du webhook pour ${externalId}`, {
      error: error.toString(),
      stack: error.stack,
      webhookData: webhookData,
    });
    
    // Tenter de marquer la transaction en erreur
    try {
      await transactionRef.update({
        status: "error",
        errorMessage: error.message,
        errorWebhookData: webhookData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (updateError) {
      logger.error("❌ Impossible de mettre à jour la transaction en erreur", {
        error: updateError.message,
      });
    }
    
    res.status(500).send("Internal Server Error");
  }
});

// ===== FONCTION 3: NETTOYAGE DES TRANSACTIONS EXPIRÉES =====

exports.cleanupExpiredTransactions = require("firebase-functions/v2/scheduler").onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "Africa/Douala",
  },
  async (event) => {
    logger.info("🧹 Démarrage du nettoyage des transactions expirées");
    
    const now = admin.firestore.Timestamp.now();
    const expiredTransactionsQuery = await db
      .collection("transactions")
      .where("status", "==", "pending")
      .where("expiresAt", "<=", now)
      .limit(100)
      .get();
    
    if (expiredTransactionsQuery.empty) {
      logger.info("✅ Aucune transaction expirée trouvée");
      return;
    }
    
    const batch = db.batch();
    let count = 0;
    
    expiredTransactionsQuery.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "expired",
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    });
    
    await batch.commit();
    logger.info(`🧹 ${count} transactions expirées nettoyées`);
  }
);

// ===== FONCTION 4: TEST DES CLÉS API =====

exports.testFreemopayAPI = onCall(async (request) => {
  logger.info("🧪 Test des clés API Freemopay");
  
  try {
    validateFreemopayConfig();
    
    // Test avec un appel minimal
    const testPayload = {
      payer: "237695509408", // Numéro de test
      amount: "10",           // Montant minimal
      externalId: `test_${Date.now()}`,
      description: "Test API depuis Cloud Function",
      callback: WEBHOOK_URL,
    };
    
    logger.info("🔑 Test d'authentification", {
      appKeyLength: FREEMOPAY_CONFIG.appKey.length,
      secretKeyLength: FREEMOPAY_CONFIG.secretKey.length,
    });
    
    const response = await axios.post(
      `${FREEMOPAY_CONFIG.baseUrl}/api/v2/payment`,
      testPayload,
      {
        headers: {
          "Content-Type": "application/json",
        },
        auth: {
          username: FREEMOPAY_CONFIG.appKey,
          password: FREEMOPAY_CONFIG.secretKey
        },
        timeout: 10000,
      }
    );
    
    logger.info("✅ Test API réussi", { 
      status: response.status,
      data: response.data 
    });
    
    return {
      success: true,
      message: "Clés API Freemopay valides",
      response: response.data
    };
    
  } catch (error) {
    logger.error("❌ Test API échoué", {
      error: error.message,
      status: error.response?.status,
      data: error.response?.data,
    });
    
    return {
      success: false,
      error: error.message,
      details: {
        status: error.response?.status,
        data: error.response?.data,
      }
    };
  }
});