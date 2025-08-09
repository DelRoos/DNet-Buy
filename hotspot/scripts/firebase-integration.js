/**
 * Module d'intégration Firebase pour le portail captif Dnet
 * 
 * Ce module gère toutes les interactions avec les services Firebase:
 * - Communication avec les Cloud Functions via HTTP
 * - Récupération des forfaits disponibles
 * - Initiation et suivi des paiements Mobile Money
 * - Gestion des erreurs réseau avec retry automatique
 * 
 * Caractéristiques:
 * - Retry automatique avec backoff exponentiel
 * - Gestion des timeouts configurable
 * - Support des codes d'erreur HTTP spécifiques (429, 5xx)
 * - Respect des headers Retry-After
 * 
 * @author Dnet Team
 * @version 1.0
 */
class FirebaseIntegration {
  constructor() {
    this.functions = null;
    this.initialized = false;

    /**
     * Configuration réseau par défaut avec possibilité de surcharge via CONFIG.network
     * Ces valeurs sont optimisées pour un environnement mobile avec connexion variable
     */
    this.defaultTimeoutMs = (CONFIG?.network?.timeoutMs) || 10000; // 10 secondes
    this.maxRetries       = (CONFIG?.network?.maxRetries) || 4;    // 4 tentatives totales
    this.baseBackoffMs    = (CONFIG?.network?.baseBackoffMs) || 600; // 0.6 seconde de base
    this.maxBackoffMs     = (CONFIG?.network?.maxBackoffMs) || 5000; // 5 secondes maximum
  }

  /**
   * Initialise la connexion Firebase (optionnel pour les appels HTTP directs)
   * 
   * Cette méthode initialise le SDK Firebase si disponible, mais l'application
   * peut fonctionner en mode HTTP-only sans le SDK pour les endpoints publics.
   * 
   * @async
   * @returns {Promise<boolean>} true si Firebase est initialisé, false sinon
   */
  async init() {
  try {
    if (this.initialized) return true;

    if (!CONFIG.firebase || !CONFIG.firebase.apiKey) {
      console.warn('⚠️ Configuration Firebase manquante');
      return false;
    }

    // Initialiser Firebase
    if (!firebase.apps || firebase.apps.length === 0) {
      firebase.initializeApp(CONFIG.firebase);
    }
    
    // Initialiser Functions et Firestore
    this.functions = firebase.functions();
    this.firestore = firebase.firestore();
    
    // Configuration Firestore
    if (CONFIG.firestore && !CONFIG.firestore.realtimeOptions.enableLocalCache) {
      this.firestore.disableNetwork();
      await this.firestore.enableNetwork();
    }

    this.initialized = true;
    console.log('✅ Firebase + Firestore initialisés');
    return true;
  } catch (error) {
    console.error('❌ Erreur d\'initialisation Firebase:', error);
    return false;
  }
}


/**
 * Écoute en temps réel les changements d'une transaction via Firestore
 * 
 * Cette méthode remplace le système de polling en établissant un listener
 * Firestore qui se déclenche automatiquement à chaque modification.
 * 
 * @param {string} transactionId - ID de la transaction à surveiller
 * @param {Function} onUpdate - Callback appelé à chaque mise à jour
 * @param {Function} onError - Callback appelé en cas d'erreur
 * @returns {Function} Fonction pour arrêter l'écoute
 */
listenToTransaction(transactionId, onUpdate, onError) {
  if (!this.firestore) {
    console.error('❌ Firestore non initialisé');
    onError?.(new Error('Firestore non disponible'));
    return () => {};
  }

  const docRef = this.firestore
    .collection(CONFIG.firestore?.transactionsCollection || 'transactions')
    .doc(transactionId);

  console.log('👂 Démarrage écoute temps réel pour transaction:', transactionId);

  // Établir l'écoute en temps réel
  const unsubscribe = docRef.onSnapshot(
    {
      // Options pour forcer les données du serveur
      source: 'server',
      includeMetadataChanges: false
    },
    (docSnapshot) => {
      try {
        if (!docSnapshot.exists) {
          console.warn('⚠️ Transaction non trouvée:', transactionId);
          onError?.(new Error('Transaction non trouvée'));
          return;
        }

        const transactionData = docSnapshot.data();
        const lastUpdate = docSnapshot.metadata.fromCache ? 'cache' : 'serveur';
        
        console.log(`📱 Mise à jour reçue depuis ${lastUpdate}:`, transactionData);

        // Appeler le callback avec les nouvelles données
        onUpdate?.(transactionData);
        
      } catch (error) {
        console.error('❌ Erreur lors du traitement de la mise à jour:', error);
        onError?.(error);
      }
    },
    (error) => {
      console.error('❌ Erreur Firestore listener:', error);
      
      // Gestion des erreurs de permission
      if (error.code === 'permission-denied') {
        onError?.(new Error('Accès refusé à la transaction'));
        return;
      }
      
      // Gestion des erreurs réseau
      if (error.code === 'unavailable') {
        console.warn('⚠️ Firestore temporairement indisponible, tentative de reconnexion...');
        // Le SDK Firebase gère automatiquement les reconnexions
        return;
      }
      
      onError?.(error);
    }
  );

  // Timeout de sécurité
  const timeoutId = setTimeout(() => {
    console.warn('⏰ Timeout atteint pour l\'écoute Firestore');
    unsubscribe();
    onError?.(new Error('Timeout de surveillance dépassé'));
  }, CONFIG.ui?.firestoreListenerTimeout || 300000);

  // Retourner une fonction de nettoyage
  return () => {
    console.log('🛑 Arrêt de l\'écoute temps réel');
    clearTimeout(timeoutId);
    unsubscribe();
  };
}

