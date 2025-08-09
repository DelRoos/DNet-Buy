/**
 * Application de portail captif Dnet - Point d'entrée principal
 * 
 * Cette classe gère l'initialisation et le cycle de vie de l'application
 * de vente de forfaits Internet via portail captif.
 * 
 * Fonctionnalités principales:
 * - Initialisation de l'application et des services Firebase
 * - Chargement des forfaits Internet disponibles
 * - Gestion des fallbacks en cas d'indisponibilité du service
 * - Gestion globale des erreurs
 * 
 * @author Dnet Team
 * @version 1.0
 */
class HotspotApp {
  constructor() {
    this.initialized = false;
  }

  /**
   * Initialise l'application de portail captif
   * 
   * Cette méthode est le point d'entrée principal qui:
   * 1. Affiche un indicateur de chargement
   * 2. Charge les forfaits disponibles depuis Firebase ou utilise les forfaits de fallback
   * 3. Gère les erreurs d'initialisation
   * 
   * @async
   * @returns {Promise<void>}
   */
  async init() {
    try {
      console.log('🚀 Initialisation de l\'application hotspot...');
      
      // Afficher le loader global
      uiHandlers.showPlansLoader(true, 'Initialisation...');
      
//       // ✅ AJOUT: Test de connectivité d'abord
//       console.log('🔍 Test de connectivité Firebase...');
//       const connectionTest = await firebaseIntegration.testConnection();
// uiHandlers.showPlansLoader(true, 'Connexion au serveur...');
//       console.log('🔗 Résultat du test:', connectionTest ? '✅ OK' : '❌ KO');
      
//       // Initialiser Firebase
//       const firebaseSuccess = await firebaseIntegration.init();
// uiHandlers.showPlansLoader(true, 'Chargement des forfaits...');
      
//       if (firebaseSuccess && connectionTest) {
//         console.log('✅ Firebase initialisé et connecté');
//         uiHandlers.showPlansLoader(true, 'Chargement des forfaits...', 'Connexion au serveur');
        
//         // Charger les forfaits
//         await this.loadPlans();
//       } else {
//         console.warn('⚠️ Firebase non disponible, utilisation des forfaits de fallback');
//         this.useFallbackPlans();
//       }
      
      // Initialiser Firebase et Firestore
      console.log('🔥 Initialisation Firebase...');
      const firebaseSuccess = await firebaseIntegration.init();
      
      if (firebaseSuccess) {
        console.log('✅ Firebase initialisé avec succès');
        uiHandlers.showPlansLoader(true, 'Chargement des forfaits...');
      } else {
        console.warn('⚠️ Firebase non disponible, mode dégradé');
        uiHandlers.showPlansLoader(true, 'Mode hors ligne...');
      }
      
      await this.loadPlans();
      
      this.initialized = true;
      
      // Masquer le loader global
      setTimeout(() => {
        uiHandlers.showPlansLoader(false);
      }, 500);
      
      console.log('✅ Application initialisée avec succès');
      
    } catch (error) {
      console.error('❌ Erreur lors de l\'initialisation:', error);
      this.handleInitError(error);
    }
  }

  /**
   * Charge les forfaits Internet disponibles depuis Firebase
   * 
   * Cette méthode tente de récupérer les forfaits depuis l'API Firebase.
   * En cas d'échec (timeout, erreur réseau, etc.), elle utilise automatiquement
   * les forfaits de fallback définis dans la configuration.
   * 
   * @async
   * @returns {Promise<void>}
   */
  async loadPlans() {
    try {
      console.log('📋 Chargement des forfaits depuis Firebase...');
      
      // Afficher le loader des forfaits
      uiHandlers.showPlansLoader(true);
      
      // Timeout pour éviter d'attendre trop longtemps
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Timeout de chargement')), CONFIG.ui.loaderTimeout);
      });
      
      // Course entre le chargement et le timeout
      const result = await Promise.race([
        firebaseIntegration.getPlans(),
        timeoutPromise
      ]);
      
