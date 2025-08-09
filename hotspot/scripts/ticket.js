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
          <button class="copy-btn" onclick="MyTickets.copyCreds('${t.username}','${t.password}')">Copier</button>
        </div>
      `;
      holder.appendChild(el);
    });
  },
  copyCreds(u, p) {
    const text = `Utilisateur: ${u}\nMot de passe: ${p}`;
    navigator.clipboard?.writeText(text);
    alert('Identifiants copiés.');
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
  _txId: null,
  _plan: null,

  open(plan, prefillPhone = '') {
    this._plan = plan;
    document.getElementById('modal-plan-title').textContent = `Paiement — ${plan.name}`;
    document.getElementById('sum-name').textContent = plan.name;
    document.getElementById('sum-price').textContent = plan.formattedPrice || `${plan.price?.toLocaleString?.() || plan.price} F`;
    this.setStep(1);
    document.getElementById('phone-capture').style.display = 'block';
    this.showStage(null);
    const input = document.getElementById('pay-phone');
    const last = prefillPhone || PhoneMemory.get();
    input.value = (last || '').replace(/\D/g, '').slice(-9);
    this._toggleStartButton();
    input.oninput = () => this._toggleStartButton();
    document.getElementById('btn-start-payment').onclick = () => this._proceedFromPhone();
    const modal = document.getElementById('payment-modal');
    modal.style.display = 'flex';
    modal.setAttribute('aria-hidden', 'false');
    setTimeout(() => input.focus(), 50);
  },

  close() {
    const modal = document.getElementById('payment-modal');
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
    this._stop();
    this._plan = null;
  },

  setStep(n) {
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
    PhoneMemory.set(local9);
    this.setStep(2);
    document.getElementById('phone-capture').style.display = 'none';
    this.showStage('stage-init');
    await this._init(full);
  },

  async _init(fullPhone) {
    try {
      const result = await firebaseIntegration.initiatePayment(this._plan.id, fullPhone);
      if (!result || !result.success) throw new Error(result?.error || 'Échec de l’initiation');
      this._txId = result.transactionId;
      this.showStage('stage-pending');
      document.getElementById('live-status').textContent =
        `Référence: ${result.freemopayReference || '—'} • Montant: ${result.amount?.toLocaleString?.() || result.amount} F`;
      this._start();
      document.getElementById('btn-resend-check').onclick = () => this._tick();
    } catch (e) {
      console.error(e);
      this.setStep(1);
      this.showStage('stage-failed');
      document.getElementById('fail-reason').textContent = e.message || 'Impossible de démarrer le paiement.';
    }
  },

  // Dans l'objet PaymentFlow, remplacer ces méthodes :

_start() {
  console.log('🚀 Démarrage surveillance Firestore pour ticket');
  
  const onUpdate = (transactionData) => {
    try {
      const tx = transactionData;
      
      if (tx.status === 'completed' && tx.credentials) {
        this.setStep(3);
        this.showStage('stage-success');
        document.getElementById('cred-username').textContent = tx.credentials.username;
        document.getElementById('cred-password').textContent = tx.credentials.password;
        
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
        document.getElementById('fail-reason').textContent =
          'Le paiement a été annulé ou a échoué. Veuillez réessayer.';
        this._stop();
        return;
      }

      // Mettre à jour le statut live
      document.getElementById('live-status').textContent =
        `Statut: ${this.getStatusText(tx.status)} • Dernière mise à jour: ${new Date().toLocaleTimeString()}`;

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

_stop() {
  if (this._firestoreUnsubscribe) {
    this._firestoreUnsubscribe();
    this._firestoreUnsubscribe = null;
  }
  
  if (this._interval) {
    clearInterval(this._interval);
    this._interval = null;
  }
  
  this._txId = null;
},

// Nouvelle méthode de fallback
_startPollingFallback() {
  console.log('🔄 Basculement vers polling pour ticket');
  this._interval = setInterval(() => this._tick(), CONFIG.ui?.transactionCheckInterval || 4000);
},

// Garder l'ancienne méthode _tick comme fallback
async _tick() {
  if (!this._txId) return;
  try {
    const res = await firebaseIntegration.checkTransactionStatus(this._txId);
    if (!res?.success) return;
    
    const tx = res.transaction || {};
    if (tx.status === 'completed' && tx.credentials) {
      this.setStep(3);
      this.showStage('stage-success');
      document.getElementById('cred-username').textContent = tx.credentials.username;
      document.getElementById('cred-password').textContent = tx.credentials.password;
      
      TicketStore.add({
        username: tx.credentials.username,
        password: tx.credentials.password,
        planName: this._plan.name,
        amount: tx.amount,
        validityText: tx.ticketTypeName || this._plan.validityText || '',
        freemopayReference: tx.freemopayReference || null
      });
      
      this._stop();
    } else if (tx.status === 'failed' || tx.status === 'expired') {
      this.showStage('stage-failed');
      document.getElementById('fail-reason').textContent =
        'Le paiement a été annulé ou a échoué. Veuillez réessayer.';
      this._stop();
    } else {
      document.getElementById('live-status').textContent =
        `Statut: ${tx.status || 'pending'} • Dernière mise à jour: ${tx.updatedAt || '—'}`;
    }
  } catch (e) {
    console.warn('tick error fallback', e.message);
  }
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
    if (!this._txId) return;
    try {
      const res = await firebaseIntegration.checkTransactionStatus(this._txId);
      if (!res?.success) return;
      const tx = res.transaction || {};
      if (tx.status === 'completed' && tx.credentials) {
        this.setStep(3);
        this.showStage('stage-success');
        document.getElementById('cred-username').textContent = tx.credentials.username;
        document.getElementById('cred-password').textContent = tx.credentials.password;
        TicketStore.add({
          username: tx.credentials.username,
          password: tx.credentials.password,
          planName: this._plan.name,
          amount: tx.amount,
          validityText: tx.ticketTypeName || this._plan.validityText || '',
          freemopayReference: tx.freemopayReference || null
        });
        this._stop();
      } else if (tx.status === 'failed' || tx.status === 'expired') {
        this.showStage('stage-failed');
        document.getElementById('fail-reason').textContent =
          'Le paiement a été annulé ou a échoué. Veuillez réessayer.';
        this._stop();
      } else {
        document.getElementById('live-status').textContent =
          `Statut: ${tx.status || 'pending'} • Dernière mise à jour: ${tx.updatedAt || '—'}`;
      }
    } catch (e) {
      console.warn('tick error', e.message);
    }
  }
};
