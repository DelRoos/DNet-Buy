// Script principal - Point d'entrée de l'application
class HotspotApp {
  constructor() {
    this.initialized = false;
  }

  // Initialiser l'application
  async init() {
    try {
      console.log('🚀 Initialisation de l\'application hotspot...');
      
      // Afficher le loader global
uiHandlers.showPlansLoader(true, 'Initialisation...');
      
      // ✅ AJOUT: Test de connectivité d'abord
      console.log('🔍 Test de connectivité Firebase...');
      const connectionTest = await firebaseIntegration.testConnection();
uiHandlers.showPlansLoader(true, 'Connexion au serveur...');
      console.log('🔗 Résultat du test:', connectionTest ? '✅ OK' : '❌ KO');
      
      // Initialiser Firebase
      const firebaseSuccess = await firebaseIntegration.init();
uiHandlers.showPlansLoader(true, 'Chargement des forfaits...');
      
      if (firebaseSuccess && connectionTest) {
        console.log('✅ Firebase initialisé et connecté');
        uiHandlers.showPlansLoader(true, 'Chargement des forfaits...', 'Connexion au serveur');
        
        // Charger les forfaits
        await this.loadPlans();
      } else {
        console.warn('⚠️ Firebase non disponible, utilisation des forfaits de fallback');
        this.useFallbackPlans();
      }
      
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

  // Charger les forfaits depuis Firebase
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

  // Utiliser les forfaits de fallback
  useFallbackPlans() {
    console.log('📋 Utilisation des forfaits de fallback');
    uiHandlers.updatePlansUI(CONFIG.fallbackPlans);
    
    // Afficher une notification discrète
    this.showErrorNotification('Forfaits en mode hors ligne - Fonctionnalités limitées');
  }

  // Gérer les erreurs d'initialisation
  handleInitError(error) {
    console.error('💥 Erreur critique:', error);
    
    // Masquer le loader et afficher un message d'erreur
    uiHandlers.showPlansLoader(false);
    
    // Utiliser les forfaits de fallback en cas d'erreur
    this.useFallbackPlans();
  }

  // Afficher une notification d'erreur
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
    
    // Auto-suppression après 8 secondes
    setTimeout(() => {
      if (notification.parentElement) {
        notification.remove();
      }
    }, 8000);
  }
}

// Instance globale de l'application
const hotspotApp = new HotspotApp();

// Initialisation au chargement du DOM
document.addEventListener('DOMContentLoaded', () => {
  console.log('📄 DOM chargé, initialisation de l\'application...');
  console.log('🔧 Configuration actuelle:', {
    zoneId: CONFIG.zone.id,
    cloudFunctionsUrl: CONFIG.api.cloudFunctionsUrl,
    hasFirebaseConfig: !!CONFIG.firebase.apiKey
  });
  
  hotspotApp.init();
});

// Gestion des erreurs globales
window.addEventListener('error', (event) => {
  console.error('💥 Erreur JavaScript globale:', event.error);
});

// Gestion des promesses rejetées
window.addEventListener('unhandledrejection', (event) => {
  console.error('💥 Promise rejetée non gérée:', event.reason);
});

// Gestion de la fermeture de la page
window.addEventListener('beforeunload', () => {
  // Nettoyer les intervals en cours
  if (uiHandlers.transactionMonitorInterval) {
    uiHandlers.stopTransactionMonitoring();
  }
});