  /**
   * Méthode helper pour les requêtes HTTP avec retry automatique
   * 
   * Cette méthode implémente un système robuste de gestion des erreurs réseau:
   * - Timeout configurable par requête
   * - Retry automatique avec backoff exponentiel
   * - Gestion spéciale des codes 429 (rate limiting)
   * - Respect des headers Retry-After
   * - Jitter aléatoire pour éviter les thundering herds
   * 
   * @async
   * @param {string} url - URL de la requête
   * @param {Object} options - Options fetch standard
   * @param {Object} retryConfig - Configuration du retry
   * @returns {Promise<Response>} Réponse HTTP
   * @throws {Error} En cas d'échec après tous les retries
   */
  async _fetchWithRetry(url, options = {}, {
    timeoutMs = this.defaultTimeoutMs,
    maxRetries = this.maxRetries,
    baseBackoffMs = this.baseBackoffMs,
    maxBackoffMs = this.maxBackoffMs,
    retryOn = [429, 500, 502, 503, 504]
  } = {}) {
    let attempt = 0;
    let lastErr = null;

    while (attempt <= maxRetries) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      try {
        const resp = await fetch(url, { ...options, signal: controller.signal });

        if (resp.ok) {
          clearTimeout(timer);
          return resp;
        }

        if (retryOn.includes(resp.status)) {
          const retryAfter = resp.headers?.get?.('retry-after');
          const retryAfterMs = retryAfter ? (parseFloat(retryAfter) * 1000) : null;

          clearTimeout(timer);
          if (attempt === maxRetries) {
            let msg = `HTTP ${resp.status}`;
            try { const data = await resp.json(); msg = data.error || msg; } catch {}
            throw new Error(msg);
          }

          const delay = retryAfterMs ?? Math.min(
            maxBackoffMs,
            Math.floor(baseBackoffMs * Math.pow(1.7, attempt)) + Math.floor(Math.random() * 200)
          );
          await new Promise(r => setTimeout(r, delay));
          attempt++;
          continue;
        }

        clearTimeout(timer);
        let msg = `HTTP ${resp.status}: ${resp.statusText}`;
        try {
          const data = await resp.json();
          msg = data.error || msg;
        } catch {}
        throw new Error(msg);

      } catch (err) {
        clearTimeout(timer);
        lastErr = err;

        const isAbort = err?.name === 'AbortError';
        if (isAbort || err?.message?.includes('NetworkError') || err?.message?.includes('Failed to fetch')) {
          if (attempt === maxRetries) break;
          const delay = Math.min(
            maxBackoffMs,
            Math.floor(baseBackoffMs * Math.pow(1.7, attempt)) + Math.floor(Math.random() * 200)
          );
          await new Promise(r => setTimeout(r, delay));
          attempt++;
          continue;
        }
        throw err;
      }
    }

