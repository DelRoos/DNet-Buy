// ====== Stockage local ======
const TicketStore = {
  KEY: 'dnet_tickets',
  all() {
    try { return JSON.parse(localStorage.getItem(this.KEY) || '[]'); } catch { return []; }
  },
  add(ticket) {
    const list = this.all();
    list.unshift({ ...ticket, savedAt: Date.now() });
    localStorage.setItem(this.KEY, JSON.stringify(list.slice(0, 100))); // on garde 100 max
  },
  clear() { localStorage.removeItem(this.KEY); }
};

// ====== Vue “Mes tickets” ======
// ====== Vue "Mes tickets" ======
const MyTickets = {
  open() {
    const modal = document.getElementById('tickets-modal');
    this.render();
    modal.style.display = 'flex';
    modal.setAttribute('aria-hidden', 'false');
  },
  close() {
    const modal = document.getElementById('tickets-modal');
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
  },
  clearAll() {
    if (confirm('Supprimer tous les tickets enregistrés sur cet appareil ?')) {
      TicketStore.clear();
      this.render();
    }
  },
  render() {
    const holder = document.getElementById('tickets-list');
    const items = TicketStore.all();
    if (!items.length) {
      holder.innerHTML = `<div class="t-muted">Aucun ticket enregistré pour le moment.</div>`;
      return;
    }
    holder.innerHTML = '';
    items.forEach((t) => {
      const el = document.createElement('div');
      el.className = 'ticket-item';
      const saved = new Date(t.savedAt || Date.now()).toLocaleString();
      el.innerHTML = `
        <div><strong>${t.planName || 'Ticket'}</strong><div class="kv">Acheté le ${saved}</div></div>
        <div class="kv">Validité: <strong>${t.validityText || '-'}</strong><br>Montant: <strong>${(t.amount||'') && t.amount.toLocaleString ? t.amount.toLocaleString() : (t.amount||'-')} F</strong></div>
        <div>
          <div>👤 <span class="cred">${t.username}</span></div>
          <div>🔑 <span class="cred">${t.password}</span></div>
          <div class="ticket-actions">
            <button class="copy-btn" onclick="MyTickets.copyCreds('${t.username}','${t.password}')">Copier</button>
            <button class="use-ticket-btn" onclick="MyTickets.useTicket('${t.username}','${t.password}')">🚀 Utiliser ce ticket</button>
          </div>
        </div>
      `;
      holder.appendChild(el);
    });
  },
  copyCreds(u, p) {
    const text = `Utilisateur: ${u}\nMot de passe: ${p}`;
    navigator.clipboard?.writeText(text);
    alert('Identifiants copiés.');
  },
  // ✅ NOUVELLE FONCTION : Utiliser un ticket pour remplir le formulaire (AMÉLIORÉE)
useTicket(username, password) {
  try {
    console.log('🎫 Utilisation du ticket:', username);
    
    // Fermer le modal des tickets
    this.close();
    
    // ✅ NOUVEAU : Scroll vers le formulaire AVANT de remplir
    setTimeout(() => {
      scrollToLoginForm();
    }, 100); // Petit délai pour que le modal se ferme
    
    // Remplir les champs de connexion après le scroll
    setTimeout(() => {
      const usernameInput = document.getElementById('code-input');
      const passwordInput = document.getElementById('password-input');
      
      if (usernameInput && passwordInput) {
        usernameInput.value = username;
        passwordInput.value = password;
        
        // ✅ Mise en évidence améliorée
        highlightFilledFields(usernameInput, passwordInput);
        
        // Focus sur le champ username
        usernameInput.focus();
        usernameInput.select();
        
        // Afficher une notification de succès
        this._showTicketUsedNotification();
        
        console.log('✅ Ticket utilisé avec succès - champs remplis');
      } else {
        alert('❌ Formulaire de connexion non trouvé');
      }
    }, 500); // Délai pour permettre le scroll
    
  } catch (error) {
    console.error('❌ Erreur lors de l\'utilisation du ticket:', error);
    alert('❌ Erreur lors de l\'utilisation du ticket');
  }
},
  
// ✅ NOTIFICATION AMÉLIORÉE avec instructions
_showTicketUsedNotification() {
  const notification = document.createElement('div');
  notification.innerHTML = `
    <div style="display: flex; align-items: center; gap: 10px;">
      <span style="font-size: 24px;">✅</span>
      <div>
        <div style="font-weight: 600;">Ticket utilisé !</div>
        <div style="font-size: 14px; opacity: 0.9;">Formulaire rempli automatiquement ci-dessus</div>
      </div>
    </div>
  `;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
    color: white;
    padding: 15px 25px;
    border-radius: 12px;
    z-index: 10001;
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
    animation: slideDownBounce 0.5s ease-out;
    max-width: 300px;
    text-align: center;
  `;
  
  // ✅ Ajouter l'animation CSS si elle n'existe pas
  if (!document.querySelector('#enhanced-notification-style')) {
    const style = document.createElement('style');
    style.id = 'enhanced-notification-style';
    style.textContent = `
      @keyframes slideDownBounce {
        0% { 
          transform: translateX(-50%) translateY(-30px) scale(0.8); 
          opacity: 0; 
        }
        60% { 
          transform: translateX(-50%) translateY(5px) scale(1.05); 
          opacity: 1; 
        }
        100% { 
          transform: translateX(-50%) translateY(0) scale(1); 
          opacity: 1; 
        }
      }
    `;
    document.head.appendChild(style);
  }
  
  document.body.appendChild(notification);
  
  // ✅ Retirer la notification avec animation
  setTimeout(() => {
    notification.style.animation = 'slideDownBounce 0.3s ease-out reverse';
    setTimeout(() => notification.remove(), 300);
  }, 4000); // Affichage plus long pour laisser le temps de voir
}
};

// bouton d’ouverture
document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('btn-my-tickets');
  if (btn) btn.addEventListener('click', () => MyTickets.open());
});

// Dernier numéro mémorisé (pour préremplir)
const PhoneMemory = {
  KEY: 'dnet_last_phone',
  get() { try { return localStorage.getItem(this.KEY) || ''; } catch { return ''; } },
  set(v) { try { localStorage.setItem(this.KEY, v); } catch {} }
};

// Validation simple Cameroun: 9 chiffres commençant par 6
function isValidCMLocal(n) {
  return /^[6]\d{8}$/.test(n);
}

// ------ PaymentFlow ------
const PaymentFlow = {
  _interval: null,
  _interval: null,
  _txId: null,
  _plan: null,
  _firestoreUnsubscribe: null,
  _countdownInterval: null,
  _currentStep: 1,

 _resetAll() {
    console.log('🧹 Nettoyage complet des variables PaymentFlow');
    
    // Arrêter tous les timers et intervalles
    this._stop();
    
    // Réinitialiser toutes les variables
    this._interval = null;
    this._txId = null;
    this._plan = null;
    this._firestoreUnsubscribe = null;
    this._countdownInterval = null;
    this._currentStep = 1;
    
    // Nettoyer l'interface
    this._resetUI();
    
    console.log('✅ Variables PaymentFlow réinitialisées');
  },

   _resetUI() {
    // Réinitialiser les étapes
    document.querySelectorAll('#pay-steps li').forEach(li => {
      li.classList.remove('active');
    });
    document.querySelector('#pay-steps li[data-step="1"]')?.classList.add('active');
    
    // Réinitialiser le bouton
    const startButton = document.getElementById('btn-start-payment');
    if (startButton) {
      startButton.disabled = true;
      startButton.onclick = null;
    }
    
    // Vider tous les contenus des stages
    ['stage-init', 'stage-pending', 'stage-success', 'stage-failed'].forEach(stageId => {
      const stage = document.getElementById(stageId);
      if (stage) {
        stage.style.display = 'none';
        stage.innerHTML = '';
      }
    });
    
    // Réinitialiser les contenus par défaut
    this._setDefaultContent();
  },



  _setDefaultContent() {
    // Contenu par défaut pour stage-init
    const stageInit = document.getElementById('stage-init');
    if (stageInit) {
      stageInit.innerHTML = `
        <div class="spinner"></div>
        <p>Connexion au service de paiement…</p>
      `;
    }
    
    // Contenu par défaut pour stage-pending
    const stagePending = document.getElementById('stage-pending');
    if (stagePending) {
      stagePending.innerHTML = `
        <div class="spinner"></div>
        <button class="link-button" id="btn-resend-check">Rafraîchir l'état</button>
      `;
    }
    
    // Contenu par défaut pour stage-success
    const stageSuccess = document.getElementById('stage-success');
    if (stageSuccess) {
      stageSuccess.innerHTML = `
        <div class="big-icon">🎉</div>
        <h4>Paiement validé</h4>
        <p>Voici vos identifiants Wi-Fi :</p>
        <div class="credentials">
          <div class="credential-item">
            <label>Nom d'utilisateur :</label>
            <span class="credential-value" id="cred-username">—</span>
          </div>
          <div class="credential-item">
            <label>Mot de passe :</label>
            <span class="credential-value" id="cred-password">—</span>
          </div>
        </div>
        <div class="auto-connect-section">
          <button onclick="autoConnectFromCredentials()" class="auto-connect-button">
            🚀 Se connecter automatiquement
          </button>
        </div>
        <button class="close-button" onclick="PaymentFlow.close()">Fermer</button>
      `;
    }
    
    // Contenu par défaut pour stage-failed
    const stageFailed = document.getElementById('stage-failed');
    if (stageFailed) {
      stageFailed.innerHTML = `
        <div class="big-icon error">❌</div>
        <h4>Le paiement a échoué</h4>
        <p id="fail-reason">Une erreur est survenue.</p>
        <button class="retry-button" onclick="PaymentFlow.close()">Fermer</button>
      `;
    }
  },


open(plan, prefillPhone = '') {
    console.log('🚀 Ouverture PaymentFlow - Nettoyage préalable');
    
    // ✅ NETTOYAGE COMPLET AVANT OUVERTURE
    this._resetAll();
    
    // Initialiser avec le nouveau plan
    this._plan = plan;
    this._currentStep = 1;
    
    // Mettre à jour l'interface
    document.getElementById('modal-plan-title').textContent = `💰 Paiement — ${plan.name}`;
    document.getElementById('sum-name').textContent = plan.name;
    document.getElementById('sum-price').textContent = plan.formattedPrice || `${plan.price?.toLocaleString?.() || plan.price} F`;
    
    // Réinitialiser à l'étape 1
    this.setStep(1);
    document.getElementById('phone-capture').style.display = 'block';
    this.showStage(null);
    
    // Configurer le champ téléphone
    const input = document.getElementById('pay-phone');
    const last = prefillPhone || PhoneMemory.get();
    input.value = (last || '').replace(/\D/g, '').slice(-9);
    this._currentPhone = input.value;
    
    // Configurer les événements
    this._toggleStartButton();
    input.oninput = () => {
      this._currentPhone = input.value;
      this._toggleStartButton();
    };
    document.getElementById('btn-start-payment').onclick = () => this._proceedFromPhone();
    
    // Ouvrir le modal
    const modal = document.getElementById('payment-modal');
    modal.style.display = 'flex';
    modal.setAttribute('aria-hidden', 'false');
    
    setTimeout(() => input.focus(), 50);
    
    console.log('✅ PaymentFlow ouvert et configuré', {
      plan: plan.name,
      step: this._currentStep,
      phone: this._currentPhone
    });
  },
close() {
  console.log('🔽 Fermeture PaymentFlow - Début du nettoyage');
  
  // Récupérer les identifiants avant nettoyage (fonctionnalité existante)
  const usernameElement = document.getElementById('cred-username');
  const passwordElement = document.getElementById('cred-password');
  
  let credentialsFound = false;
  
  if (usernameElement && passwordElement) {
    const username = usernameElement.textContent.trim();
    const password = passwordElement.textContent.trim();
    
    if (username && password && username !== '—' && password !== '—') {
      console.log('✅ Identifiants trouvés lors de la fermeture');
      
      // ✅ NOUVEAU : Scroll vers le formulaire
      setTimeout(() => {
        scrollToLoginForm();
      }, 200);
      
      // Préremplir les champs de connexion après le scroll
      setTimeout(() => {
        const usernameInput = document.getElementById('code-input');
        const passwordInput = document.getElementById('password-input');
        
        if (usernameInput && passwordInput) {
          usernameInput.value = username;
          passwordInput.value = password;
          
          // ✅ Mise en évidence améliorée
          highlightFilledFields(usernameInput, passwordInput);
          
          // Focus pour attirer l'attention
          usernameInput.focus();
          usernameInput.select();
          
          credentialsFound = true;
          this._showAutoFillNotification();
        }
      }, 700); // Délai pour permettre le scroll
    }
  }
  
  // Fermer le modal
  const modal = document.getElementById('payment-modal');
  modal.style.display = 'none';
  modal.setAttribute('aria-hidden', 'true');
  
  // ✅ NETTOYAGE COMPLET APRÈS FERMETURE
  setTimeout(() => {
    this._resetAll();
  }, 100);
  
  console.log(credentialsFound ? 
    '🎯 Fermeture avec remplissage automatique + scroll' : 
    '🔽 Fermeture simple'
  );
},

// ✅ NOUVELLE MÉTHODE : Notification d'auto-remplissage
_showAutoFillNotification() {
  // Supprimer notification existante
  const existingNotification = document.querySelector('.autofill-notification');
  if (existingNotification) {
    existingNotification.remove();
  }
  
  const notification = document.createElement('div');
  notification.className = 'autofill-notification';
  notification.innerHTML = `
    <div class="notification-content">
      <span class="notification-icon">✅</span>
      <div class="notification-text">
        <strong>Identifiants récupérés !</strong>
        <small>Les champs ont été préremplis automatiquement</small>
      </div>
      <button class="notification-close" onclick="this.parentElement.parentElement.remove()">×</button>
    </div>
  `;
  
  document.body.appendChild(notification);
  
  // Supprimer automatiquement après 5 secondes
  setTimeout(() => {
    if (notification.parentNode) {
      notification.remove();
    }
  }, 5000);
},

  setStep(n) {
    this._currentStep = n;
    document.querySelectorAll('#pay-steps li').forEach(li => {
      li.classList.toggle('active', Number(li.dataset.step) === n);
    });
    console.log(`📍 Étape changée: ${n}`);
  },

  showStage(id) {
    ['stage-init', 'stage-pending', 'stage-success', 'stage-failed'].forEach(s => {
      const el = document.getElementById(s);
      if (el) el.style.display = (id && s === id) ? 'block' : 'none';
    });
  },

  _toggleStartButton() {
    const ok = isValidCMLocal(document.getElementById('pay-phone').value.trim());
    document.getElementById('btn-start-payment').disabled = !ok;
  },

  async _proceedFromPhone() {
    const local9 = document.getElementById('pay-phone').value.trim();
    if (!isValidCMLocal(local9)) return;
    
    const full = `237${local9}`;
    this._currentPhone = full;
    PhoneMemory.set(local9);
    
    this.setStep(2);
    this._currentStep = 2;
    document.getElementById('phone-capture').style.display = 'none';
    this.showStage('stage-init');
    
    await this._init(full);
  },

// Dans ticket.js - Modifier _init()
async _init(fullPhone) {
  try {
    // ✅ NOUVEAU : Message convivial pendant l'initiation
    this.showStage('stage-init');
    this._updateInitMessage("🚀 Préparation de votre commande...", "Nous réservons votre forfait et préparons le paiement.<br>Plus que quelques secondes ! ⏳");
    
    const result = await firebaseIntegration.initiatePayment(this._plan.id, fullPhone);
    
    if (!result || !result.success) {
      throw new Error(result?.error || 'Échec de l\'initiation');
    }
    
    this._txId = result.transactionId;
    this._showPaymentSuccess(result);
    this._start();
    
  } catch (e) {
    console.error(e);
    this._showInitError(e.message);
  }
},

// ✅ NOUVELLE MÉTHODE : Mise à jour des messages d'init
_updateInitMessage(title, subtitle) {
  document.getElementById('stage-init').innerHTML = `
    <div class="spinner"></div>
    <h4>${title}</h4>
    <p>${subtitle}</p>
  `;
},

// ✅ NOUVELLE MÉTHODE : Succès d'initiation
_showPaymentSuccess(result) {
  this.setStep(2);
  this.showStage('stage-pending');
document.getElementById('stage-pending').innerHTML = `
  <h4>Validez le paiement du ticket</h4>
  

<div class="payment-instructions">
  <p>
    1️⃣ <strong>Entrez votre code</strong><br>
    2️⃣ Attendez quelques secondes<br>
    3️⃣ Nous verifions le statut de la transaction <span class="loader-inline"></span>
  </p>
</div>
  
  <div class="payment-timing">
    <div class="timing-info">
      <div class="timing-text">
        <strong>Vous avez 2 minutes pour confirmer</strong>
        <p>Aucun débit ne sera effectué sans votre confirmation&nbsp;!</p>
      </div>
    </div>
  </div>

  <div class="transaction-status">
    <div class="status-timer">
      <span id="countdown-timer">2:00</span>
    </div>
  </div>
  
  <button class="link-button" id="btn-resend-check" onclick="PaymentFlow._tick()">🔍 Vérifier maintenant</button>
`;

  // Démarrer le compte à rebours
  this._startPaymentCountdown();
},

// ✅ NOUVELLE MÉTHODE : Erreur d'initiation
_showInitError(errorMessage) {
  this.setStep(1);
  this.showStage('stage-failed');
  
  document.getElementById('stage-failed').innerHTML = `
    <div class="big-icon error">😅</div>
    <h4>Une petite pause technique !</h4>
    <p>Nous n'avons pas pu préparer votre commande.</p>
    
    <div class="error-explanation">
      <p><strong>Message d'erreur :</strong> ${errorMessage}</p>
    </div>
    
    <div class="failure-reasons">
      <h5>💡 Quelques suggestions :</h5>
      <ul>
        <li>Vérifiez votre connexion internet</li>
        <li>Réessayez dans 30 secondes</li>
        <li>Ce forfait est peut-être épuisé</li>
      </ul>
    </div>
    
    <div class="action-buttons">
      <button onclick="location.reload()" class="retry-button primary">🔄 Pas de souci, réessayons ensemble !</button>
      <button onclick="PaymentFlow.close()" class="secondary-button">Plus tard</button>
    </div>
  `;
},
  // Dans l'objet PaymentFlow, remplacer ces méthodes :

// Dans ticket.js - Ajouter la méthode de compte à rebours
_startPaymentCountdown() {
  const PAYMENT_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes
  const startTime = Date.now();
  
  const updateCountdown = () => {
    const elapsed = Date.now() - startTime;
    const remaining = Math.max(0, PAYMENT_TIMEOUT_MS - elapsed);
    
    if (remaining <= 0) {
      this._handlePaymentTimeout();
      return;
    }
    
    const minutes = Math.floor(remaining / 60000);
    const seconds = Math.floor((remaining % 60000) / 1000);
    const timeString = `${minutes}:${seconds.toString().padStart(2, '0')}`;
    
    const timerElement = document.getElementById('countdown-timer');
    // const statusElement = document.getElementById('status-text');
    
    if (timerElement) {
      timerElement.textContent = timeString;
      
      // Changer la couleur selon le temps restant
      if (remaining <= 30000) {
        timerElement.style.color = '#ff4444';
        timerElement.style.fontWeight = 'bold';
      } else if (remaining <= 60000) {
        timerElement.style.color = '#ff8800';
      }
    }
    
    // // ✅ MESSAGES PROGRESSIFS CONVIVIAUX
    // if (statusElement) {
    //   if (remaining > 90000) { // Plus de 1m30
    //     statusElement.innerHTML = "📱 En attente de votre confirmation";
    //   } else if (remaining > 60000) { // Plus de 1 minute
    //     statusElement.innerHTML = "⏰ Temps restant: plus d'une minute<br>💡 Vérifiez les notifications sur votre téléphone";
    //   } else if (remaining > 30000) { // Plus de 30s
    //     statusElement.innerHTML = "🚨 Plus que quelques secondes !<br>👆 Regardez vos notifications Mobile Money maintenant !";
    //     statusElement.style.color = '#ff8800';
    //   } else { // Moins de 30s
    //     statusElement.innerHTML = "⚡ Presque fini ! Plus que quelques secondes<br>🚨 Confirmez rapidement pour ne pas perdre votre réservation";
    //     statusElement.style.color = '#ff4444';
    //   }
    // }
  };
  
  updateCountdown();
  this._countdownInterval = setInterval(updateCountdown, 1000);
},

// ✅ NOUVELLE MÉTHODE : Gestion du timeout
_handlePaymentTimeout() {
  if (this._countdownInterval) {
    clearInterval(this._countdownInterval);
    this._countdownInterval = null;
  }
  
  this.showStage('stage-failed');
  document.getElementById('stage-failed').innerHTML = `
    <div class="big-icon error">⏰</div>
    <h4>Temps écoulé, mais pas de panique !</h4>
    
    <div class="timeout-explanation">
      <p><strong>Votre réservation a expiré après 2 minutes d'attente.</strong></p>
      <p>Bonne nouvelle : aucun débit n'a eu lieu sur votre compte ! 😊</p>
    </div>
    
    <div class="next-steps">
      <h5>🔄 Que faire maintenant ?</h5>
      <div class="step-list">
        <div class="step-item">
          <span class="step-number">1</span>
          <span>Recommencez simplement votre commande</span>
        </div>
        <div class="step-item">
          <span class="step-number">2</span>
          <span>Vérifiez que votre Mobile Money fonctionne</span>
        </div>
        <div class="step-item">
          <span class="step-number">3</span>
          <span>Soyez plus rapide pour confirmer (vous avez 2 minutes)</span>
        </div>
      </div>
    </div>
    
    <div class="support-info">
      <p><strong>💡 Astuce :</strong> Gardez votre téléphone à portée de main !</p>
      <p>📞 Besoin d'aide ? Appelez-nous : +237 6 94 22 15 06</p>
      <p>💬 Ou écrivez-nous sur <a href="https://wa.me/237694221506" target="_blank">WhatsApp</a></p>
    </div>
    
    <div class="timeout-actions">
      <button onclick="location.reload()" class="retry-button primary">🔄 Recommencer</button>
      <button onclick="PaymentFlow.close()" class="secondary-button">❌ Annuler</button>
    </div>
  `;
  
  this._stop();
},

_start() {
  const onUpdate = (transactionData) => {
    try {
      const tx = transactionData;
      
      if (tx.status === 'completed' && tx.credentials) {
        // ✅ SUCCÈS CONVIVIAL
        this.setStep(3);
        this.showStage('stage-success');
        
        document.getElementById('stage-success').innerHTML = `
          <h4>Voici vos codes d'accès WiFi </h4>
          
          <div class="credentials">
            <div class="credential-item">
              <label>🆔 Votre identifiant:</label>
              <span class="credential-value" id="cred-username">${tx.credentials.username}</span>
            </div>
            <div class="credential-item">
              <label>🔐 Votre mot de passe:</label>
              <span class="credential-value" id="cred-password">${tx.credentials.password}</span>
            </div>
          </div>

          <div class="auto-connect-section">
            <button onclick="autoConnectFromCredentials()" class="auto-connect-button">
              🚀 Me connecter maintenant
            </button>
          </div>
          
          <button class="close-button" onclick="PaymentFlow.close()">📋 Garder pour plus tard</button>
        `;
        
        // Sauvegarder le ticket
        TicketStore.add({
          username: tx.credentials.username,
          password: tx.credentials.password,
          planName: this._plan.name,
          amount: tx.amount,
          validityText: tx.ticketTypeName || this._plan.validityText || '',
          freemopayReference: tx.freemopayReference || null
        });
        
        this._stop();
        return;
      }

      if (tx.status === 'failed' || tx.status === 'expired') {
        // ✅ ÉCHEC CONVIVIAL
        this.showStage('stage-failed');
        
        document.getElementById('stage-failed').innerHTML = `
          <div class="big-icon error">😔</div>
          <h4>Votre paiement n'a pas abouti</h4>
          
          <p>Ne vous inquiétez pas, votre argent est en sécurité ! 💳</p>
          
          <div class="failure-reasons">
            <h5>🤔 Pourquoi ça n'a pas marché ?</h5>
            <ul>
              <li>Vous avez peut-être refusé sur votre téléphone</li>
              <li>Solde insuffisant sur votre compte Mobile Money</li>
              <li>Petit problème technique temporaire</li>
              <li>Confirmation trop tardive (plus de 2 minutes)</li>
            </ul>
          </div>
          
          <div class="failure-actions">
            <h5>✨ Solutions simples :</h5>
            <ul>
              <li>Vérifiez votre solde Mobile Money</li>
              <li>Réessayez en confirmant plus rapidement</li>
              <li>Contactez-nous si ça persiste</li>
            </ul>
          </div>
          
          <div class="action-buttons">
            <button onclick="location.reload()" class="retry-button primary">🔄 Retenter ma chance</button>
            <button onclick="PaymentFlow.close()" class="secondary-button">❌ Peut-être plus tard</button>
          </div>
          
          <div class="support-contact">
            <p><strong>🆘 Une question ? On est là !</strong></p>
            <p>📞 +237 6 94 22 15 06 | 💬 <a href="https://wa.me/237694221506" target="_blank">WhatsApp</a></p>
          </div>
        `;
        
        this._stop();
        return;
      }

      // Mettre à jour le statut intermédiaire
      const statusMap = {
        'created': '🎬 Démarrage... Votre commande démarre, on prépare tout !',
        'pending': '📱 En attente de votre accord - Votre opérateur vous demande confirmation',
        'processing': '⚙️ Validation en cours... Votre paiement est en cours de traitement'
      };
      
      // const statusText = statusMap[tx.status] || `Statut: ${tx.status}`;
      // document.getElementById('live-status').textContent = `${statusText} • Dernière mise à jour: ${new Date().toLocaleTimeString()}`;

    } catch (error) {
      console.error('Erreur traitement mise à jour ticket:', error);
      this._handleError('Erreur de traitement');
    }
  };

  const onError = (error) => {
    console.error('Erreur surveillance Firestore ticket:', error);
    // Basculer vers polling de secours
    this._startPollingFallback();
  };

  // Démarrer l'écoute Firestore
  this._firestoreUnsubscribe = firebaseIntegration.listenToTransaction(
    this._txId,
    onUpdate,
    onError
  );
},
  // ✅ MÉTHODE MODIFIÉE : Stop améliorée
  _stop() {
    console.log('⏹️ Arrêt de tous les processus PaymentFlow');
    
    // Arrêter l'écoute Firestore
    if (this._firestoreUnsubscribe) {
      try {
        this._firestoreUnsubscribe();
        console.log('✅ Firestore listener arrêté');
      } catch (error) {
        console.warn('⚠️ Erreur lors de l\'arrêt Firestore:', error);
      }
      this._firestoreUnsubscribe = null;
    }
    
    // Arrêter le polling de fallback
    if (this._interval) {
      clearInterval(this._interval);
      this._interval = null;
      console.log('✅ Polling interval arrêté');
    }
    
    // Arrêter le compte à rebours
    if (this._countdownInterval) {
      clearInterval(this._countdownInterval);
      this._countdownInterval = null;
      console.log('✅ Countdown interval arrêté');
    }
    
    // Nettoyer les événements globaux
    this._removeGlobalEventListeners();
  },

  // ✅ NOUVELLE MÉTHODE : Nettoyage des événements globaux
  _removeGlobalEventListeners() {
    // Nettoyer les onclick des boutons dynamiques
    const buttons = [
      'btn-start-payment',
      'btn-resend-check'
    ];
    
    buttons.forEach(buttonId => {
      const button = document.getElementById(buttonId);
      if (button) {
        button.onclick = null;
      }
    });
    
    // Nettoyer les oninput
    const inputs = ['pay-phone'];
    inputs.forEach(inputId => {
      const input = document.getElementById(inputId);
      if (input) {
        input.oninput = null;
      }
    });
  },

// Nouvelle méthode de fallback
_startPollingFallback() {
  console.log('🔄 Basculement vers polling pour ticket');
  this._interval = setInterval(() => this._tick(), CONFIG.ui?.transactionCheckInterval || 4000);
},


getStatusText(status) {
  const statusMap = {
    'created': 'Créée',
    'pending': 'En attente',
    'processing': 'En cours',
    'completed': 'Terminée',
    'failed': 'Échouée',
    'expired': 'Expirée'
  };
  return statusMap[status] || status;
},

_handleError(message) {
  this.showStage('stage-failed');
  document.getElementById('fail-reason').textContent = message;
  this._stop();
},

async _tick() {
  if (!this._txId) {
    console.warn('🚫 Pas de transaction ID - arrêt du monitoring');
    this._stop();
    return;
  }
  
  try {
    const res = await firebaseIntegration.checkTransactionStatus(this._txId);
    if (!res?.success) {
      console.warn('⚠️ Réponse invalide du serveur');
      return;
    }
    
    const tx = res.transaction || {};
    console.log(`🔍 Statut transaction: ${tx.status}`);
    
    // ✅ SÉCURITÉ : Validation stricte pour affichage des credentials
    if (tx.status === 'completed' && 
        tx.credentials && 
        tx.credentials.username && 
        tx.credentials.password &&
        tx.credentials.username.trim() !== '' &&
        tx.credentials.password.trim() !== '') {
      
      console.log('✅ Paiement confirmé - affichage des credentials');
      this.setStep(3);
      this.showStage('stage-success');
      
      // ✅ Affichage sécurisé dans l'interface
      const usernameEl = document.getElementById('cred-username');
      const passwordEl = document.getElementById('cred-password');
      
      if (usernameEl && passwordEl) {
        usernameEl.textContent = tx.credentials.username;
        passwordEl.textContent = tx.credentials.password;
        
        // ✅ Sauvegarder UNIQUEMENT si paiement réellement réussi
        TicketStore.add({
          username: tx.credentials.username,
          password: tx.credentials.password,
          planName: tx.planName || this._plan?.name || 'Forfait',
          amount: tx.amount,
          validityText: tx.ticketTypeName || this._plan?.validityText || '',
          freemopayReference: tx.freemopayReference || null,
          purchaseDate: new Date().toISOString(),
          transactionId: this._txId
        });
        
        console.log('✅ Ticket sauvegardé localement');
      }
      
      this._stop();
      return;
    }
    
    // ✅ Gestion des échecs avec nettoyage
    if (tx.status === 'failed' || tx.status === 'expired') {
      console.log(`❌ Paiement échoué: ${tx.status}`);
      this.showStage('stage-failed');
      
      const failReasonEl = document.getElementById('fail-reason');
      if (failReasonEl) {
        const messages = {
          'failed': 'Le paiement a échoué. Votre argent est sécurisé.',
          'expired': 'Le délai de paiement a expiré. Veuillez réessayer.'
        };
        failReasonEl.textContent = messages[tx.status] || 'Une erreur est survenue.';
      }
      
      this._stop();
      return;
    }
    
    // ✅ Status en attente - mise à jour de l'interface
    if (tx.status === 'pending' || tx.status === 'created') {
      const statusEl = document.getElementById('live-status');
      if (statusEl) {
        const statusMessages = {
          'created': 'Transaction initiée...',
          'pending': 'En attente de confirmation...'
        };
        statusEl.textContent = statusMessages[tx.status] || 'Vérification en cours...';
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error);
    // ✅ Ne pas arrêter automatiquement en cas d'erreur réseau temporaire
  }
}


};
