// ============================
// Gestion de l'interface utilisateur
// ============================
class UIHandlers {
  constructor() {
    this.currentTransaction = null;
    // IMPORTANT : on utilise setTimeout (pas setInterval) pour backoff progressif,
    // donc on stocke l’ID ici aussi.
    this.transactionMonitorInterval = null;
  }

  // Afficher/masquer le loader global
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
      const planCard = this.createPlanCard(plan, index === 1); // 2e = "populaire"
      plansGrid.appendChild(planCard);
    });

    // Mettre à jour les infos de zone
    if (zoneInfo && zoneInfo.name) {
      const welcomeTitle = document.querySelector('.welcome-panel h1');
      if (welcomeTitle) {
        welcomeTitle.innerHTML = `Bienvenue sur<br>${zoneInfo.name}`;
      }
    }

    this.showPlansLoader(false);
  }

  // Créer une carte de forfait (avec affichage du débit)
  createPlanCard(plan, isPopular = false) {
    const planCard = document.createElement('div');
    planCard.className = `plan-card ${isPopular ? 'popular' : ''}`;

    if (!plan.isAvailable) {
      planCard.classList.add('disabled');
    }

    planCard.onclick = plan.isAvailable
      ? () => PaymentFlow.open(plan) // tu gères le flow dans PaymentFlow
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

  // (Ancien flux) Clic plan avec prompt — conservé si besoin
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
        this.showPaymentSuccess(result); // affiche “paiement initié”
        // nouvelle logique : réponse immédiate, puis polling
        this.startTransactionMonitoring(result.transactionId);
      } else {
        throw new Error(result.error || 'Erreur inconnue');
      }
    } catch (error) {
      console.error('❌ Erreur de paiement:', error);
      this.showPaymentError(error.message || "Impossible d'initier le paiement");
    }
  }

  showUnavailableMessage(plan) {
    alert(`😔 Désolé, le forfait "${plan.name}" est temporairement épuisé.\n\nVeuillez choisir un autre forfait ou réessayer plus tard.`);
  }

  // Modal de paiement — étape "initiation"
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

  /**
   * Affiche l'état initial du paiement avec informations détaillées
   * 
   * @param {Object} result - Résultat de l'initiation de paiement
   */
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
            <div class="status-indicator">
              <div class="spinner-small"></div>
              <span id="status-text">En attente de votre confirmation...</span>
            </div>
            <div class="status-timer">
              <span id="countdown-timer">2:00</span>
            </div>
          </div>
        </div>
      `;
      
      // Démarrer le compte à rebours
      this.startPaymentCountdown();
    }
  }

  // Erreur d'initiation
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

  // ============================
  // Monitoring transaction — backoff progressif
  // ============================
/**
 * Démarre la surveillance temps réel d'une transaction via Firestore
 * 
 * Cette méthode remplace l'ancien système de polling par une écoute
 * en temps réel des modifications Firestore.
 * 
 * @param {string} transactionId - ID de la transaction à surveiller
 */
startTransactionMonitoring(transactionId) {
  // Arrêter toute surveillance précédente
  this.stopTransactionMonitoring();

  this.currentTransaction = transactionId;
  const startedAt = Date.now();

  console.log('🚀 Démarrage surveillance Firestore:', transactionId);

  // Callbacks pour les mises à jour
  const onUpdate = (transactionData) => {
    try {
      console.log('📨 Nouvelle donnée reçue:', transactionData);

      // Vérifier les statuts finaux
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

      // Mettre à jour l'interface pour les statuts intermédiaires
      if (transactionData.status === 'pending' || transactionData.status === 'processing') {
        this.updateTransactionStatus(transactionData);
      }
      
      // Gérer le statut "created" - en attente d'initiation Mobile Money
      if (transactionData.status === 'created') {
        this.updateStatusMessage("Initiation du paiement Mobile Money...");
      }

    } catch (error) {
      console.error('❌ Erreur lors du traitement de la mise à jour:', error);
      this.showTransactionFailed('Erreur de traitement');
      this.stopTransactionMonitoring();
    }
  };

  const onError = (error) => {
    console.error('❌ Erreur de surveillance Firestore:', error);
    
    // En cas d'erreur, revenir au polling comme fallback
    console.log('🔄 Basculement vers le mode polling de secours');
    this.startPollingFallback(transactionId);
  };

  // Démarrer l'écoute Firestore
  this.firestoreUnsubscribe = firebaseIntegration.listenToTransaction(
    transactionId, 
    onUpdate, 
    onError
  );

  // Timeout de sécurité global
  this.monitoringTimeout = setTimeout(() => {
    console.warn('⏰ Timeout global de surveillance atteint');
    this.showTransactionTimeout();
    this.stopTransactionMonitoring();
  }, CONFIG.ui?.firestoreListenerTimeout || 300000);
}

/**
 * Arrête la surveillance de transaction
 */
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
  console.log('✅ Surveillance arrêtée');
}

/**
 * Mode de secours avec polling en cas d'échec Firestore
 * 
 * @param {string} transactionId - ID de la transaction
 */
startPollingFallback(transactionId) {
  console.log('🔄 Activation du mode polling de secours');
  
  // Utiliser l'ancien système de polling comme fallback
  let attempt = 0;
  const startedAt = Date.now();
  const HARD_TIMEOUT = 60000; // 1 minute en mode secours
  const BASE_DELAY = 3000; // 3 secondes
  const MAX_DELAY = 8000; // 8 secondes max

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
      console.warn('[polling fallback]', err?.message || err);
    }

    // Backoff progressif
    attempt++;
    const nextDelay = Math.min(MAX_DELAY, Math.floor(BASE_DELAY * Math.pow(1.3, attempt)));
    this.transactionMonitorInterval = setTimeout(poll, nextDelay);
  };

  // Démarrer le polling de secours
  this.transactionMonitorInterval = setTimeout(poll, 1000);
}

/**
 * Met à jour l'interface pour les statuts intermédiaires
 * 
 * @param {Object} transactionData - Données de transaction
 */
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

/**
 * Convertit le statut technique en texte utilisateur
 * 
 * @param {string} status - Statut technique
 * @returns {string} Texte à afficher
 */
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

/**
 * Démarre le compte à rebours de 2 minutes pour le paiement
 * Met à jour l'interface en temps réel et gère l'expiration
 */
startPaymentCountdown() {
  const PAYMENT_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes
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
    const statusElement = document.getElementById('status-text');
    
    if (timerElement) {
      timerElement.textContent = timeString;
      // Changer la couleur quand il reste moins de 30 secondes
      if (remaining <= 30000) {
        timerElement.style.color = '#ff4444';
        timerElement.style.fontWeight = 'bold';
      }
    }
    
    // Messages progressifs selon le temps restant
    if (statusElement) {
      if (remaining > 90000) { // Plus de 1m30
        statusElement.textContent = "En attente de votre confirmation...";
      } else if (remaining > 30000) { // Plus de 30s
        statusElement.textContent = "Veuillez confirmer rapidement sur votre téléphone";
      } else { // Moins de 30s
        statusElement.textContent = "⚠️ Attention: Temps limite bientôt écoulé !";
        statusElement.style.color = '#ff4444';
      }
    }
  };
  
  // Mise à jour immédiate puis chaque seconde
  updateCountdown();
  this.countdownInterval = setInterval(updateCountdown, 1000);
}

/**
 * Gère l'expiration du délai de paiement (2 minutes écoulées)
 */
handlePaymentTimeout() {
  if (this.countdownInterval) {
    clearInterval(this.countdownInterval);
    this.countdownInterval = null;
  }
  
  console.warn('⏰ Timeout de paiement atteint (2 minutes)');
  
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
  
  // Arrêter toute surveillance en cours
  this.stopTransactionMonitoring();
}

/**
 * Met à jour le message de statut sans changer le reste de l'interface
 * 
 * @param {string} message - Nouveau message à afficher
 */
updateStatusMessage(message) {
  const statusElement = document.getElementById('status-text');
  if (statusElement && !message.includes('Attention')) {
    statusElement.textContent = message;
    statusElement.style.color = ''; // Reset color
  }
}

  stopTransactionMonitoring() {
    if (this.transactionMonitorInterval) {
      clearTimeout(this.transactionMonitorInterval);
      this.transactionMonitorInterval = null;
    }
    this.currentTransaction = null;
  }

  // ============================
  // États finaux UI
  // ============================
  showTransactionCompleted(transaction) {
    // Arrêter le compte à rebours s'il est actif
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }

    const content = document.getElementById('payment-content');
    if (!content) return;

    const username = transaction?.credentials?.username || '—';
    const password = transaction?.credentials?.password || '—';
    const ticketTypeName = transaction?.ticketTypeName || 'Votre forfait';

    content.innerHTML = `
      <div class="payment-completed">
        <div class="success-icon">🎉</div>
        <h4>Paiement confirmé avec succès !</h4>
        <div class="success-message">
          <p><strong>Félicitations ! Votre paiement a été validé.</strong></p>
          <p>Voici vos identifiants WiFi pour vous connecter :</p>
        </div>
        
        <div class="credentials">
          <div class="credential-item">
            <label>👤 Nom d'utilisateur:</label>
            <span class="credential-value" onclick="copyToClipboard('${username}')">${username}</span>
            <button class="copy-btn" onclick="copyToClipboard('${username}')">📋</button>
          </div>
          <div class="credential-item">
            <label>🔑 Mot de passe:</label>
            <span class="credential-value" onclick="copyToClipboard('${password}')">${password}</span>
            <button class="copy-btn" onclick="copyToClipboard('${password}')">📋</button>
          </div>
        </div>
        
        <div class="usage-instructions">
          <div class="instruction-box">
            <h5>🚀 Comment vous connecter :</h5>
            <ol>
              <li>Copiez les identifiants ci-dessus</li>
              <li>Collez-les dans le formulaire de connexion en haut de la page</li>
              <li>Cliquez sur "Se connecter"</li>
              <li>Profitez de votre connexion Internet !</li>
            </ol>
          </div>
          <p class="forfait-info">📦 <strong>Forfait:</strong> ${ticketTypeName}</p>
        </div>
        
        <div class="completion-actions">
          <button onclick="closePaymentModal(); fillLoginForm('${username}', '${password}')" class="primary-button">
            Se connecter maintenant
          </button>
          <button onclick="closePaymentModal()" class="secondary-button">Fermer</button>
        </div>
      </div>
    `;
  }

  // Accepte soit un string (message), soit un objet transaction
  showTransactionFailed(messageOrTx) {
    // Arrêter le compte à rebours s'il est actif
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

// ============================
// Fonctions globales UI
// ============================
const uiHandlers = new UIHandlers();

// Toggle mot de passe — FIX du SVG cassé
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

/**
 * Copie un texte dans le presse-papiers
 * 
 * @param {string} text - Texte à copier
 */
function copyToClipboard(text) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      // Visual feedback
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
    // Fallback pour navigateurs plus anciens
    const textArea = document.createElement('textarea');
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
    document.body.removeChild(textArea);
    alert('Identifiant copié !');
  }
}

/**
 * Remplit automatiquement le formulaire de connexion
 * 
 * @param {string} username - Nom d'utilisateur
 * @param {string} password - Mot de passe
 */
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
  
  // Visual feedback
  if (usernameField) {
    usernameField.style.backgroundColor = '#e8f5e8';
    setTimeout(() => {
      usernameField.style.backgroundColor = '';
    }, 2000);
  }
}

// Fermer le modal de paiement
function closePaymentModal() {
  const modal = document.getElementById('payment-modal');
  if (modal) {
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
  }
  // Stop le monitoring si en cours
  uiHandlers.stopTransactionMonitoring();
}
