class UIHandlers {
  constructor() {
    this.currentTransaction = null;
    this.transactionMonitorInterval = null;
  }

  showGlobalLoader(show, message = 'Chargement...', subtext = 'Veuillez patienter') {
    const loader = document.getElementById('global-loader');
    if (!loader) return;

    const text = loader.querySelector('.loader-text');
    const subText = loader.querySelector('.loader-subtext');

    if (show) {
      if (text) text.textContent = message;
      if (subText) subText.textContent = subtext;
      loader.style.display = 'flex';
      document.body.style.overflow = 'hidden';
    } else {
      loader.style.display = 'none';
      document.body.style.overflow = '';
    }
  }

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

  updatePlansUI(plans, zoneInfo = null) {
    const plansGrid = document.getElementById('plans-grid');
    if (!plansGrid) return;

    plansGrid.innerHTML = '';

    plans.forEach((plan, index) => {
      const planCard = this.createPlanCard(plan, index === 1);
      plansGrid.appendChild(planCard);
    });

    if (zoneInfo && zoneInfo.name) {
      const welcomeTitle = document.querySelector('.welcome-panel h1');
      if (welcomeTitle) {
        welcomeTitle.innerHTML = `Bienvenue sur<br>${zoneInfo.name}`;
      }
    }

    this.showPlansLoader(false);
  }

