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
    // Masquer complètement la grille des forfaits
    const plansGrid = document.getElementById('plans-grid');
    if (plansGrid) {
        plansGrid.style.display = 'none';
    }

    const plansCta = document.querySelector('.plans-cta');
    if (plansCta) {
        plansCta.style.display = 'none';
    }
    
    
    // Afficher le message de contact support
    this.showContactSupportMessage();
  }

  // useFallbackPlans() {
  //   uiHandlers.updatePlansUI(CONFIG.fallbackPlans);
  //   this.showErrorNotification('Forfaits en mode hors ligne - Fonctionnalités limitées');
  // }

  handleInitError(error) {
    uiHandlers.showPlansLoader(false);
    this.useFallbackPlans();
  }

  // showErrorNotification(message) {
  //   const notification = document.createElement('div');
  //   notification.className = 'error-notification';
  //   notification.innerHTML = `
  //     <div class="notification-content">
  //       <span class="notification-icon">⚠️</span>
  //       <span class="notification-message">${message}</span>
  //       <button class="notification-close" onclick="this.parentElement.parentElement.remove()">×</button>
  //     </div>
  //   `;
    
  //   document.body.appendChild(notification);
    
  //   setTimeout(() => {
  //     if (notification.parentElement) {
  //       notification.remove();
  //     }
  //   }, 8000);
  // }

  showContactSupportMessage() {
    const notification = document.createElement('div');
    notification.className = 'contact-support-notification';
    notification.innerHTML = `
      <div class="support-content">
        <div class="support-icon">📞</div>
        <h3>Service Temporairement Indisponible</h3>
        <p>Nous ne pouvons pas charger les forfaits automatiques actuellement.</p>
        <p><strong>Pour acheter un forfait, contactez-nous directement :</strong></p>
        
        <div class="contact-methods">
          <a href="tel:+237694221506" class="contact-button phone">
            📞 Appeler +237 6 94 22 15 06
          </a>
          <a href="https://wa.me/237694221506" target="_blank" class="contact-button whatsapp">
            💬 WhatsApp
          </a>
        </div>
        
        <div class="manual-payment-info">
          <h4>Paiement Manuel Disponible</h4>
          <p>• Paiement Orange Money / MTN Mobile Money</p>
          <p>• Réception immédiate de vos codes d'accès</p>
          <p>• Support technique inclus</p>
        </div>
      </div>
    `;
    
    // Insérer après la section des forfaits
    const plansSection = document.querySelector('.plans-info');
    if (plansSection) {
        plansSection.parentNode.insertBefore(notification, plansSection.nextSibling);
    } else {
        document.body.appendChild(notification);
    }
  }

  // Garder cette fonction pour d'autres types d'erreurs si nécessaire
  showErrorNotification(message) {
      console.error('Erreur système:', message);
      // Cette fonction peut être gardée pour d'autres erreurs non liées aux forfaits
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