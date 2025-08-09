// portal.js - Version Optimisée pour la Performance

document.addEventListener('DOMContentLoaded', () => {

    // --- MÉTRIQUES DE PERFORMANCE ---
    const performanceMetrics = {
        startTime: Date.now(),
        logStep(step) {
            console.log(`⏱️ ${step}: ${Date.now() - this.startTime}ms`);
        }
    };
    performanceMetrics.logStep('DOM Loaded');

    // --- INITIALISATION FIREBASE OPTIMISÉE ---
    if (typeof firebase === 'undefined' || !firebase.initializeApp) {
        document.getElementById('view-content').innerHTML = `
            <div class="error-box">❌ Erreur critique : SDK Firebase non chargé. Vérifiez votre connexion.</div>
        `;
        return;
    }

    firebase.initializeApp(firebaseConfig);
    const db = firebase.firestore();
    const functions = firebase.functions();

    // Optimisations Firestore
    db.settings({
        cacheSizeBytes: firebase.firestore.CACHE_SIZE_UNLIMITED,
        ignoreUndefinedProperties: true
    });

    // Activer la persistance (cache local)
    db.enablePersistence({ synchronizeTabs: true })
        .then(() => console.log('✅ Cache Firestore activé'))
        .catch(err => console.log('⚠️ Cache non activé:', err));

    performanceMetrics.logStep('Firebase Initialized');

    // --- CACHE LOCAL POUR LES TYPES DE TICKETS ---
    const ticketTypeCache = new Map();

    const mainTitle = document.getElementById('main-title');
    const viewContent = document.getElementById('view-content');
    
    // --- ÉTAT DE L'APPLICATION OPTIMISÉ ---
    const state = {
        pageStatus: 'loading',
        ticketTypeDetails: null,
        finalTicket: null,
        errorMessage: '',
        transactionId: null,
        listeners: [],
        startTime: Date.now()
    };

    // --- ICÔNES SVG OPTIMISÉES (Plus petites) ---
    const icons = {
        success: `<svg class="status-icon success" width="48" height="48" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>`,
        error: `<svg class="status-icon error" width="48" height="48" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>`,
        warning: `<svg class="status-icon warning" width="48" height="48" viewBox="0 0 24 24" fill="currentColor"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>`,
        spinner: `<div class="spinner-optimized"></div>`
    };

    // --- FONCTIONS DE RENDU OPTIMISÉES (Sans transitions pour la vitesse) ---
    function renderLoadingView() {
        mainTitle.textContent = '⏳ Chargement';
        return `<div class="view">${icons.spinner}</div>`;
    }

    function renderInitialView() {
        const ticket = state.ticketTypeDetails;
        mainTitle.textContent = `📶 Forfait ${ticket.name}`;
        return `
            <div class="view">
                <div class="price-chip">💰 ${ticket.price} XAF</div>
                <p class="description">${ticket.description}</p>
                
                <div class="form-group">
                    <label for="phone-input">📱 Numéro (Orange/MTN)</label>
                    <input 
                        type="tel" 
                        id="phone-input" 
                        placeholder="699123456" 
                        autocomplete="tel" 
                        inputmode="numeric"
                        pattern="[6][0-9]{8}"
                        maxlength="9">
                </div>
                <button id="pay-button" class="btn" disabled>🔒 Payer et recevoir mon code</button>
                <small class="help-text">💡 Saisissez votre numéro sans le +237</small>
            </div>
        `;
    }

    function renderPendingView(message) {
        mainTitle.textContent = '⏳ Paiement en cours';
        return `
            <div class="view">
                ${icons.spinner}
                <h2>📲 ${message}</h2>
                <p class="description">Tapez *126# sur votre téléphone pour valider. Cette page se met à jour automatiquement.</p>
                <div class="progress-info">
                    <small>⏱️ Temps écoulé: <span id="timer">0</span>s</small>
                </div>
            </div>
        `;
    }

    function renderSuccessView() {
        mainTitle.textContent = '🎉 Paiement Réussi !';
        const ticket = state.finalTicket;
        return `
            <div class="view">
                ${icons.success}
                <h2>✅ Félicitations !</h2>
                <p class="description">Utilisez ces identifiants sur la page Wi-Fi de connexion.</p>
                <div class="credentials-card">
                    <div class="credential-row">
                        <span>👤 Utilisateur:</span>
                        <code>${ticket.username}</code>
                    </div>
                     <div class="credential-row">
                        <span>🔑 Mot de passe:</span>
                        <code>${ticket.password}</code>
                    </div>
                </div>
                <br>
                <button id="copy-button" class="btn">📋 Copier les Identifiants</button>
                <small class="help-text">💡 Connectez-vous au réseau Wi-Fi avec ces identifiants</small>
            </div>
        `;
    }

    function renderFailedView() {
        mainTitle.textContent = '❌ Échec du Paiement';
        return `
            <div class="view">
                ${icons.error}
                <h2>⚠️ Une erreur est survenue</h2>
                <div class="error-box">${state.errorMessage}</div>
                <br>
                <button id="retry-button" class="btn">🔄 Réessayer</button>
                <small class="help-text">💡 Vérifiez votre solde et votre réseau</small>
            </div>
        `;
    }
    
    function renderOutOfStockView() {
        mainTitle.textContent = '⚠️ Forfait Épuisé';
        return `
             <div class="view">
                ${icons.warning}
                <h2>😔 Désolé, stock épuisé</h2>
                <p class="description">Ce forfait est momentanément indisponible. Contactez le support.</p>
                <small class="help-text">📞 Support: +237 xxx xxx xxx</small>
             </div>
        `;
    }

    // --- FONCTION DE RENDU RAPIDE (Sans animation) ---
    function renderFast() {
        performanceMetrics.logStep(`Render ${state.pageStatus} start`);
        
        let html = '';
        switch (state.pageStatus) {
            case 'loading': html = renderLoadingView(); break;
            case 'idle': html = renderInitialView(); break;
            case 'checking': html = renderPendingView('Vérification...'); break;
            case 'pending': html = renderPendingView('Transaction initiée'); break;
            case 'fetchingCredentials': html = renderPendingView('Finalisation...'); break;
            case 'success': html = renderSuccessView(); break;
            case 'failed': html = renderFailedView(); break;
            case 'outOfStock': html = renderOutOfStockView(); break;
        }
        
        viewContent.innerHTML = html;
        attachEventListeners();
        
        performanceMetrics.logStep(`Render ${state.pageStatus} complete`);
    }

    // --- FONCTION DE RENDU AVEC TRANSITION (Pour UX importante) ---
    function renderWithTransition() {
        viewContent.style.opacity = '0';
        setTimeout(() => {
            renderFast();
            viewContent.style.opacity = '1';
        }, 150); // Réduit de 200ms à 150ms
    }

    // --- LOGIQUE MÉTIER OPTIMISÉE ---
    
    async function loadTicketTypeDetails(ticketTypeId) {
        performanceMetrics.logStep('Load ticket type start');
        
        try {
            // Vérifier le cache d'abord
            if (ticketTypeCache.has(ticketTypeId)) {
                console.log('✅ Ticket type from cache');
                state.ticketTypeDetails = ticketTypeCache.get(ticketTypeId);
                state.pageStatus = 'idle';
                renderFast();
                return;
            }

            const doc = await db.collection('ticket_types').doc(ticketTypeId).get();
            
            if (!doc.exists || !doc.data().isActive) {
                throw new Error("Forfait inactif ou introuvable.");
            }
            
            const ticketTypeData = { id: doc.id, ...doc.data() };
            
            // Mettre en cache
            ticketTypeCache.set(ticketTypeId, ticketTypeData);
            
            state.ticketTypeDetails = ticketTypeData;
            state.pageStatus = 'idle';
            
            performanceMetrics.logStep('Load ticket type complete');
        } catch (error) {
            console.error('❌ Erreur chargement ticket:', error);
            handleErrorFast("Ce forfait n'est pas accessible ou le lien est invalide.", error);
        }
        
        renderFast();
    }
    
    async function initiatePaymentOptimized() {
        const phoneInput = document.getElementById('phone-input');
        const phoneNumber = phoneInput.value.trim();
        
        performanceMetrics.logStep('Payment initiation start');
        
        // Feedback immédiat
        state.pageStatus = 'checking';
        renderFast();

        try {
            // Appel optimisé de la Cloud Function
            const initiatePublicPayment = functions.httpsCallable('initiatePublicPayment');
            const response = await initiatePublicPayment({
                ticketTypeId: state.ticketTypeDetails.id,
                phoneNumber: phoneNumber,
            });

            state.transactionId = response.data.transactionId;
            if (!state.transactionId) throw new Error("Réponse serveur invalide.");

            state.pageStatus = 'pending';
            performanceMetrics.logStep('Payment API call complete');
            
            listenForTransactionUpdatesOptimized(state.transactionId);
        } catch (error) {
            performanceMetrics.logStep('Payment error');
            
            // Gestion d'erreur optimisée
            switch (error.code) {
                case 'functions/out-of-range':
                    state.pageStatus = 'outOfStock';
                    break;
                case 'functions/invalid-argument':
                    handleErrorFast("Numéro de téléphone invalide. Utilisez le format: 6XXXXXXXX");
                    break;
                case 'functions/deadline-exceeded':
                    handleErrorFast("Délai d'attente dépassé. Vérifiez votre connexion et réessayez.");
                    break;
                default:
                    const userMessage = error.message || "Erreur de connexion. Réessayez.";
                    handleErrorFast(userMessage);
            }
        }
        
        renderFast();
    }

    function listenForTransactionUpdatesOptimized(transactionId) {
        clearListeners();
        performanceMetrics.logStep('Transaction listener setup');
        
        let startTime = Date.now();
        
        const unsubscribe = db.collection('transactions').doc(transactionId)
            .onSnapshot(async (doc) => {
                if (!doc.exists) return;
                const data = doc.data();
                
                console.log(`📊 Transaction update: ${data.status} (${Date.now() - startTime}ms)`);
                
                switch (data.status) {
                    case 'completed':
                        clearListeners();
                        await handleTransactionSuccess(data);
                        break;
                    case 'failed':
                        clearListeners();
                        handleTransactionFailure(data);
                        break;
                }
            }, (error) => {
                console.error('❌ Listener error:', error);
                handleErrorFast("Erreur de connexion. Vérifiez votre réseau.");
                renderFast();
            });

        // Timer visuel pour l'utilisateur
        let seconds = 0;
        const timer = setInterval(() => {
            seconds++;
            const timerElement = document.getElementById('timer');
            if (timerElement) {
                timerElement.textContent = seconds;
            }
        }, 1000);

        // Timeout réduit à 2 minutes
        const timeout = setTimeout(() => {
            if (state.pageStatus === 'pending' || state.pageStatus === 'checking') {
                clearListeners();
                clearInterval(timer);
                handleErrorFast("⏰ Délai d'attente dépassé. Le paiement peut prendre quelques minutes.");
                renderFast();
            }
        }, 2 * 60 * 1000);

        state.listeners.push(unsubscribe, timeout, timer);
    }

    async function handleTransactionSuccess(data) {
        performanceMetrics.logStep('Handle success start');
        
        state.pageStatus = 'fetchingCredentials';
        renderFast();
        
        try {
            const ticketDoc = await db.collection('tickets').doc(data.ticketId).get();
            if (ticketDoc.exists) {
                state.finalTicket = { id: ticketDoc.id, ...ticketDoc.data() };
                state.pageStatus = 'success';
                performanceMetrics.logStep('Success handling complete');
            } else {
                throw new Error("Ticket final non trouvé.");
            }
        } catch (error) {
            console.error('❌ Erreur récupération ticket:', error);
            handleErrorFast("✅ Paiement réussi mais erreur technique. Contactez le support avec votre numéro.");
        }
        
        renderWithTransition(); // Animation pour le succès
    }

    function handleTransactionFailure(data) {
        const reason = data.failureReason || "Paiement refusé par votre opérateur";
        handleErrorFast(`❌ ${reason}`);
        renderFast();
    }
    
    function handleErrorFast(userMessage, errorObject = null) {
        if (errorObject) {
            console.error(`❌ Erreur: ${userMessage}`, errorObject);
        }
        state.pageStatus = 'failed';
        state.errorMessage = userMessage;
        clearListeners();
        performanceMetrics.logStep('Error handled');
    }

    // --- GESTION DES ÉVÉNEMENTS OPTIMISÉE ---

    function attachEventListeners() {
        const phoneInput = document.getElementById('phone-input');
        if (phoneInput) {
            const payButton = document.getElementById('pay-button');
            
            // Validation optimisée avec debouncing
            let validationTimeout;
            phoneInput.addEventListener('input', (e) => {
                clearTimeout(validationTimeout);
                validationTimeout = setTimeout(() => {
                    const value = e.target.value.trim();
                    const isValid = /^6\d{8}$/.test(value);
                    
                    payButton.disabled = !isValid;
                    payButton.textContent = isValid ? 
                        '✅ Payer et recevoir mon code' : 
                        '🔒 Payer et recevoir mon code';
                        
                    // Feedback visuel immédiat
                    phoneInput.style.borderColor = value.length === 0 ? '' : 
                        (isValid ? '#4CAF50' : '#ff5722');
                }, 300);
            });
            
            // Formatage automatique du numéro
            phoneInput.addEventListener('keydown', (e) => {
                // Permettre seulement les chiffres et touches de contrôle
                if (!/[0-9]/.test(e.key) && !['Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
                    e.preventDefault();
                }
            });
            
            payButton.addEventListener('click', initiatePaymentOptimized);
        }

        const copyButton = document.getElementById('copy-button');
        if (copyButton) {
            copyButton.addEventListener('click', async () => {
                const ticket = state.finalTicket;
                const textToCopy = `Utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}`;
                
                try {
                    await navigator.clipboard.writeText(textToCopy);
                    copyButton.innerHTML = '✅ Copié !';
                    setTimeout(() => { 
                        copyButton.innerHTML = '📋 Copier les Identifiants'; 
                    }, 2000);
                } catch (error) {
                    console.warn('⚠️ Fallback pour copie:', error);
                    // Fallback pour navigateurs anciens
                    const textArea = document.createElement('textarea');
                    textArea.value = textToCopy;
                    document.body.appendChild(textArea);
                    textArea.select();
                    document.execCommand('copy');
                    document.body.removeChild(textArea);
                    
                    copyButton.innerHTML = '✅ Copié !';
                    setTimeout(() => { 
                        copyButton.innerHTML = '📋 Copier les Identifiants'; 
                    }, 2000);
                }
            });
        }
        
        const retryButton = document.getElementById('retry-button');
        if (retryButton) {
            retryButton.addEventListener('click', () => {
                state.pageStatus = 'idle';
                state.errorMessage = '';
                renderFast();
            });
        }
    }
    
    function clearListeners() {
        state.listeners.forEach(item => {
            if (typeof item === 'function') {
                item(); // Unsubscribe function
            } else {
                clearTimeout(item); // Timeout
                clearInterval(item); // Interval
            }
        });
        state.listeners = [];
    }
    
    // --- DÉMARRAGE DE L'APPLICATION OPTIMISÉ ---
    function main() {
        performanceMetrics.logStep('Main function start');
        
        const urlParams = new URLSearchParams(window.location.search);
        const ticketTypeId = urlParams.get('ticketTypeId');

        if (!ticketTypeId) {
            handleErrorFast("🔗 Lien invalide. L'identifiant du forfait est manquant.");
            renderFast();
            return;
        }

        // Préchargement CSS critique inline
        const criticalCSS = `
            .spinner-optimized { 
                width: 40px; height: 40px; 
                border: 4px solid #f3f3f3; 
                border-top: 4px solid #3498db; 
                border-radius: 50%; 
                animation: spin 1s linear infinite; 
                margin: 20px auto;
            }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            .credentials-card code { 
                background: #f5f5f5; 
                padding: 4px 8px; 
                border-radius: 4px; 
                font-family: monospace;
                font-weight: bold;
            }
            .help-text { 
                display: block; 
                margin-top: 10px; 
                color: #666; 
                font-size: 0.9em;
            }
            .progress-info {
                margin-top: 15px;
                padding: 10px;
                background: #f0f0f0;
                border-radius: 5px;
                font-size: 0.9em;
            }
        `;
        
        const styleElement = document.createElement('style');
        styleElement.textContent = criticalCSS;
        document.head.appendChild(styleElement);

        console.log('🚀 Application démarrée - Mode Performance');
        console.log(`📱 Ticket ID: ${ticketTypeId}`);
        
        renderFast(); // Affichage immédiat du spinner
        loadTicketTypeDetails(ticketTypeId);
        
        performanceMetrics.logStep('Application fully loaded');
    }

    // Démarrer l'application
    main();
});