    throw lastErr || new Error('Échec réseau après retries');
  }

  /**
   * Récupère la liste des forfaits disponibles depuis Firebase
   * 
   * Cette méthode effectue un appel GET vers l'endpoint public getPublicTicketTypes
   * pour récupérer les forfaits Internet disponibles pour la zone configurée.
   * 
   * @async
   * @returns {Promise<Object>} Objet contenant success, plans, zone ou error
   */
  async getPlans() {
    try {
      let url = `${CONFIG.api.cloudFunctionsUrl}${CONFIG.api.endpoints.getPlans}?zoneId=${encodeURIComponent(CONFIG.zone.id)}`;
      if (CONFIG.zone.publicKey) url += `&publicKey=${encodeURIComponent(CONFIG.zone.publicKey)}`;

      console.log('🔍 Appel GET plans:', url);

      const resp = await this._fetchWithRetry(url, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });

      const data = await resp.json();
      console.log('📦 Plans reçus:', data);

      if (data.success && Array.isArray(data.plans) && data.plans.length > 0) {
        return { success: true, plans: data.plans, zone: data.zone };
      }
      throw new Error(data.error || 'Aucun forfait disponible');
    } catch (error) {
      console.error('❌ Erreur lors du chargement des forfaits:', error?.message || error);
      return { success: false, error: error.message, plans: CONFIG.fallbackPlans };
    }
  }

  /**
   * Génère un identifiant externe unique pour les transactions
   * 
   * Cet identifiant permet d'assurer l'idempotence des requêtes de paiement
   * et de suivre les transactions côté client.
   * 
   * Format: ext_{timestamp}_{random_string}
   * 
   * @returns {string} Identifiant externe unique
   */
  genExternalId() {
    return `ext_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
  }

  /**
   * Initie un paiement Mobile Money via Firebase
   * 
   * Cette méthode envoie une requête POST à la Cloud Function pour initier
   * un paiement Mobile Money. La réponse est immédiate et contient les
   * informations de transaction.
   * 
   * @async
   * @param {string} ticketTypeId - ID du type de forfait à acheter
   * @param {string} phoneNumber - Numéro de téléphone Mobile Money
   * @returns {Promise<Object>} Réponse avec success, transactionId, amount, status
   */
  async initiatePayment(ticketTypeId, phoneNumber) {
    const externalId = this.genExternalId();
    const url = `${CONFIG.api.cloudFunctionsUrl}/initiatePublicPayment`;

    const body = {
      planId: ticketTypeId,
      phoneNumber,
      externalId
    };

    const resp = await this._fetchWithRetry(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(body)
    });

    const data = await resp.json();
    return data;
  }

  /**
   * Vérifie le statut d'une transaction en cours
   * 
   * Cette méthode effectue un appel GET pour vérifier l'état actuel
   * d'une transaction de paiement. Utilisée pour le polling en temps réel.
   * 
   * @async
   * @param {string} transactionId - ID de la transaction à vérifier
   * @returns {Promise<Object>} Statut de la transaction
   */
  async checkTransactionStatus(transactionId) {
    const url = `${CONFIG.api.cloudFunctionsUrl}/checkTransactionStatus?transactionId=${encodeURIComponent(transactionId)}`;

    const resp = await this._fetchWithRetry(url, {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    }, {
      timeoutMs: Math.min(this.defaultTimeoutMs, 6000),
      maxRetries: 2, // Peu de retries car l'UI gère le polling
      baseBackoffMs: 400,
      maxBackoffMs: 2000
    });

    return await resp.json();
  }

  /**
   * Teste la connectivité avec les services Firebase
   * 
   * Méthode utilitaire pour vérifier si les services Firebase sont accessibles
   * avant de tenter des opérations critiques. Utilisée pour le diagnostic.
   * 
   * @async
   * @returns {Promise<boolean>} true si la connectivité est OK, false sinon
   */
  async testConnection() {
    try {
      const testUrl = `${CONFIG.api.cloudFunctionsUrl}/getPublicTicketTypes?zoneId=${encodeURIComponent(CONFIG.zone.id || 'healthcheck')}`;
      const resp = await this._fetchWithRetry(testUrl, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      }, { timeoutMs: 5000, maxRetries: 1 });

      return resp.status !== 404;
    } catch (error) {
      console.error('❌ Test de connexion échoué:', error?.message || error);
      return false;
    }
  }
}

/**
 * Instance globale de FirebaseIntegration
 * 
 * Cette instance unique gère toutes les interactions avec Firebase
 * et est partagée par tous les modules de l'application.
 * 
 * @type {FirebaseIntegration}
 */
const firebaseIntegration = new FirebaseIntegration();
