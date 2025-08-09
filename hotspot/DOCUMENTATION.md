# Documentation du Portail Captif Dnet

## Vue d'ensemble

Le portail captif Dnet est une application web permettant aux utilisateurs de se connecter à un hotspot WiFi en achetant des forfaits Internet via Mobile Money. L'application est conçue pour être utilisée sur des équipements MikroTik et intègre Firebase pour la gestion des paiements et des forfaits.

## Architecture du projet

### Structure des fichiers

```
hotspot/
├── img/                        # Ressources graphiques
│   ├── favicon.ico
│   ├── logo-dnet.png
│   ├── password.svg
│   └── user.svg
├── scripts/                    # Scripts JavaScript
│   ├── config.js              # Configuration centrale
│   ├── firebase-integration.js # Intégration Firebase
│   ├── main.js                # Point d'entrée principal
│   ├── md5.js                 # Algorithme MD5 pour l'authentification
│   ├── ticket.js              # Gestion des tickets locaux
│   └── ui-handlers.js         # Gestion de l'interface utilisateur
├── styles/                     # Feuilles de style CSS
│   ├── main.css               # Styles principaux
│   └── style.css              # Styles supplémentaires
├── xml/                        # Templates XML pour MikroTik
├── *.html                      # Pages HTML du portail
└── DOCUMENTATION.md           # Cette documentation
```

### Composants principaux

#### 1. Configuration (config.js)

Le fichier `config.js` centralise tous les paramètres de l'application :

- **Configuration Firebase** : Paramètres de connexion aux services Firebase
- **Configuration de zone** : ID de la zone hotspot et clé publique optionnelle
- **URLs des services** : Endpoints des Cloud Functions Firebase
- **Forfaits de fallback** : Forfaits utilisés en cas d'indisponibilité du service
- **Paramètres UI** : Timeouts et intervalles pour l'interface utilisateur

#### 2. Intégration Firebase (firebase-integration.js)

Cette classe gère toutes les interactions avec Firebase :

- **Retry automatique** : Système robuste de gestion des erreurs réseau avec backoff exponentiel
- **Gestion des timeouts** : Configuration flexible des délais d'attente
- **Support des codes d'erreur HTTP** : Gestion spéciale des codes 429 (rate limiting) et 5xx
- **Respect des headers Retry-After** : Pour les limitations de taux

**Méthodes principales :**
- `getPlans()` : Récupère les forfaits disponibles
- `initiatePayment()` : Initie un paiement Mobile Money
- `checkTransactionStatus()` : Vérifie le statut d'une transaction
- `testConnection()` : Teste la connectivité avec Firebase

#### 3. Application principale (main.js)

La classe `HotspotApp` gère le cycle de vie de l'application :

- **Initialisation** : Configuration et démarrage de tous les services
- **Chargement des forfaits** : Récupération depuis Firebase avec fallback automatique
- **Gestion d'erreurs** : Système robuste de gestion des erreurs critiques
- **Nettoyage des ressources** : Libération de la mémoire avant fermeture

#### 4. Interface utilisateur (ui-handlers.js)

La classe `UIHandlers` gère tous les aspects visuels :

- **Gestion des loaders** : Indicateurs de chargement pour différentes actions
- **Création des cartes de forfaits** : Affichage dynamique des forfaits disponibles
- **Monitoring des transactions** : Polling en temps réel avec backoff progressif
- **États finaux** : Affichage des résultats de transaction (succès/échec/timeout)

#### 5. Gestion des tickets (ticket.js)

Ce module gère le stockage local des tickets achetés :

- **Stockage local** : Sauvegarde des identifiants dans localStorage
- **Interface "Mes tickets"** : Vue pour consulter les tickets précédents
- **Mémorisation du téléphone** : Pré-remplissage automatique
- **Flow de paiement** : Interface moderne pour l'achat de forfaits

## Fonctionnalités

### Authentification hotspot

Le système supporte l'authentification CHAP pour MikroTik :
- Utilisation de MD5 pour le hachage des mots de passe
- Variables MikroTik intégrées dans les templates HTML
- Formulaires cachés pour l'authentification automatique

