// Gestion de l'interface utilisateur
class UIHandlers {
  constructor() {
    this.currentTransaction = null;
    this.transactionMonitorInterval = null;
  }

  // Afficher/masquer le loader global
  showGlobalLoader(show, message = 'Chargement...', subtext = 'Veuillez patienter') {
    const loader = document.getElementById('global-loader');
    const text = loader.querySelector('.loader-text');
    const subText = loader.querySelector('.loader-subtext');
    
    if (show) {
      text.textContent = message;
      subText.textContent = subtext;
      loader.style.display = 'flex';
      document.body.style.overflow = 'hidden';
    } else {
      loader.style.display = 'none';
      document.body.style.overflow = '';
    }
  }

  // Afficher/masquer le loader des forfaits
  showPlansLoader(show, message = null) {
    const loader = document.getElementById('plans-loader');
    const grid = document.getElementById('plans-grid');

    if (!loader || !grid) return;

    if (show) {
      const text = loader.querySelector('p');
      if (text && message) text.textContent = message;
      loader.style.display = 'block';
      grid.style.display = 'none';
    } else {
      loader.style.display = 'none';
      grid.style.display = 'grid';
    }
  }


  // Mettre à jour l'interface avec les forfaits
  updatePlansUI(plans, zoneInfo = null) {
    const plansGrid = document.getElementById('plans-grid');
    
    if (!plansGrid) return;
    
    // Vider la grille actuelle
    plansGrid.innerHTML = '';
    
    plans.forEach((plan, index) => {
      const planCard = this.createPlanCard(plan, index === 1); // Deuxième forfait = populaire
      plansGrid.appendChild(planCard);
    });
    
    // Mettre à jour les informations de la zone si disponibles
    if (zoneInfo && zoneInfo.name) {
      const welcomePanel = document.querySelector('.welcome-panel h1');
      if (welcomePanel) {
        welcomePanel.innerHTML = `Bienvenue sur<br>${zoneInfo.name}`;
      }
    }

    this.showPlansLoader(false);
  }

  // Créer une carte de forfait (version optimisée avec débit)
createPlanCard(plan, isPopular = false) {
  const planCard = document.createElement('div');
  planCard.className = `plan-card ${isPopular ? 'popular' : ''}`;
  
  if (!plan.isAvailable) {
    planCard.classList.add('disabled');
  }
  
  planCard.onclick = plan.isAvailable
  ? () => PaymentFlow.open(plan)    // <-- plus de prompt ici
  : () => uiHandlers.showUnavailableMessage(plan);
  
  // Formater les débits pour l'affichage
  const formatSpeed = (limitInKbps) => {
    if (!limitInKbps || limitInKbps === 0) return 'Illimité';
    if (limitInKbps >= 1000) return `${(limitInKbps/1000).toFixed(0)}`;
    return `${limitInKbps}`;
  };

  planCard.innerHTML = `
    <div class="plan-header">
      <div class="duration">${plan.name}</div>
      <div class="plan-price">
        ${plan.hasPromotion ? 
          `<div class="price-old">${plan.originalPrice.toLocaleString()} F</div>` : 
          ''
        }
        <div class="price">${plan.formattedPrice}</div>
      </div>
    </div>
    <div class="plan-details">
      <div class="detail-row">
        <span class="detail-icon">📶</span>
        <span class="detail-text">
          ↑ ${formatSpeed(plan.rateLimit)}
        </span>
      </div>
      <div class="detail-row">
        <span class="detail-icon">⏱️</span>
        <span class="detail-text">${plan.validityText}</span>
      </div>
      ${!plan.isAvailable ? 
        '<div class="unavailable-notice">Temporairement épuisé</div>' : 
        ''
      }
    </div>
  `;
  
  return planCard;
}

  // Gérer le clic sur un forfait
  async handlePlanClick(plan) {
    const phoneNumber = prompt(
      `💰 ${plan.name} - ${plan.formattedPrice}\n\n` +
      `Validité: ${plan.validityText}\n\n` +
      `Entrez votre numéro de téléphone Mobile Money:`
    );
    
    if (!phoneNumber) return;

    try {
      this.showPaymentModal(plan, phoneNumber);
      
      const result = await firebaseIntegration.initiatePayment(plan.id, phoneNumber);
      
      if (result.success) {
        this.showPaymentSuccess(result);
        this.startTransactionMonitoring(result.transactionId);
      } else {
        throw new Error(result.error || 'Erreur inconnue');
      }
      
    } catch (error) {
      console.error('❌ Erreur de paiement:', error);
      this.showPaymentError(error.message || 'Impossible d\'initier le paiement');
    }
  }

  // Afficher le message pour forfait indisponible
  showUnavailableMessage(plan) {
    alert(`😔 Désolé, le forfait "${plan.name}" est temporairement épuisé.\n\nVeuillez choisir un autre forfait ou réessayer plus tard.`);
  }

  // Afficher le modal de paiement
  showPaymentModal(plan, phoneNumber) {
    const modal = document.getElementById('payment-modal');
    const title = document.getElementById('modal-plan-title');
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');
    
    title.textContent = `${plan.name} - ${plan.formattedPrice}`;
    loader.style.display = 'flex';
    content.style.display = 'none';
    modal.style.display = 'flex';
    
    // Mettre à jour le message du loader
    const loaderText = loader.querySelector('p');
    loaderText.textContent = `Initialisation du paiement pour ${phoneNumber}...`;
  }

