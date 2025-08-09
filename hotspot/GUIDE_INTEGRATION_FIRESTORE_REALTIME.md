# Guide d'intégration Firestore en temps réel

## 📋 Vue d'ensemble

Ce guide détaille la migration du système de polling actuel vers une écoute en temps réel des transactions via Firestore. Cette approche permet de recevoir automatiquement les mises à jour de statut dès que les webhooks modifient les transactions.

## 🔍 Analyse de l'architecture actuelle

### Système actuel (Polling)

L'application utilise actuellement un système de polling avec les caractéristiques suivantes :

1. **Initiation du paiement** (`firebase-integration.js:215`)
   - Appel HTTP POST vers `/initiatePublicPayment`
   - Retour immédiat avec `transactionId`

2. **Monitoring par polling** (`ui-handlers.js:212` et `ticket.js:164`)
   - Appels répétés à `/checkTransactionStatus`
   - Backoff progressif (1.5s → 6s)
   - Timeout global de 90 secondes

3. **Limitations actuelles**
   - Consommation réseau excessive
   - Latence de détection des changements
   - Charge serveur inutile
   - Délais variables selon l'intervalle de polling

### Avantages de Firestore en temps réel

- ✅ **Instantané** : Mises à jour immédiates via websockets
- ✅ **Économique** : Pas de polling répétitif
- ✅ **Fiable** : Reconnexion automatique en cas de perte réseau
- ✅ **Scalable** : Gestion native des montées en charge

## 🛠️ Plan d'implémentation

### Étape 1 : Mise à jour des dépendances Firebase

#### Modifications dans `login.html` (ligne 14-15)

**Actuel :**
```html
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-functions-compat.js"></script>
```

**Nouveau :**
```html
<!-- Firebase v9 avec Firestore -->
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-functions-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore-compat.js"></script>
```

### Étape 2 : Configuration Firestore

#### Mise à jour de `config.js`

Ajouter la configuration Firestore dans l'objet CONFIG :

```javascript
const CONFIG = {
  // Configuration Firebase existante...
  firebase: {
    apiKey: "AIzaSyDT9KnNJgE5ShcT8KKsOj5J9cOmW6Rx3kY",
    authDomain: "dnet-29b02.firebaseapp.com",
    projectId: "dnet-29b02",
    storageBucket: "dnet-29b02.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456"
  },

  // NOUVEAU : Configuration Firestore
  firestore: {
    // Collection où sont stockées les transactions
    transactionsCollection: 'transactions',
    
    // Options de surveillance
    realtimeOptions: {
      // Réessais automatiques en cas de déconnexion
      maxRetries: 5,
      retryDelayMs: 1000,
      
      // Timeout pour la connexion initiale
      connectionTimeoutMs: 10000,
      
      // Désactiver le cache local pour éviter les données obsolètes
      enableLocalCache: false
    }
  },

  // Configuration UI mise à jour
  ui: {
    loaderTimeout: 10000,
    // SUPPRIMÉ : transactionMonitorTimeout et transactionCheckInterval
    // (plus nécessaires avec le temps réel)
    
    // NOUVEAU : Timeout pour l'écoute Firestore
    firestoreListenerTimeout: 300000, // 5 minutes max
  }
};
```

### Étape 3 : Modification de `firebase-integration.js`

#### A. Initialisation Firestore

Modifier la méthode `init()` pour inclure Firestore :

```javascript
/**
 * Initialise la connexion Firebase avec support Firestore
 * 
 * @async
 * @returns {Promise<boolean>} true si Firebase+Firestore sont initialisés
 */
async init() {
  try {
    if (this.initialized) return true;

    if (!CONFIG.firebase || !CONFIG.firebase.apiKey) {
      console.warn('⚠️ Configuration Firebase manquante');
      return false;
    }

    // Initialiser Firebase
    if (!firebase.apps || firebase.apps.length === 0) {
      firebase.initializeApp(CONFIG.firebase);
    }
    
    // Initialiser Functions et Firestore
    this.functions = firebase.functions();
    this.firestore = firebase.firestore();
    
    // Configuration Firestore
    if (!CONFIG.firestore.realtimeOptions.enableLocalCache) {
      this.firestore.disableNetwork();
      await this.firestore.enableNetwork();
    }

    this.initialized = true;
    console.log('✅ Firebase + Firestore initialisés');
    return true;
  } catch (error) {
    console.error('❌ Erreur d\'initialisation Firebase:', error);
    return false;
  }
}
```

#### B. Nouvelle méthode d'écoute temps réel

Ajouter cette nouvelle méthode dans la classe `FirebaseIntegration` :

