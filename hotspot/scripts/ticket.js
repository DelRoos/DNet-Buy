const TicketStore = {
  KEY: 'dnet_tickets',
  all() {
    try { 
      return JSON.parse(localStorage.getItem(this.KEY) || '[]'); 
    } catch { 
      return []; 
    }
  },
  add(ticket) {
    const list = this.all();
    list.unshift({ ...ticket, savedAt: Date.now() });
    localStorage.setItem(this.KEY, JSON.stringify(list.slice(0, 100)));
  },
  clear() { 
    localStorage.removeItem(this.KEY); 
  }
};

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
  
  useTicket(username, password) {
    try {
      this.close();
      
      setTimeout(() => {
        scrollToLoginForm();
      }, 100);
      
      setTimeout(() => {
        const usernameInput = document.getElementById('code-input');
        const passwordInput = document.getElementById('password-input');
        
        if (usernameInput && passwordInput) {
          usernameInput.value = username;
          passwordInput.value = password;
          
          highlightFilledFields(usernameInput, passwordInput);
          
          usernameInput.focus();
          usernameInput.select();
          
          this._showTicketUsedNotification();
        } else {
          alert('❌ Formulaire de connexion non trouvé');
        }
      }, 500);
      
    } catch (error) {
      alert('❌ Erreur lors de l\'utilisation du ticket');
    }
  },
  
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
    
    setTimeout(() => {
      notification.style.animation = 'slideDownBounce 0.3s ease-out reverse';
      setTimeout(() => notification.remove(), 300);
    }, 4000);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  const btn = document.getElementById('btn-my-tickets');
  if (btn) btn.addEventListener('click', () => MyTickets.open());
});

const PhoneMemory = {
  KEY: 'dnet_last_phone',
  get() { 
    try { 
      return localStorage.getItem(this.KEY) || ''; 
    } catch { 
      return ''; 
    } 
  },
  set(v) { 
    try { 
      localStorage.setItem(this.KEY, v); 
    } catch {} 
  }
};

function isValidCMLocal(n) {
  return /^[6]\d{8}$/.test(n);
}