  createPlanCard(plan, isPopular = false) {
    const planCard = document.createElement('div');
    planCard.className = `plan-card ${isPopular ? 'popular' : ''}`;

    if (!plan.isAvailable) {
      planCard.classList.add('disabled');
    }

    planCard.onclick = plan.isAvailable
      ? () => PaymentFlow.open(plan)
      : () => uiHandlers.showUnavailableMessage(plan);

    const formatSpeed = (limitInKbps) => {
      if (!limitInKbps || limitInKbps === 0) return 'Illimité';
      if (limitInKbps >= 1000) return `${(limitInKbps / 1000).toFixed(0)}`;
      return `${limitInKbps}`;
    };

    planCard.innerHTML = `
      <div class="plan-header">
        <div class="duration">${plan.name}</div>
        <div class="plan-price">
          ${plan.hasPromotion ? `<div class="price-old">${Number(plan.originalPrice).toLocaleString()} F</div>` : ''}
          <div class="price">${plan.formattedPrice}</div>
        </div>
      </div>
      <div class="plan-details">
        <div class="detail-row">
          <span class="detail-icon">📶</span>
          <span class="detail-text">↑ ${formatSpeed(plan.rateLimit)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-icon">⏱️</span>
          <span class="detail-text">${plan.validityText}</span>
        </div>
        ${!plan.isAvailable ? '<div class="unavailable-notice">Temporairement épuisé</div>' : ''}
      </div>
    `;

    return planCard;
  }

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
      this.showPaymentError(error.message || "Impossible d'initier le paiement");
    }
  }

  showUnavailableMessage(plan) {
    alert(`Oups ! Ce forfait est très demandé !\n\nLe forfait "${plan.name}" n'est plus disponible pour le moment.\nNos autres offres sont toujours là pour vous !`);
  }

  showPaymentModal(plan, phoneNumber) {
    const modal = document.getElementById('payment-modal');
    const title = document.getElementById('modal-plan-title');
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');

    if (title) title.textContent = `${plan.name} - ${plan.formattedPrice}`;
    if (loader) loader.style.display = 'flex';
    if (content) content.style.display = 'none';
    if (modal) {
      modal.style.display = 'flex';
      modal.removeAttribute('aria-hidden');
    }

    const loaderText = loader ? loader.querySelector('p') : null;
    if (loaderText) loaderText.textContent = `Initialisation du paiement pour ${phoneNumber}...`;
  }

  showPaymentSuccess(result) {
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');

    if (loader) loader.style.display = 'none';
    if (content) {
      content.style.display = 'block';
      content.innerHTML = `
        <div class="payment-success">
          <div class="success-icon">✅</div>
          <h4>Ticket réservé avec succès !</h4>
          <p>Transaction: <strong>${result.transactionId}</strong></p>
          <p>Montant: <strong>${Number(result.amount).toLocaleString()} F CFA</strong></p>
          
          <div class="payment-instructions">
            <div class="instruction-step">
              <span class="step-icon">📱</span>
              <div class="step-content">
                <strong>Vérifiez votre téléphone maintenant</strong>
                <p>Confirmez le paiement Mobile Money pour finaliser votre achat</p>
              </div>
            </div>
          </div>
          
          <div class="payment-timing">
            <div class="timing-info">
              <span class="clock-icon">⏱️</span>
              <div class="timing-text">
                <strong>Délai maximum: 2 minutes</strong>
                <p>Le paiement sera automatiquement annulé si non confirmé</p>
              </div>
            </div>
          </div>

          <div class="transaction-status">
            <div class="status-timer">
              <span id="countdown-timer">2:00</span>
            </div>
          </div>
        </div>
      `;
      
      this.startPaymentCountdown();
    }
  }

  showPaymentError(errorMessage) {
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');

    if (loader) loader.style.display = 'none';
    if (content) {
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
  }

  startTransactionMonitoring(transactionId) {
    this.stopTransactionMonitoring();
    this.currentTransaction = transactionId;
    const startedAt = Date.now();

    const onUpdate = (transactionData) => {
      try {
        if (transactionData.status === 'completed') {
          this.showTransactionCompleted(transactionData);
          this.stopTransactionMonitoring();
          return;
        }

        if (transactionData.status === 'failed' || transactionData.status === 'expired') {
          this.showTransactionFailed(
            transactionData.providerMessage || 'Paiement échoué'
          );
          this.stopTransactionMonitoring();
          return;
        }

        if (transactionData.status === 'pending' || transactionData.status === 'processing') {
          this.updateTransactionStatus(transactionData);
        }
        
        if (transactionData.status === 'created') {
          this.updateStatusMessage("Initiation du paiement Mobile Money...");
        }

      } catch (error) {
        this.showTransactionFailed('Erreur de traitement');
        this.stopTransactionMonitoring();
      }
    };

    const onError = (error) => {
      this.startPollingFallback(transactionId);
    };

    this.firestoreUnsubscribe = firebaseIntegration.listenToTransaction(
      transactionId, 
      onUpdate, 
      onError
    );

    this.monitoringTimeout = setTimeout(() => {
      this.showTransactionTimeout();
      this.stopTransactionMonitoring();
    }, CONFIG.ui?.firestoreListenerTimeout || 300000);
  }

  stopTransactionMonitoring() {
    if (this.firestoreUnsubscribe) {
      this.firestoreUnsubscribe();
      this.firestoreUnsubscribe = null;
    }

    if (this.monitoringTimeout) {
      clearTimeout(this.monitoringTimeout);
      this.monitoringTimeout = null;
    }

    if (this.transactionMonitorInterval) {
      clearTimeout(this.transactionMonitorInterval);
      this.transactionMonitorInterval = null;
    }

    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }

    this.currentTransaction = null;
  }

  startPollingFallback(transactionId) {
    let attempt = 0;
    const startedAt = Date.now();
    const HARD_TIMEOUT = 60000;
    const BASE_DELAY = 3000;
    const MAX_DELAY = 8000;

    const poll = async () => {
      if (Date.now() - startedAt > HARD_TIMEOUT) {
        this.showTransactionTimeout();
        this.stopTransactionMonitoring();
        return;
      }

      try {
        const res = await firebaseIntegration.checkTransactionStatus(transactionId);
        if (res && res.success) {
          const tx = res.transaction;

          if (tx.status === 'completed') {
            this.showTransactionCompleted(tx);
            this.stopTransactionMonitoring();
            return;
          }

          if (tx.status === 'failed' || tx.status === 'expired') {
            this.showTransactionFailed(tx.providerMessage || 'Paiement échoué');
            this.stopTransactionMonitoring();
            return;
          }
        }
      } catch (err) {
        // Continue polling on error
      }

      attempt++;
      const nextDelay = Math.min(MAX_DELAY, Math.floor(BASE_DELAY * Math.pow(1.3, attempt)));
      this.transactionMonitorInterval = setTimeout(poll, nextDelay);
    };

    this.transactionMonitorInterval = setTimeout(poll, 1000);
  }

  updateTransactionStatus(transactionData) {
    const statusElement = document.getElementById('transaction-status');
    const timestampElement = document.getElementById('transaction-timestamp');
    
    if (statusElement) {
      const statusText = this.getStatusDisplayText(transactionData.status);
      statusElement.textContent = statusText;
    }
    
    if (timestampElement) {
      const lastUpdate = transactionData.updatedAt ? 
        new Date(transactionData.updatedAt).toLocaleTimeString() : 
        new Date().toLocaleTimeString();
      timestampElement.textContent = `Dernière mise à jour: ${lastUpdate}`;
    }
  }

  getStatusDisplayText(status) {
    const statusMap = {
      'created': 'Transaction créée',
      'pending': 'En attente de confirmation',
      'processing': 'Traitement en cours',
      'completed': 'Terminée avec succès',
      'failed': 'Échouée',
      'expired': 'Expirée',
      'cancelled': 'Annulée'
    };
    
    return statusMap[status] || status;
  }

  startPaymentCountdown() {
    const PAYMENT_TIMEOUT_MS = 2 * 60 * 1000;
    const startTime = Date.now();
    
    const updateCountdown = () => {
      const elapsed = Date.now() - startTime;
      const remaining = Math.max(0, PAYMENT_TIMEOUT_MS - elapsed);
      
      if (remaining <= 0) {
        this.handlePaymentTimeout();
        return;
      }
      
      const minutes = Math.floor(remaining / 60000);
      const seconds = Math.floor((remaining % 60000) / 1000);
      const timeString = `${minutes}:${seconds.toString().padStart(2, '0')}`;
      
      const timerElement = document.getElementById('countdown-timer');
      
      if (timerElement) {
        timerElement.textContent = timeString;
        if (remaining <= 30000) {
          timerElement.style.color = '#ff4444';
          timerElement.style.fontWeight = 'bold';
        }
      }
    };
    
    updateCountdown();
    this.countdownInterval = setInterval(updateCountdown, 1000);
  }

  handlePaymentTimeout() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
    
    const content = document.getElementById('payment-content');
    if (content) {
      content.innerHTML = `
        <div class="payment-timeout">
          <div class="timeout-icon">⏰</div>
          <h4>Délai de paiement écoulé</h4>
          <div class="timeout-explanation">
            <p><strong>Le délai de 2 minutes est écoulé.</strong></p>
            <p>Votre ticket a été automatiquement libéré et le paiement annulé pour éviter tout prélèvement.</p>
          </div>
          
          <div class="next-steps">
            <h5>Que faire maintenant ?</h5>
            <div class="step-list">
              <div class="step-item">
                <span class="step-number">1</span>
                <span>Réessayez avec un nouveau paiement</span>
              </div>
              <div class="step-item">  
                <span class="step-number">2</span>
                <span>Vérifiez que votre Mobile Money est actif</span>
              </div>
              <div class="step-item">
                <span class="step-number">3</span>
                <span>Contactez le support si le problème persiste</span>
              </div>
            </div>
          </div>
          
          <div class="support-info">
            <p><strong>Support technique:</strong></p>
            <p>📞 +237 6 94 22 15 06</p>
            <p>💬 WhatsApp: <a href="https://wa.me/237694221506" target="_blank">Cliquez ici</a></p>
          </div>
          
          <div class="timeout-actions">
            <button onclick="closePaymentModal()" class="retry-button">Fermer</button>
            <button onclick="location.reload()" class="primary-button">Réessayer</button>
          </div>
        </div>
      `;
    }
    
    this.stopTransactionMonitoring();
  }

  updateStatusMessage(message) {
    const statusElement = document.getElementById('status-text');
    if (statusElement && !message.includes('Attention')) {
      statusElement.textContent = message;
      statusElement.style.color = '';
    }
  }

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
            <span class="credential-value" id="final-username">${transaction.credentials.username}</span>
          </div>
          <div class="credential-item">
            <label>Mot de passe:</label>
            <span class="credential-value" id="final-password">${transaction.credentials.password}</span>
          </div>
        </div>
        <div class="usage-instructions">
          <p>✅ Utilisez ces identifiants dans le formulaire de connexion ci-dessus</p>
          <p>⏰ Validité: ${transaction.ticketTypeName}</p>
        </div>
        
        <div class="auto-connect-section">
          <button onclick="autoConnectAndSubmit(document.getElementById('final-username').textContent, document.getElementById('final-password').textContent)" class="auto-connect-button">
            🚀 Se connecter automatiquement
          </button>
          <button onclick="closePaymentModal()" class="close-button">Fermer</button>
        </div>
      </div>
    `;
  }

  showTransactionFailed(messageOrTx) {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }

    const content = document.getElementById('payment-content');
    if (!content) return;

    const msg = typeof messageOrTx === 'string'
      ? messageOrTx
      : (messageOrTx?.providerMessage || "Le paiement n'a pas pu être traité.");

    content.innerHTML = `
      <div class="payment-failed">
        <div class="error-icon">❌</div>
        <h4>Paiement non confirmé</h4>
        <div class="error-explanation">
          <p><strong>Le paiement n'a pas pu être finalisé.</strong></p>
          <p class="error-message">${msg}</p>
        </div>
        
        <div class="failure-reasons">
          <h5>Causes possibles :</h5>
          <ul>
            <li>Paiement refusé sur votre téléphone</li>
            <li>Solde insuffisant sur votre compte Mobile Money</li>
            <li>Problème technique temporaire</li>
            <li>Délai de confirmation dépassé (2 minutes)</li>
          </ul>
        </div>
        
        <div class="failure-actions">
          <h5>Solutions :</h5>
          <div class="action-buttons">
            <button onclick="location.reload()" class="retry-button primary">
              🔄 Réessayer le paiement
            </button>
            <button onclick="closePaymentModal()" class="secondary-button">
              Fermer
            </button>
          </div>
        </div>
        
        <div class="support-contact">
          <p><strong>Besoin d'aide ?</strong></p>
          <p>📞 Support: +237 6 94 22 15 06</p>
          <p>💬 <a href="https://wa.me/237694221506" target="_blank">WhatsApp</a></p>
        </div>
      </div>
    `;
  }

  showTransactionTimeout() {
    const content = document.getElementById('payment-content');
    if (!content) return;

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

const uiHandlers = new UIHandlers();

function togglePassword() {
  const passwordInput = document.getElementById('password-input');
  const eyeIcon = document.getElementById('eye-icon');
  if (!passwordInput || !eyeIcon) return;

  if (passwordInput.type === 'password') {
    passwordInput.type = 'text';
    eyeIcon.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
        <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
        <path d="M9.9 9.9a3 3 0 0 1 4.24 4.24"/>
        <line x1="1" y1="1" x2="23" y2="23"/>
      </svg>
    `;
  } else {
    passwordInput.type = 'password';
    eyeIcon.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
        <circle cx="12" cy="12" r="3"/>
      </svg>
    `;
  }
}

function copyToClipboard(text) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      const notification = document.createElement('div');
      notification.className = 'copy-notification';
      notification.textContent = '✅ Copié !';
      notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #4CAF50;
        color: white;
        padding: 10px 15px;
        border-radius: 5px;
        z-index: 10000;
        animation: fadeInOut 2s ease-in-out;
      `;
      document.body.appendChild(notification);
      setTimeout(() => notification.remove(), 2000);
    });
  } else {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
    document.body.removeChild(textArea);
    alert('Identifiant copié !');
  }
}

