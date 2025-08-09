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

  // Initier un paiement
  async initiatePayment(ticketTypeId, phoneNumber) {
    try {
      if (!this.initialized) {
        const initSuccess = await this.init();
        if (!initSuccess) {
          throw new Error('Firebase non disponible');
        }
      }

      console.log('💳 Initiation du paiement...', { ticketTypeId, phoneNumber: '***masked***' });

      const initiatePayment = this.functions.httpsCallable(CONFIG.api.endpoints.initiatePayment);

      const result = await initiatePayment({
        ticketTypeId: ticketTypeId,
        phoneNumber: phoneNumber,
        zoneId: CONFIG.zone.id
      });

      console.log('✅ Paiement initié:', result.data);
      return result.data;
    } catch (error) {
      console.error('❌ Erreur de paiement:', error);
      
      // Améliorer le message d'erreur pour l'utilisateur
      let userMessage = 'Erreur lors de l\'initiation du paiement';
      
      if (error.code === 'functions/unauthenticated') {
        userMessage = 'Service temporairement indisponible';
      } else if (error.code === 'functions/not-found') {
        userMessage = 'Service de paiement non disponible';
      } else if (error.message) {
        userMessage = error.message;
      }
      
      throw new Error(userMessage);
    }
  }

  // Vérifier le statut d'une transaction
  async checkTransactionStatus(transactionId) {
    try {
      if (!this.initialized) {
        const initSuccess = await this.init();
        if (!initSuccess) {
          throw new Error('Firebase non disponible');
        }
      }

      const checkTransaction = this.functions.httpsCallable(CONFIG.api.endpoints.checkTransaction);

      const result = await checkTransaction({ transactionId });

      return result.data;
    } catch (error) {
      console.error('❌ Erreur lors de la vérification:', error);
      throw error;
    }
  }

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