      if (result.success) {
        uiHandlers.updatePlansUI(result.plans, result.zone);
        console.log('✅ Forfaits chargés depuis Firebase');
      } else {
        console.warn('⚠️ Pas de forfaits Firebase disponibles:', result.error);
        throw new Error(result.error || 'Erreur inconnue');
      }
      
    } catch (error) {
      console.warn('⚠️ Erreur lors du chargement des forfaits Firebase:', error.message);
      this.useFallbackPlans();
    }
  }

  /**
   * Active les forfaits de fallback en cas d'indisponibilité de Firebase
   * 
   * Cette méthode charge les forfaits définis localement dans CONFIG.fallbackPlans
   * et affiche une notification discrète à l'utilisateur pour l'informer du mode dégradé.
   * 
   * @returns {void}
   */
  useFallbackPlans() {
    console.log('📋 Utilisation des forfaits de fallback');
    uiHandlers.updatePlansUI(CONFIG.fallbackPlans);
    
    this.showErrorNotification('Forfaits en mode hors ligne - Fonctionnalités limitées');
  }

  /**
   * Gère les erreurs critiques survenues lors de l'initialisation
   * 
   * Cette méthode est appelée en cas d'erreur fatale empêchant le démarrage
   * normal de l'application. Elle masque les indicateurs de chargement et
   * active automatiquement les forfaits de fallback.
   * 
   * @param {Error} error - L'erreur survenue lors de l'initialisation
   * @returns {void}
   */
  handleInitError(error) {
    console.error('💥 Erreur critique:', error);
    
    uiHandlers.showPlansLoader(false);
    this.useFallbackPlans();
  }

  /**
   * Affiche une notification d'erreur temporaire à l'utilisateur
   * 
   * Cette méthode crée une notification non-bloquante qui informe l'utilisateur
   * d'un problème (mode hors ligne, erreur de service, etc.) et se supprime
   * automatiquement après 8 secondes.
   * 
   * @param {string} message - Le message à afficher dans la notification
   * @returns {void}
   */
  showErrorNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'error-notification';
    notification.innerHTML = `
      <div class="notification-content">
        <span class="notification-icon">⚠️</span>
        <span class="notification-message">${message}</span>
        <button class="notification-close" onclick="this.parentElement.parentElement.remove()">×</button>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
      if (notification.parentElement) {
        notification.remove();
      }
    }, 8000);
  }
}

/**
 * Instance globale de l'application HotspotApp
 * 
 * Cette instance unique gère l'état global de l'application et est accessible
 * depuis tous les autres modules JavaScript.
 * 
 * @type {HotspotApp}
 */
const hotspotApp = new HotspotApp();

/**
 * Initialisation automatique de l'application au chargement du DOM
 * 
 * Cet événement se déclenche quand le DOM est entièrement chargé et parsé,
 * mais avant que toutes les ressources (images, CSS) soient chargées.
 */
document.addEventListener('DOMContentLoaded', () => {
  console.log('📄 DOM chargé, initialisation de l\'application...');
  console.log('🔧 Configuration actuelle:', {
    zoneId: CONFIG.zone.id,
    cloudFunctionsUrl: CONFIG.api.cloudFunctionsUrl,
    hasFirebaseConfig: !!CONFIG.firebase.apiKey
  });
  
  hotspotApp.init();
});

/**
 * Gestionnaire global des erreurs JavaScript non capturées
 * 
 * Capture toutes les erreurs JavaScript qui ne sont pas gérées explicitement
 * par l'application pour faciliter le débogage et la surveillance.
 */
window.addEventListener('error', (event) => {
  console.error('💥 Erreur JavaScript globale:', event.error);
});

/**
 * Gestionnaire global des promesses rejetées non gérées
 * 
 * Capture les promesses rejetées qui n'ont pas de gestionnaire .catch()
 * pour éviter les erreurs silencieuses dans l'application.
 */
window.addEventListener('unhandledrejection', (event) => {
  console.error('💥 Promise rejetée non gérée:', event.reason);
});

/**
 * Nettoyage des ressources avant fermeture de la page
 * 
 * Cet événement se déclenche juste avant que l'utilisateur quitte la page
 * et permet de nettoyer les timers et intervalles pour éviter les fuites mémoire.
 */
window.addEventListener('beforeunload', () => {
  if (uiHandlers.transactionMonitorInterval) {
    uiHandlers.stopTransactionMonitoring();
  }
});

