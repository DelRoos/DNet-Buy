class HotspotApp {
  constructor() {
    this.initialized = false;
  }

  async init() {
    try {
      uiHandlers.showPlansLoader(true, 'Initialisation...');
      
      const firebaseSuccess = await firebaseIntegration.init();
      
      if (firebaseSuccess) {
        uiHandlers.showPlansLoader(true, 'Chargement des forfaits...');
      } else {
        uiHandlers.showPlansLoader(true, 'Mode hors ligne...');
      }
      
      await this.loadPlans();
      
      this.initialized = true;
      
      setTimeout(() => {
        uiHandlers.showPlansLoader(false);
      }, 500);
      
    } catch (error) {
      this.handleInitError(error);
    }
  }

  async loadPlans() {
    try {
      uiHandlers.showPlansLoader(true);
      
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Timeout de chargement')), CONFIG.ui.loaderTimeout);
      });
      
      const result = await Promise.race([
        firebaseIntegration.getPlans(),
        timeoutPromise
      ]);
      
      if (result.success) {
        uiHandlers.updatePlansUI(result.plans, result.zone);
      } else {
        throw new Error(result.error || 'Erreur inconnue');
      }
      
    } catch (error) {
      this.useFallbackPlans();
    }
  }

  useFallbackPlans() {
    uiHandlers.updatePlansUI(CONFIG.fallbackPlans);
    this.showErrorNotification('Forfaits en mode hors ligne - Fonctionnalités limitées');
  }

  handleInitError(error) {
    uiHandlers.showPlansLoader(false);
    this.useFallbackPlans();
  }

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

const hotspotApp = new HotspotApp();

document.addEventListener('DOMContentLoaded', () => {
  hotspotApp.init();
});

window.addEventListener('error', (event) => {
  console.error('Erreur JavaScript globale:', event.error);
});

window.addEventListener('unhandledrejection', (event) => {
  console.error('Promise rejetée non gérée:', event.reason);
});

window.addEventListener('beforeunload', () => {
  if (uiHandlers.transactionMonitorInterval) {
    uiHandlers.stopTransactionMonitoring();
  }
});