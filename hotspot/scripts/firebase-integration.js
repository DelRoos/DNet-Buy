// Gestion de l'intégration Firebase
class FirebaseIntegration {
  constructor() {
    this.functions = null;
    this.initialized = false;
  }

  // Initialiser Firebase
  async init() {
    try {
      if (this.initialized) return true;

      // Vérifier que la configuration Firebase existe
      if (!CONFIG.firebase || !CONFIG.firebase.apiKey) {
        console.warn('⚠️ Configuration Firebase manquante, mode dégradé activé');
        return false;
      }

      // Initialiser Firebase
      firebase.initializeApp(CONFIG.firebase);
      this.functions = firebase.functions();

      this.initialized = true;
      console.log('✅ Firebase initialisé avec succès');
      return true;
    } catch (error) {
      console.error('❌ Erreur d\'initialisation Firebase:', error);
      return false;
    }
  }

  // Récupérer les forfaits depuis Firebase
  async getPlans() {
    try {
      // ✅ CORRECTION : Construction correcte de l'URL
      let url = `${CONFIG.api.cloudFunctionsUrl}${CONFIG.api.endpoints.getPlans}?zoneId=${CONFIG.zone.id}`;
      
      if (CONFIG.zone.publicKey) {
        url += `&publicKey=${CONFIG.zone.publicKey}`;
      }

      console.log('🔍 Appel de l\'API:', url);

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      });
      
      console.log('📡 Réponse reçue:', response.status, response.statusText);

      if (!response.ok) {
        // Gestion spécifique des erreurs HTTP
        let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
        
        try {
          const errorData = await response.json();
          errorMessage = errorData.error || errorMessage;
        } catch (parseError) {
          // Si on ne peut pas parser la réponse, garder le message HTTP
        }
        
        throw new Error(errorMessage);
      }

      const data = await response.json();
      console.log('📦 Données reçues:', data);

      if (data.success && data.plans && data.plans.length > 0) {
        console.log(`✅ ${data.plans.length} forfaits chargés depuis Firebase`);
        return {
          success: true,
          plans: data.plans,
          zone: data.zone
        };
      } else {
        throw new Error(data.error || 'Aucun forfait disponible');
      }
    } catch (error) {
      console.error('❌ Erreur lors du chargement des forfaits:', error);
      return {
        success: false,
        error: error.message,
        plans: CONFIG.fallbackPlans
      };
    }
  }

  // Initier un paiement (HTTP onRequest)
async initiatePayment(ticketTypeId, phoneNumber) {
  // ensure init() was called if you need firebase for other things, but not required for HTTP
  const url = `${CONFIG.api.cloudFunctionsUrl}/initiatePayment`;
  const body = {
    planId: ticketTypeId,          // <-- CF attend planId
    phoneNumber: phoneNumber,
    externalId: undefined          // ou fournissez un ID pour l’idempotence
  };

  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type':'application/json', 'Accept':'application/json' },
    body: JSON.stringify(body)
  });

  if (!resp.ok) {
    let msg = `HTTP ${resp.status}`;
    try { const err = await resp.json(); msg = err.error || msg; } catch {}
    throw new Error(msg);
  }
  const data = await resp.json();
  // attendu: { success:true, transactionId, freemopayReference, amount }
  return data;
}

// Vérifier le statut (HTTP onRequest)
async checkTransactionStatus(transactionId) {
  const url = `${CONFIG.api.cloudFunctionsUrl}/checkTransactionStatus?transactionId=${encodeURIComponent(transactionId)}`;
  const resp = await fetch(url, { method: 'GET', headers: { 'Accept':'application/json' }});
  if (!resp.ok) {
    let msg = `HTTP ${resp.status}`;
    try { const err = await resp.json(); msg = err.error || msg; } catch {}
    throw new Error(msg);
  }
  return await resp.json(); // { success:true, transaction:{...} }
}


  // // Vérifier le statut d'une transaction
  // async checkTransactionStatus(transactionId) {
  //   try {
  //     if (!this.initialized) {
  //       const initSuccess = await this.init();
  //       if (!initSuccess) {
  //         throw new Error('Firebase non disponible');
  //       }
  //     }

  //     const checkTransaction = this.functions.httpsCallable(CONFIG.api.endpoints.checkTransaction);

  //     const result = await checkTransaction({ transactionId });

  //     return result.data;
  //   } catch (error) {
  //     console.error('❌ Erreur lors de la vérification:', error);
  //     throw error;
  //   }
  // }

  // Méthode de test pour vérifier la connectivité
  async testConnection() {
    try {
      const testUrl = `${CONFIG.api.cloudFunctionsUrl}/getPublicTicketTypes?zoneId=test`;
      const response = await fetch(testUrl, { method: 'HEAD' });
      return response.status !== 404; // 404 = fonction non trouvée, autres codes = fonction existe
    } catch (error) {
      console.error('❌ Test de connexion échoué:', error);
      return false;
    }
  }
}

// Instance globale
const firebaseIntegration = new FirebaseIntegration();