  // Afficher le succès du paiement
  showPaymentSuccess(result) {
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');
    
    loader.style.display = 'none';
    content.style.display = 'block';
    
    content.innerHTML = `
      <div class="payment-success">
        <div class="success-icon">✅</div>
        <h4>Paiement initié avec succès !</h4>
        <p>Référence: <strong>${result.freemopayReference}</strong></p>
        <p>Montant: <strong>${result.amount.toLocaleString()} F</strong></p>
        <div class="payment-instructions">
          <p>📱 <strong>Vérifiez votre téléphone</strong></p>
          <p>Confirmez le paiement sur votre téléphone pour recevoir vos identifiants WiFi.</p>
        </div>
        <div class="transaction-status">
          <div class="status-indicator">
            <div class="spinner-small"></div>
            <span>En attente de confirmation...</span>
          </div>
        </div>
      </div>
    `;
  }

  // Afficher l'erreur de paiement
  showPaymentError(errorMessage) {
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');
    
    loader.style.display = 'none';
    content.style.display = 'block';
    
    content.innerHTML = `
      <div class="payment-error">
        <div class="error-icon">❌</div>
        <h4>Erreur de paiement</h4>
        <p>${errorMessage}</p>
        <button onclick="closePaymentModal()" class="retry-button">Fermer</button>
      </div>
    `;
  }

  // Démarrer le monitoring de transaction
  startTransactionMonitoring(transactionId) {
    this.currentTransaction = transactionId;
    let attempts = 0;
    const maxAttempts = CONFIG.ui.transactionMonitorTimeout / CONFIG.ui.transactionCheckInterval;
    
    this.transactionMonitorInterval = setInterval(async () => {
      attempts++;
      
      try {
        const result = await firebaseIntegration.checkTransactionStatus(transactionId);
        
        if (result.success) {
          const transaction = result.transaction;
          
          if (transaction.status === 'completed') {
            this.showTransactionCompleted(transaction);
            this.stopTransactionMonitoring();
            return;
          } else if (transaction.status === 'failed' || transaction.status === 'expired') {
            this.showTransactionFailed(transaction);
            this.stopTransactionMonitoring();
            return;
          }
        }
        
        // Arrêter après le timeout
        if (attempts >= maxAttempts) {
          this.showTransactionTimeout();
          this.stopTransactionMonitoring();
        }
        
      } catch (error) {
        console.error('Erreur lors de la vérification:', error);
        // Continuer à essayer en cas d'erreur réseau
      }
    }, CONFIG.ui.transactionCheckInterval);
  }

  // Arrêter le monitoring
  stopTransactionMonitoring() {
    if (this.transactionMonitorInterval) {
      clearInterval(this.transactionMonitorInterval);
      this.transactionMonitorInterval = null;
    }
    this.currentTransaction = null;
  }

  // Afficher la transaction complétée
  showTransactionCompleted(transaction) {
    const content = document.getElementById('payment-content');
    
    content.innerHTML = `
      <div class="payment-completed">
        <div class="success-icon">🎉</div>
        <h4>Paiement réussi !</h4>
        <p>Voici vos identifiants WiFi :</p>
        <div class="credentials">
          <div class="credential-item">
            <label>Nom d'utilisateur:</label>
            <span class="credential-value">${transaction.credentials.username}</span>
          </div>
          <div class="credential-item">
            <label>Mot de passe:</label>
            <span class="credential-value">${transaction.credentials.password}</span>
          </div>
        </div>
        <div class="usage-instructions">
          <p>✅ Utilisez ces identifiants dans le formulaire de connexion ci-dessus</p>
          <p>⏰ Validité: ${transaction.ticketTypeName}</p>
        </div>
        <button onclick="closePaymentModal()" class="close-button">Fermer</button>
      </div>
    `;
  }

  // Afficher la transaction échouée
  showTransactionFailed(transaction) {
    const content = document.getElementById('payment-content');
    
    content.innerHTML = `
      <div class="payment-failed">
        <div class="error-icon">❌</div>
        <h4>Paiement échoué</h4>
        <p>Le paiement n'a pas pu être traité.</p>
        <p>Veuillez réessayer ou contacter le support.</p>
        <button onclick="closePaymentModal()" class="retry-button">Fermer</button>
      </div>
    `;
  }

  // Afficher le timeout
  showTransactionTimeout() {
    const content = document.getElementById('payment-content');
    
    content.innerHTML = `
      <div class="payment-timeout">
        <div class="warning-icon">⏱️</div>
        <h4>Délai d'attente dépassé</h4>
        <p>La vérification du paiement prend plus de temps que prévu.</p>
        <p>Vérifiez votre téléphone ou contactez le support si le problème persiste.</p>
        <button onclick="closePaymentModal()" class="close-button">Fermer</button>
      </div>
    `;
  }
}

// Fonctions globales pour l'interface
const uiHandlers = new UIHandlers();

// Fonction pour basculer la visibilité du mot de passe
function togglePassword() {
  const passwordInput = document.getElementById('password-input');
  const eyeIcon = document.getElementById('eye-icon');
  
  if (passwordInput.type === 'password') {
    passwordInput.type = 'text';
    eyeIcon.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
<line x1="1" y1="1" x2="23" y2="23"/>
</svg>
;   } else {     passwordInput.type = 'password';     eyeIcon.innerHTML = 
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
<circle cx="12" cy="12" r="3"/>
</svg>
`;
}
}
// Fermer le modal de paiement
function closePaymentModal() {
const modal = document.getElementById('payment-modal');
modal.style.display = 'none';
// Arrêter le monitoring si en cours
uiHandlers.stopTransactionMonitoring();
}