```javascript
/**
 * Écoute en temps réel les changements d'une transaction via Firestore
 * 
 * Cette méthode remplace le système de polling en établissant un listener
 * Firestore qui se déclenche automatiquement à chaque modification.
 * 
 * @param {string} transactionId - ID de la transaction à surveiller
 * @param {Function} onUpdate - Callback appelé à chaque mise à jour
 * @param {Function} onError - Callback appelé en cas d'erreur
 * @returns {Function} Fonction pour arrêter l'écoute
 */
listenToTransaction(transactionId, onUpdate, onError) {
  if (!this.firestore) {
    console.error('❌ Firestore non initialisé');
    onError?.(new Error('Firestore non disponible'));
    return () => {};
  }

  const docRef = this.firestore
    .collection(CONFIG.firestore.transactionsCollection)
    .doc(transactionId);

  console.log('👂 Démarrage écoute temps réel pour transaction:', transactionId);

  // Établir l'écoute en temps réel
  const unsubscribe = docRef.onSnapshot(
    {
      // Options pour forcer les données du serveur
      source: 'server',
      includeMetadataChanges: false
    },
    (docSnapshot) => {
      try {
        if (!docSnapshot.exists) {
          console.warn('⚠️ Transaction non trouvée:', transactionId);
          onError?.(new Error('Transaction non trouvée'));
          return;
        }

        const transactionData = docSnapshot.data();
        const lastUpdate = docSnapshot.metadata.fromCache ? 'cache' : 'serveur';
        
        console.log(`📱 Mise à jour reçue depuis ${lastUpdate}:`, transactionData);

        // Appeler le callback avec les nouvelles données
        onUpdate?.(transactionData);
        
      } catch (error) {
        console.error('❌ Erreur lors du traitement de la mise à jour:', error);
        onError?.(error);
      }
    },
    (error) => {
      console.error('❌ Erreur Firestore listener:', error);
      
      // Gestion des erreurs de permission
      if (error.code === 'permission-denied') {
        onError?.(new Error('Accès refusé à la transaction'));
        return;
      }
      
      // Gestion des erreurs réseau
      if (error.code === 'unavailable') {
        console.warn('⚠️ Firestore temporairement indisponible, tentative de reconnexion...');
        // Le SDK Firebase gère automatiquement les reconnexions
        return;
      }
      
      onError?.(error);
    }
  );

  // Timeout de sécurité
  const timeoutId = setTimeout(() => {
    console.warn('⏰ Timeout atteint pour l\'écoute Firestore');
    unsubscribe();
    onError?.(new Error('Timeout de surveillance dépassé'));
  }, CONFIG.ui.firestoreListenerTimeout);

  // Retourner une fonction de nettoyage
  return () => {
    console.log('🛑 Arrêt de l\'écoute temps réel');
    clearTimeout(timeoutId);
    unsubscribe();
  };
}
```

### Étape 4 : Modification de `ui-handlers.js`

#### A. Remplacer le système de polling

Remplacer la méthode `startTransactionMonitoring` :

```javascript
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
  }, CONFIG.ui.firestoreListenerTimeout);
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
```

### Étape 5 : Modification de `ticket.js`

#### Mise à jour du PaymentFlow

Remplacer la méthode `_start()` et `_tick()` :

```javascript
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
}
```

### Étape 6 : Configuration côté serveur (Cloud Functions)

#### Structure Firestore recommandée

```javascript
// Collection: transactions
// Document ID: {transactionId}
{
  id: "trans_123456",
  status: "pending", // created, pending, processing, completed, failed, expired
  amount: 1000,
  phoneNumber: "237690123456",
  planId: "1jour",
  planName: "1 Jour Illimité",
  freemopayReference: "FMP_REF_789",
  providerMessage: null,
  credentials: null, // Ajouté quand status = completed
  createdAt: Timestamp,
  updatedAt: Timestamp,
  expiresAt: Timestamp,
  
  // Métadonnées webhook
  webhookEvents: [
    {
      event: "payment.created",
      timestamp: Timestamp,
      data: {...}
    },
    {
      event: "payment.completed", 
      timestamp: Timestamp,
      data: {...}
    }
  ]
}
```

#### Modification des Cloud Functions

```javascript
// Exemple de Cloud Function webhook qui met à jour Firestore
exports.handlePaymentWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { transactionId, status, ...webhookData } = req.body;
    
    const transactionRef = admin.firestore()
      .collection('transactions')
      .doc(transactionId);
    
    // Préparer les données de mise à jour
    const updateData = {
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      [`webhookEvents.${Date.now()}`]: {
        event: webhookData.event,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        data: webhookData
      }
    };
    
    // Ajouter les credentials si le paiement est complété
    if (status === 'completed') {
      const credentials = await generateWifiCredentials(transactionId);
      updateData.credentials = credentials;
    }
    
    // Mettre à jour Firestore - ceci déclenchera automatiquement
    // les listeners côté client !
    await transactionRef.update(updateData);
    
    console.log(`Transaction ${transactionId} mise à jour: ${status}`);
    res.status(200).json({ success: true });
    
  } catch (error) {
    console.error('Erreur webhook:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### Étape 7 : Règles de sécurité Firestore

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Les transactions peuvent être lues par n'importe qui avec l'ID
    // mais seulement écrites par les Cloud Functions (authentifiées)
    match /transactions/{transactionId} {
      // Lecture permise pour tous (le portail captif n'a pas d'auth user)
      allow read: if true;
      
      // Écriture seulement pour les fonctions authentifiées
      allow write: if request.auth != null && request.auth.token.admin == true;
      
      // Ou alternativement, permettre les écritures depuis des fonctions spécifiques
      // allow write: if request.auth != null && 
      //   request.auth.token.firebase.sign_in_provider == 'custom';
    }
  }
}
```