function fillLoginForm(username, password) {
  const usernameField = document.getElementById('code-input') || document.querySelector('input[name="username"]');
  const passwordField = document.getElementById('password-input') || document.querySelector('input[name="password"]');
  
  if (usernameField) {
    usernameField.value = username;
    usernameField.focus();
  }
  
  if (passwordField) {
    passwordField.value = password;
  }
  
  if (usernameField) {
    usernameField.style.backgroundColor = '#e8f5e8';
    setTimeout(() => {
      usernameField.style.backgroundColor = '';
    }, 2000);
  }
}

function closePaymentModal() {
  const modal = document.getElementById('payment-modal');
  modal.style.display = 'none';
  
  uiHandlers.stopTransactionMonitoring();
  
  const savedCredentials = localStorage.getItem('dnet_credentials');
  if (savedCredentials) {
    try {
      const credentials = JSON.parse(savedCredentials);
      
      const usernameInput = document.getElementById('code-input');
      const passwordInput = document.getElementById('password-input');
      
      if (usernameInput && passwordInput) {
        usernameInput.value = credentials.username;
        passwordInput.value = credentials.password;
      }
    } catch (error) {
      console.error('Erreur lors du chargement des identifiants:', error);
    }
  }
}

function autoConnectFromCredentials() {
  try {
    const usernameElement = document.getElementById('cred-username');
    const passwordElement = document.getElementById('cred-password');
    
    if (!usernameElement || !passwordElement) {
      alert('❌ Identifiants non trouvés dans le modal');
      return;
    }
    
    const username = usernameElement.textContent.trim();
    const password = passwordElement.textContent.trim();
    
    if (!username || !password || username === '—' || password === '—') {
      alert('❌ Identifiants non valides');
      return;
    }
    
    autoConnectAndSubmit(username, password);
    
  } catch (error) {
    alert('❌ Erreur lors de la connexion automatique');
  }
}

