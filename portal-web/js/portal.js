// portal.js

document.addEventListener('DOMContentLoaded', () => {

    // --- INITIALISATION ---
    if (typeof firebase === 'undefined' || !firebase.initializeApp) {
        document.getElementById('view-content').innerHTML = `
            <div class="error-box">Erreur critique : Le SDK Firebase n'a pas pu être chargé. Veuillez vérifier votre connexion.</div>
        `;
        return;
    }
    firebase.initializeApp(firebaseConfig);
    const db = firebase.firestore();
    const functions = firebase.functions();
    
    const mainTitle = document.getElementById('main-title');
    const viewContent = document.getElementById('view-content');
    
    // --- ÉTAT DE L'APPLICATION ---
    const state = {
        pageStatus: 'loading',
        ticketTypeDetails: null,
        finalTicket: null,
        errorMessage: '',
        transactionId: null,
        listeners: [],
    };

    // --- ICÔNES SVG ---
    const icons = {
        success: `<svg class="status-icon success" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"></path></svg>`,
        error: `<svg class="status-icon error" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"></path></svg>`,
        warning: `<svg class="status-icon warning" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"></path></svg>`,
    };

    // --- FONCTIONS DE RENDU (Vues HTML) ---
    function renderLoadingView() {
        mainTitle.textContent = 'Chargement';
        return `<div class="view"><div class="spinner"></div></div>`;
    }

    function renderInitialView() {
        const ticket = state.ticketTypeDetails;
        mainTitle.textContent = `Forfait ${ticket.name}`;
        return `
            <div class="view">
                <div class="price-chip">${ticket.price} XAF</div>
                <p class="description">${ticket.description}</p>
                
                <div class="form-group">
                    <label for="phone-input">Numéro de téléphone (Orange/MTN)</label>
                    <input type="tel" id="phone-input" placeholder="699123456" autocomplete="tel" inputmode="numeric">
                </div>
                <button id="pay-button" class="btn" disabled>Payer et recevoir mon code</button>
            </div>
        `;
    }

    function renderPendingView(message) {
        mainTitle.textContent = 'Paiement en cours';
        return `
            <div class="view">
                <div class="spinner"></div>
                <h2>${message}</h2>
                <p class="description">Veuillez valider la transaction sur votre téléphone. Cette page se mettra à jour automatiquement.</p>
            </div>
        `;
    }

    function renderSuccessView() {
        mainTitle.textContent = 'Paiement Réussi !';
        const ticket = state.finalTicket;
        return `
            <div class="view">
                ${icons.success}
                <h2>Félicitations !</h2>
                <p class="description">Utilisez ces identifiants sur la page de connexion Wi-Fi.</p>
                <div class="credentials-card">
                    <div class="credential-row">
                        <span>Utilisateur:</span>
                        <span>${ticket.username}</span>
                    </div>
                     <div class="credential-row">
                        <span>Mot de passe:</span>
                        <span>${ticket.password}</span>
                    </div>
                </div>
                <br>
                <button id="copy-button" class="btn">Copier les Identifiants</button>
            </div>
        `;
    }

    function renderFailedView() {
        mainTitle.textContent = 'Échec du Paiement';
        return `
            <div class="view">
                ${icons.error}
                <h2>Une erreur est survenue</h2>
                <div class="error-box">${state.errorMessage}</div>
                <br>
                <button id="retry-button" class="btn">Réessayer</button>
            </div>
        `;
    }
    
    function renderOutOfStockView() {
        mainTitle.textContent = 'Forfait Épuisé';
        return `
             <div class="view">
                ${icons.warning}
                <h2>Désolé, stock épuisé</h2>
                <p class="description">Ce forfait est momentanément indisponible. Veuillez contacter le support ou choisir un autre forfait.</p>
             </div>
        `;
    }

    // --- FONCTION DE RENDU PRINCIPALE (avec transition) ---
    function render() {
        viewContent.style.opacity = '0';
        setTimeout(() => {
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
            viewContent.style.opacity = '1';
            attachEventListeners();
        }, 200);
    }

    // --- LOGIQUE MÉTIER ---
    
    async function loadTicketTypeDetails(ticketTypeId) {
        try {
            const doc = await db.collection('ticket_types').doc(ticketTypeId).get();
            if (!doc.exists || !doc.data().isActive) {
                throw new Error("Forfait inactif ou introuvable.");
            }
            state.ticketTypeDetails = { id: doc.id, ...doc.data() };
            state.pageStatus = 'idle';
        } catch (error) {
            handleError("Ce forfait n'est pas accessible ou le lien est invalide.", error);
        }
        render();
    }
    
    async function initiatePayment() {
        const phoneInput = document.getElementById('phone-input');
        state.pageStatus = 'checking';
        render();

        try {
            const initiatePublicPayment = functions.httpsCallable('initiatePublicPayment');
            const response = await initiatePublicPayment({
                ticketTypeId: state.ticketTypeDetails.id,
                phoneNumber: phoneInput.value.trim(),
            });

            state.transactionId = response.data.transactionId;
            if (!state.transactionId) throw new Error("Réponse invalide du serveur.");

            state.pageStatus = 'pending';
            listenForTransactionUpdates(state.transactionId);
        } catch (error) {
            // Gérer les erreurs spécifiques de la Cloud Function
            if (error.code === 'functions/out-of-range') {
                state.pageStatus = 'outOfStock';
            } else {
                const userMessage = error.message || "Une erreur inconnue est survenue.";
                handleError(userMessage, error);
            }
        }
        render();
    }

    function listenForTransactionUpdates(transactionId) {
        clearListeners();
        
        const unsubscribe = db.collection('transactions').doc(transactionId)
            .onSnapshot(async (doc) => {
                if (!doc.exists) return;
                const data = doc.data();
                
                if (data.status === 'completed') {
                    clearListeners();
                    state.pageStatus = 'fetchingCredentials';
                    render();
                    try {
                        const ticketDoc = await db.collection('tickets').doc(data.ticketId).get();
                        if (ticketDoc.exists) {
                            state.finalTicket = { id: ticketDoc.id, ...ticketDoc.data() };
                            state.pageStatus = 'success';
                        } else {
                           throw new Error("Ticket final non trouvé après paiement.");
                        }
                    } catch (e) {
                        handleError("Paiement réussi mais erreur à la récupération du code. Contactez le support.", e);
                    }
                    render();
                } else if (data.status === 'failed') {
                    clearListeners();
                    handleError(data.failureReason || "Le paiement a été refusé par l'opérateur.");
                    render();
                }
            }, (error) => {
                handleError("Erreur de connexion. Veuillez vérifier votre réseau.", error);
                render();
            });

        const timeout = setTimeout(() => {
            if (state.pageStatus === 'pending' || state.pageStatus === 'checking') {
                clearListeners();
                handleError("Le délai de paiement a expiré. Veuillez réessayer.");
                render();
            }
        }, 3 * 60 * 1000);

        state.listeners.push(unsubscribe, timeout);
    }
    
    function handleError(userMessage, errorObject) {
        console.error(`Erreur: ${userMessage}`, errorObject || '');
        state.pageStatus = 'failed';
        state.errorMessage = userMessage;
        clearListeners();
    }

    // --- GESTION DES ÉVÉNEMENTS ---

    function attachEventListeners() {
        const phoneInput = document.getElementById('phone-input');
        if (phoneInput) {
            const payButton = document.getElementById('pay-button');
            phoneInput.addEventListener('input', () => {
                const isValid = /^6\d{8}$/.test(phoneInput.value.trim());
                payButton.disabled = !isValid;
            });
            payButton.addEventListener('click', initiatePayment);
        }

        const copyButton = document.getElementById('copy-button');
        if (copyButton) {
            copyButton.addEventListener('click', () => {
                const ticket = state.finalTicket;
                const textToCopy = `Utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}`;
                navigator.clipboard.writeText(textToCopy).then(() => {
                    copyButton.textContent = 'Copié !';
                    setTimeout(() => { copyButton.textContent = 'Copier les Identifiants'; }, 2000);
                });
            });
        }
        
        const retryButton = document.getElementById('retry-button');
        if (retryButton) {
            retryButton.addEventListener('click', () => {
                state.pageStatus = 'idle';
                state.errorMessage = '';
                render();
            });
        }
    }
    
    function clearListeners() {
        state.listeners.forEach(stop => typeof stop === 'function' ? stop() : clearTimeout(stop));
        state.listeners = [];
    }
    
    // --- DÉMARRAGE DE L'APPLICATION ---
    function main() {
        const urlParams = new URLSearchParams(window.location.search);
        const ticketTypeId = urlParams.get('ticketTypeId');

        if (!ticketTypeId) {
            handleError("Lien de paiement invalide. L'identifiant du forfait est manquant.");
            render();
            return;
        }

        render(); // Affiche le spinner de chargement initial
        loadTicketTypeDetails(ticketTypeId);
    }

    main();
});