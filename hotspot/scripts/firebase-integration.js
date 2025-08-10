class FirebaseIntegration {
  constructor() {
    this.functions = null;
    this.initialized = false;

    this.defaultTimeoutMs = (CONFIG?.network?.timeoutMs) || 10000;
    this.maxRetries = (CONFIG?.network?.maxRetries) || 4;
    this.baseBackoffMs = (CONFIG?.network?.baseBackoffMs) || 600;
    this.maxBackoffMs = (CONFIG?.network?.maxBackoffMs) || 5000;
  }

  async init() {
    try {
      if (this.initialized) return true;

      if (!CONFIG.firebase || !CONFIG.firebase.apiKey) {
        return false;
      }

      if (!firebase.apps || firebase.apps.length === 0) {
        firebase.initializeApp(CONFIG.firebase);
      }
      
      this.functions = firebase.functions();
      this.firestore = firebase.firestore();
      
      if (CONFIG.firestore && !CONFIG.firestore.realtimeOptions.enableLocalCache) {
        this.firestore.disableNetwork();
        await this.firestore.enableNetwork();
      }

      this.initialized = true;
      return true;
    } catch (error) {
      return false;
    }
  }

  listenToTransaction(transactionId, onUpdate, onError) {
    if (!this.firestore) {
      onError?.(new Error('Firestore non disponible'));
      return () => {};
    }

    const docRef = this.firestore
      .collection(CONFIG.firestore?.transactionsCollection || 'transactions')
      .doc(transactionId);

    const unsubscribe = docRef.onSnapshot(
      {
        source: 'server',
        includeMetadataChanges: false
      },
      (docSnapshot) => {
        try {
          if (!docSnapshot.exists) {
            onError?.(new Error('Transaction non trouvée'));
            return;
          }

          const transactionData = docSnapshot.data();
          onUpdate?.(transactionData);
          
        } catch (error) {
          onError?.(error);
        }
      },
      (error) => {
        if (error.code === 'permission-denied') {
          onError?.(new Error('Accès refusé à la transaction'));
          return;
        }
        
        if (error.code === 'unavailable') {
          return;
        }
        
        onError?.(error);
      }
    );

    const timeoutId = setTimeout(() => {
      unsubscribe();
      onError?.(new Error('Timeout de surveillance dépassé'));
    }, CONFIG.ui?.firestoreListenerTimeout || 300000);

    return () => {
      clearTimeout(timeoutId);
      unsubscribe();
    };
  }

  async _fetchWithRetry(url, options = {}, {
    timeoutMs = this.defaultTimeoutMs,
    maxRetries = this.maxRetries,
    baseBackoffMs = this.baseBackoffMs,
    maxBackoffMs = this.maxBackoffMs,
    retryOn = [429, 500, 502, 503, 504]
  } = {}) {
    let attempt = 0;
    let lastErr = null;

    while (attempt <= maxRetries) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      try {
        const resp = await fetch(url, { ...options, signal: controller.signal });

        if (resp.ok) {
          clearTimeout(timer);
          return resp;
        }

        if (retryOn.includes(resp.status)) {
          const retryAfter = resp.headers?.get?.('retry-after');
          const retryAfterMs = retryAfter ? (parseFloat(retryAfter) * 1000) : null;

          clearTimeout(timer);
          if (attempt === maxRetries) {
            let msg = `HTTP ${resp.status}`;
            try { const data = await resp.json(); msg = data.error || msg; } catch {}
            throw new Error(msg);
          }

          const delay = retryAfterMs ?? Math.min(
            maxBackoffMs,
            Math.floor(baseBackoffMs * Math.pow(1.7, attempt)) + Math.floor(Math.random() * 200)
          );
          await new Promise(r => setTimeout(r, delay));
          attempt++;
          continue;
        }

        clearTimeout(timer);
        let msg = `HTTP ${resp.status}: ${resp.statusText}`;
        try {
          const data = await resp.json();
          msg = data.error || msg;
        } catch {}
        throw new Error(msg);

      } catch (err) {
        clearTimeout(timer);
        lastErr = err;

        const isAbort = err?.name === 'AbortError';
        if (isAbort || err?.message?.includes('NetworkError') || err?.message?.includes('Failed to fetch')) {
          if (attempt === maxRetries) break;
          const delay = Math.min(
            maxBackoffMs,
            Math.floor(baseBackoffMs * Math.pow(1.7, attempt)) + Math.floor(Math.random() * 200)
          );
          await new Promise(r => setTimeout(r, delay));
          attempt++;
          continue;
        }
        throw err;
      }
    }

    throw lastErr || new Error('Échec réseau après retries');
  }

  async getPlans() {
    try {
      let url = `${CONFIG.api.cloudFunctionsUrl}${CONFIG.api.endpoints.getPlans}?zoneId=${encodeURIComponent(CONFIG.zone.id)}`;
      if (CONFIG.zone.publicKey) url += `&publicKey=${encodeURIComponent(CONFIG.zone.publicKey)}`;

      const resp = await this._fetchWithRetry(url, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });

      const data = await resp.json();

      if (data.success && Array.isArray(data.plans) && data.plans.length > 0) {
        return { success: true, plans: data.plans, zone: data.zone };
      }
      throw new Error(data.error || 'Aucun forfait disponible');
    } catch (error) {
      return { success: false, error: error.message, plans: CONFIG.fallbackPlans };
    }
  }

  genExternalId() {
    return `ext_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
  }

  async initiatePayment(ticketTypeId, phoneNumber) {
    const externalId = this.genExternalId();
    const url = `${CONFIG.api.cloudFunctionsUrl}/initiatePublicPayment`;

    const body = {
      planId: ticketTypeId,
      phoneNumber,
      externalId
    };

    const resp = await this._fetchWithRetry(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(body)
    });

    const data = await resp.json();
    return data;
  }

  async checkTransactionStatus(transactionId) {
    const url = `${CONFIG.api.cloudFunctionsUrl}/checkTransactionStatus?transactionId=${encodeURIComponent(transactionId)}`;

    const resp = await this._fetchWithRetry(url, {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    }, {
      timeoutMs: Math.min(this.defaultTimeoutMs, 6000),
      maxRetries: 2,
      baseBackoffMs: 400,
      maxBackoffMs: 2000
    });

    return await resp.json();
  }

  async testConnection() {
    try {
      const testUrl = `${CONFIG.api.cloudFunctionsUrl}/getPublicTicketTypes?zoneId=${encodeURIComponent(CONFIG.zone.id || 'healthcheck')}`;
      const resp = await this._fetchWithRetry(testUrl, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      }, { timeoutMs: 5000, maxRetries: 1 });

      return resp.status !== 404;
    } catch (error) {
      return false;
    }
  }
}

const firebaseIntegration = new FirebaseIntegration();