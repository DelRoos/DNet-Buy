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
    if (modal) modal.style.display = 'flex';

    const loaderText = loader ? loader.querySelector('p') : null;
    if (loaderText) loaderText.textContent = `Initialisation du paiement pour ${phoneNumber}...`;
  }

  // Feedback "paiement initié"
  showPaymentSuccess(result) {
    const loader = document.getElementById('payment-loader');
    const content = document.getElementById('payment-content');

    if (loader) loader.style.display = 'none';
    if (content) {
      content.style.display = 'block';
      content.innerHTML = `
        <div class="payment-success">
          <div class="success-icon">✅</div>
          <h4>Paiement initié avec succès !</h4>
          <p>Référence: <strong>${result.freemopayReference || '—'}</strong></p>
          <p>Montant: <strong>${Number(result.amount).toLocaleString()} F</strong></p>
          <div class="payment-instructions">
            <p>📱 <strong>Vérifiez votre téléphone</strong></p>
            <p>Confirmez le paiement pour recevoir vos identifiants WiFi.</p>
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
  startTransactionMonitoring(transactionId) {
    // stop un éventuel monitoring précédent
    this.stopTransactionMonitoring();

    this.currentTransaction = transactionId;

    let attempt = 0;
    const startedAt = Date.now();
    const HARD_TIMEOUT = CONFIG.ui.transactionMonitorTimeout || 90000; // 90s par défaut
    const BASE_DELAY = CONFIG.ui.transactionCheckInterval || 1500;     // 1.5s par défaut
    const MAX_DELAY = 6000; // plafonné à 6s

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
            // accepte soit un objet, soit un message
            this.showTransactionFailed(tx.providerMessage || 'Paiement échoué');
            this.stopTransactionMonitoring();
            return;
          }

          // sinon: created / pending → on continue
        }
      } catch (err) {
        // erreurs réseau / 5xx : on log et on retente
        console.warn('[poll]', err?.message || err);
      }

      // backoff (1.5^n) jusqu’à MAX_DELAY
      attempt++;
      const nextDelay = Math.min(MAX_DELAY, Math.floor(BASE_DELAY * Math.pow(1.5, attempt)));
      this.transactionMonitorInterval = setTimeout(poll, nextDelay);
    };

    // premier poll rapide
    this.transactionMonitorInterval = setTimeout(poll, 800);
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
    const content = document.getElementById('payment-content');
    if (!content) return;

    const username = transaction?.credentials?.username || '—';
    const password = transaction?.credentials?.password || '—';
    const ticketTypeName = transaction?.ticketTypeName || 'Votre forfait';

    content.innerHTML = `
      <div class="payment-completed">
        <div class="success-icon">🎉</div>
        <h4>Paiement réussi !</h4>
        <p>Voici vos identifiants WiFi :</p>
        <div class="credentials">
          <div class="credential-item">
            <label>Nom d'utilisateur:</label>
            <span class="credential-value">${username}</span>
          </div>
          <div class="credential-item">
            <label>Mot de passe:</label>
            <span class="credential-value">${password}</span>
          </div>
        </div>
        <div class="usage-instructions">
          <p>✅ Utilisez ces identifiants dans le formulaire de connexion ci-dessus</p>
          <p>⏰ Forfait: ${ticketTypeName}</p>
        </div>
        <button onclick="closePaymentModal()" class="close-button">Fermer</button>
      </div>
    `;
  }

  // Accepte soit un string (message), soit un objet transaction
  showTransactionFailed(messageOrTx) {
    const content = document.getElementById('payment-content');
    if (!content) return;

    const msg = typeof messageOrTx === 'string'
      ? messageOrTx
      : (messageOrTx?.providerMessage || "Le paiement n'a pas pu être traité.");

    content.innerHTML = `
      <div class="payment-failed">
        <div class="error-icon">❌</div>
        <h4>Paiement échoué</h4>
        <p>${msg}</p>
        <p>Veuillez réessayer ou contacter le support.</p>
        <button onclick="closePaymentModal()" class="retry-button">Fermer</button>
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

// Fermer le modal de paiement
function closePaymentModal() {
  const modal = document.getElementById('payment-modal');
  if (modal) modal.style.display = 'none';
  // Stop le monitoring si en cours
  uiHandlers.stopTransactionMonitoring();
}