const PaymentFlow = {
  _interval: null,
  _txId: null,
  _plan: null,
  _firestoreUnsubscribe: null,
  _countdownInterval: null,
  _currentStep: 1,

  _resetAll() {
    this._stop();
    this._interval = null;
    this._txId = null;
    this._plan = null;
    this._firestoreUnsubscribe = null;
    this._countdownInterval = null;
    this._currentStep = 1;
    this._resetUI();
  },

  _resetUI() {
    document.querySelectorAll('#pay-steps li').forEach(li => {
      li.classList.remove('active');
    });
    document.querySelector('#pay-steps li[data-step="1"]')?.classList.add('active');
    
    const startButton = document.getElementById('btn-start-payment');
    if (startButton) {
      startButton.disabled = true;
      startButton.onclick = null;
    }
    
    ['stage-init', 'stage-pending', 'stage-success', 'stage-failed'].forEach(stageId => {
      const stage = document.getElementById(stageId);
      if (stage) {
        stage.style.display = 'none';
        stage.innerHTML = '';
      }
    });
    
    this._setDefaultContent();
  },

  _setDefaultContent() {
    const stageInit = document.getElementById('stage-init');
    if (stageInit) {
      stageInit.innerHTML = `
        <div class="spinner"></div>
        <p>Connexion au service de paiement…</p>
      `;
    }
    
    const stagePending = document.getElementById('stage-pending');
    if (stagePending) {
      stagePending.innerHTML = `
        <div class="spinner"></div>
        <button class="link-button" id="btn-resend-check">Rafraîchir l'état</button>
      `;
    }
    
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
    this._resetAll();
    
    this._plan = plan;
    this._currentStep = 1;
    
    document.getElementById('modal-plan-title').textContent = `💰 Paiement — ${plan.name}`;
    document.getElementById('sum-name').textContent = plan.name;
    document.getElementById('sum-price').textContent = plan.formattedPrice || `${plan.price?.toLocaleString?.() || plan.price} F`;
    
    this.setStep(1);
    document.getElementById('phone-capture').style.display = 'block';
    this.showStage(null);
    
    const input = document.getElementById('pay-phone');
    const last = prefillPhone || PhoneMemory.get();
    input.value = (last || '').replace(/\D/g, '').slice(-9);
    this._currentPhone = input.value;
    
    this._toggleStartButton();
    input.oninput = () => {
      this._currentPhone = input.value;
      this._toggleStartButton();
    };
    document.getElementById('btn-start-payment').onclick = () => this._proceedFromPhone();
    
    const modal = document.getElementById('payment-modal');
    modal.style.display = 'flex';
    modal.setAttribute('aria-hidden', 'false');
    
    setTimeout(() => input.focus(), 50);
  },
  
  close() {
    const usernameElement = document.getElementById('cred-username');
    const passwordElement = document.getElementById('cred-password');
    
    let credentialsFound = false;
    
    if (usernameElement && passwordElement) {
      const username = usernameElement.textContent.trim();
      const password = passwordElement.textContent.trim();
      
      if (username && password && username !== '—' && password !== '—') {
        setTimeout(() => {
          scrollToLoginForm();
        }, 200);
        
        setTimeout(() => {
          const usernameInput = document.getElementById('code-input');
          const passwordInput = document.getElementById('password-input');
          
          if (usernameInput && passwordInput) {
            usernameInput.value = username;
            passwordInput.value = password;
            
            highlightFilledFields(usernameInput, passwordInput);
            
            usernameInput.focus();
            usernameInput.select();
            
            credentialsFound = true;
            this._showAutoFillNotification();
          }
        }, 700);
      }
    }
    
    const modal = document.getElementById('payment-modal');
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
    
    setTimeout(() => {
      this._resetAll();
    }, 100);
  },

  _showAutoFillNotification() {
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

  async _init(fullPhone) {
    try {
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
      this._showInitError(e.message);
    }
  },

  _updateInitMessage(title, subtitle) {
    document.getElementById('stage-init').innerHTML = `
      <div class="spinner"></div>
      <h4>${title}</h4>
      <p>${subtitle}</p>
    `;
  },

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

    this._startPaymentCountdown();
  },

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

  _startPaymentCountdown() {
    const PAYMENT_TIMEOUT_MS = 2 * 60 * 1000;
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
      
      if (timerElement) {
        timerElement.textContent = timeString;
        
        if (remaining <= 30000) {
          timerElement.style.color = '#ff4444';
          timerElement.style.fontWeight = 'bold';
        } else if (remaining <= 60000) {
          timerElement.style.color = '#ff8800';
        }
      }
    };
    
    updateCountdown();
    this._countdownInterval = setInterval(updateCountdown, 1000);
  },

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

        const statusMap = {
          'created': '🎬 Démarrage... Votre commande démarre, on prépare tout !',
          'pending': '📱 En attente de votre accord - Votre opérateur vous demande confirmation',
          'processing': '⚙️ Validation en cours... Votre paiement est en cours de traitement'
        };

      } catch (error) {
        this._handleError('Erreur de traitement');
      }
    };

    const onError = (error) => {
      this._startPollingFallback();
    };

    this._firestoreUnsubscribe = firebaseIntegration.listenToTransaction(
      this._txId,
      onUpdate,
      onError
    );
  },
  
  _stop() {
    if (this._firestoreUnsubscribe) {
      try {
        this._firestoreUnsubscribe();
      } catch (error) {
        // Ignore errors during cleanup
      }
      this._firestoreUnsubscribe = null;
    }
    
    if (this._interval) {
      clearInterval(this._interval);
      this._interval = null;
    }
    
    if (this._countdownInterval) {
      clearInterval(this._countdownInterval);
      this._countdownInterval = null;
    }
    
    this._removeGlobalEventListeners();
  },

  _removeGlobalEventListeners() {
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
    
    const inputs = ['pay-phone'];
    inputs.forEach(inputId => {
      const input = document.getElementById(inputId);
      if (input) {
        input.oninput = null;
      }
    });
  },

  _startPollingFallback() {
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
      this._stop();
      return;
    }
    
    try {
      const res = await firebaseIntegration.checkTransactionStatus(this._txId);
      if (!res?.success) {
        return;
      }
      
      const tx = res.transaction || {};
      
      if (tx.status === 'completed' && 
          tx.credentials && 
          tx.credentials.username && 
          tx.credentials.password &&
          tx.credentials.username.trim() !== '' &&
          tx.credentials.password.trim() !== '') {
        
        this.setStep(3);
        this.showStage('stage-success');
        
        const usernameEl = document.getElementById('cred-username');
        const passwordEl = document.getElementById('cred-password');
        
        if (usernameEl && passwordEl) {
          usernameEl.textContent = tx.credentials.username;
          passwordEl.textContent = tx.credentials.password;
          
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
        }
        
        this._stop();
        return;
      }
      
      if (tx.status === 'failed' || tx.status === 'expired') {
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
      // Continue polling on error
    }
  }
};