function autoConnectAndSubmit(username, password) {
  try {
    const usernameInput = document.getElementById('code-input');
    const passwordInput = document.getElementById('password-input');
    
    if (usernameInput && passwordInput) {
      scrollToLoginForm();
      
      usernameInput.value = username;
      passwordInput.value = password;
      
      highlightFilledFields(usernameInput, passwordInput);
      
      PaymentFlow.close();
      
      setTimeout(() => {
        usernameInput.focus();
        usernameInput.select();
      }, 300);
      
      setTimeout(() => {
        const submitButton = document.querySelector('.submit-button');
        if (submitButton) {
          submitButton.click();
        } else {
          alert('❌ Bouton de connexion non trouvé');
        }
      }, 2000);
      
    } else {
      alert('❌ Champs de connexion non trouvés');
    }
    
  } catch (error) {
    alert('❌ Erreur lors de la connexion automatique');
  }
}

function scrollToLoginForm() {
  const loginForm = document.querySelector('form[name="login"]') || document.querySelector('.login-panel');
  
  if (loginForm) {
    loginForm.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
      inline: 'nearest'
    });
  } else {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  }
}

function highlightFilledFields(usernameInput, passwordInput) {
  const highlightStyle = {
    backgroundColor: '#e8f5e8',
    borderColor: '#19c394',
    boxShadow: '0 0 10px rgba(25, 195, 148, 0.3)',
    transform: 'scale(1.02)',
    transition: 'all 0.3s ease'
  };
  
  Object.assign(usernameInput.style, highlightStyle);
  Object.assign(passwordInput.style, highlightStyle);
  
  usernameInput.style.animation = 'credentialsPulse 1s ease-in-out';
  passwordInput.style.animation = 'credentialsPulse 1s ease-in-out';
  
  setTimeout(() => {
    usernameInput.style.backgroundColor = '';
    usernameInput.style.borderColor = '';
    usernameInput.style.boxShadow = '';
    usernameInput.style.transform = '';
    usernameInput.style.animation = '';
    
    passwordInput.style.backgroundColor = '';
    passwordInput.style.borderColor = '';
    passwordInput.style.boxShadow = '';
    passwordInput.style.transform = '';
    passwordInput.style.animation = '';
  }, 3000);
}