### Étape 8 : Tests et validation

#### A. Test du fallback

Créer une fonction de test pour vérifier le basculement :

```javascript
// À ajouter temporairement dans firebase-integration.js pour les tests
async testFirestoreConnection() {
  try {
    // Tenter une lecture simple
    const testDoc = await this.firestore
      .collection('transactions')
      .doc('test')
      .get();
    
    console.log('✅ Connexion Firestore OK');
    return true;
  } catch (error) {
    console.error('❌ Test Firestore échoué:', error);
    return false;
  }
}
```

#### B. Mode de débogage

Ajouter dans `config.js` :

```javascript
const CONFIG = {
  // ...existing config...
  
  // Mode debug pour tester les deux systèmes
  debug: {
    // Force l'utilisation du polling même si Firestore est disponible
    forcePolling: false,
    
    // Active les logs détaillés
    verbose: true,
    
    // Simule des erreurs Firestore pour tester le fallback
    simulateFirestoreErrors: false
  }
};
```

## 🚀 Migration progressive

### Phase 1 : Préparation (Semaine 1)
1. ✅ Ajouter les dépendances Firestore
2. ✅ Mettre à jour la configuration
3. ✅ Préparer les Cloud Functions côté serveur
4. ✅ Configurer les règles de sécurité Firestore

### Phase 2 : Implémentation (Semaine 2)
1. ✅ Implémenter le système Firestore en parallèle
2. ✅ Conserver le système de polling comme fallback
3. ✅ Tests avec un petit groupe d'utilisateurs
4. ✅ Monitoring et ajustements

### Phase 3 : Déploiement (Semaine 3)
1. ✅ Activation progressive sur tous les utilisateurs
2. ✅ Monitoring des performances
3. ✅ Suppression graduelle du code de polling
4. ✅ Documentation finale

## ⚡ Optimisations avancées

### A. Gestion de la déconnexion réseau

```javascript
// Ajouter dans firebase-integration.js
setupNetworkMonitoring() {
  // Écouter les événements de connexion
  window.addEventListener('online', () => {
    console.log('📶 Connexion rétablie');
    // Firestore se reconnecte automatiquement
  });
  
  window.addEventListener('offline', () => {
    console.log('📵 Connexion perdue');
    // Informer l'utilisateur
    uiHandlers.showNetworkStatus(false);
  });
}
```

### B. Cache intelligent

```javascript
// Système de cache pour réduire les appels
class TransactionCache {
  constructor(ttlMs = 30000) { // 30 secondes
    this.cache = new Map();
    this.ttl = ttlMs;
  }
  
  get(transactionId) {
    const entry = this.cache.get(transactionId);
    if (!entry) return null;
    
    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(transactionId);
      return null;
    }
    
    return entry.data;
  }
  
  set(transactionId, data) {
    this.cache.set(transactionId, {
      data,
      timestamp: Date.now()
    });
  }
  
  clear() {
    this.cache.clear();
  }
}
```

### C. Metrics et monitoring

```javascript
// Ajouter dans firebase-integration.js pour le monitoring
class FirestoreMetrics {
  constructor() {
    this.metrics = {
      connectionsSuccessful: 0,
      connectionsFailed: 0,
      messagesReceived: 0,
      averageLatency: 0,
      fallbackActivations: 0
    };
  }
  
  recordConnection(success) {
    if (success) {
      this.metrics.connectionsSuccessful++;
    } else {
      this.metrics.connectionsFailed++;
      this.metrics.fallbackActivations++;
    }
  }
  
  recordMessage(latency) {
    this.metrics.messagesReceived++;
    this.metrics.averageLatency = 
      (this.metrics.averageLatency + latency) / 2;
  }
  
  getReport() {
    return {
      ...this.metrics,
      successRate: this.metrics.connectionsSuccessful / 
        (this.metrics.connectionsSuccessful + this.metrics.connectionsFailed),
      timestamp: new Date().toISOString()
    };
  }
}
```

## 🎯 Avantages attendus

### Performance
- **-80% de requêtes réseau** (suppression du polling)
- **-90% de latence** sur les mises à jour
- **+50% de réactivité** de l'interface utilisateur

### Expérience utilisateur
- **Mise à jour instantanée** des statuts
- **Interface plus fluide** sans rechargements
- **Feedback temps réel** sur les paiements

### Coûts opérationnels
- **-70% de charges serveur** Firebase
- **Réduction de la bande passante**
- **Meilleure scalabilité**

## 📚 Ressources et documentation

### Documentation Firebase
- [Firestore Real-time Updates](https://firebase.google.com/docs/firestore/query-data/listen)
- [Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Error Handling](https://firebase.google.com/docs/firestore/handle-errors)

### Outils de monitoring
- Firebase Console pour surveiller l'utilisation
- Google Cloud Monitoring pour les métriques avancées
- Logs personnalisés pour le débogage

---

*Guide créé par l'équipe technique Dnet - Version 1.0*