### Paiement Mobile Money

Intégration complète avec les services de paiement :
- Initiation immédiate des transactions
- Polling en temps réel du statut
- Gestion des timeouts et erreurs
- Interface utilisateur responsive

### Mode dégradé

L'application peut fonctionner même en cas d'indisponibilité de Firebase :
- Forfaits de fallback définis localement
- Notifications discrètes à l'utilisateur
- Fonctionnalités limitées mais utilisables

### Gestion des erreurs

Système complet de gestion d'erreurs :
- Retry automatique avec backoff exponentiel
- Logs détaillés pour le débogage
- Notifications utilisateur appropriées
- Nettoyage automatique des ressources

## Configuration et déploiement

### Prérequis

1. **Projet Firebase** configuré avec Cloud Functions
2. **Équipement MikroTik** avec hotspot activé
3. **Certificat SSL** pour les communications sécurisées
4. **Service de paiement Mobile Money** intégré côté serveur

### Configuration Firebase

1. Créer un projet Firebase
2. Activer les Cloud Functions
3. Déployer les fonctions de gestion des forfaits et paiements
4. Configurer les paramètres dans `config.js`

### Configuration MikroTik

1. Activer le serveur hotspot
2. Configurer les pages de login personnalisées
3. Copier les fichiers HTML dans le répertoire hotspot
4. Configurer les redirections appropriées

### Variables de configuration importantes

Dans `config.js`, remplacez les valeurs suivantes :

```javascript
// Configuration Firebase - À REMPLACER
firebase: {
  apiKey: "VOTRE_API_KEY",
  authDomain: "VOTRE_PROJET.firebaseapp.com",
  projectId: "VOTRE_PROJET_ID",
  // ...
},

// Configuration de zone - À REMPLACER
zone: {
  id: 'VOTRE_ZONE_ID',
  publicKey: 'VOTRE_CLE_PUBLIQUE' // Optionnel
},
```

## Sécurité

### Bonnes pratiques implémentées

1. **Chiffrement des communications** : Toutes les requêtes utilisent HTTPS
2. **Validation côté client** : Vérification des formats de numéros de téléphone
3. **Idempotence des transactions** : Génération d'identifiants externes uniques
4. **Gestion des timeouts** : Prévention des requêtes infinies
5. **Nettoyage mémoire** : Libération des ressources avant fermeture de page

### Points d'attention

- Les clés API Firebase sont visibles côté client (normal pour une webapp)
- L'authentification réelle se fait côté serveur via les Cloud Functions
- Les identifiants WiFi sont stockés localement (localStorage) pour commodité

## Maintenance et monitoring

### Logs et débogage

L'application génère des logs détaillés dans la console :
- `🚀` Événements d'initialisation
- `📋` Opérations de chargement des forfaits
- `💰` Transactions de paiement
- `❌` Erreurs et exceptions
- `⚠️` Avertissements et modes dégradés

### Monitoring des performances

Points à surveiller :
- Temps de réponse des Cloud Functions
- Taux d'échec des paiements Mobile Money
- Utilisation des forfaits de fallback
- Erreurs JavaScript côté client

### Mise à jour

Pour mettre à jour l'application :
1. Modifier les fichiers sources
2. Tester en local avec les forfaits de fallback
3. Déployer sur l'équipement MikroTik
4. Vérifier la connectivité Firebase
5. Monitorer les logs pour détecter les problèmes

## Support et dépannage

### Problèmes courants

1. **Forfaits non chargés** : Vérifier la configuration Firebase et la connectivité réseau
2. **Paiements échoués** : Contrôler les logs des Cloud Functions
3. **Interface non responsive** : Vérifier les fichiers CSS et JavaScript
4. **Authentification WiFi échouée** : Vérifier la configuration MikroTik

### Contact support

Pour obtenir de l'aide technique, contactez l'équipe Dnet avec :
- Logs de la console navigateur
- Configuration utilisée (en masquant les clés sensibles)
- Description détaillée du problème rencontré
- Équipement utilisé (modèle MikroTik, version RouterOS)

---

*Documentation générée automatiquement - Version 1.0*