## Description Détaillée du Projet : Plateforme de Vente de Tickets WiFi via Portail Captif

Ce document décrit en détail le projet de création d'une plateforme web permettant à des utilisateurs (marchands) de vendre des accès WiFi sous forme de tickets, via un portail captif. Les clients finaux pourront acheter ces tickets en utilisant la solution de paiement mobile Freemopay. Le projet sera développé en utilisant Flutter Web pour l'interface utilisateur, GoRouter pour la navigation, GetX pour la gestion de l'état, et Firebase comme backend pour l'authentification et la base de données.

### **1. Architecture Technologique**

*   **Frontend :** Flutter Web sera utilisé pour créer une application web responsive et performante, accessible depuis n'importe quel navigateur.
    *   **GoRouter :** Assurera une gestion de la navigation déclarative et simple, essentielle pour une application web avec différentes sections.
    *   **GetX :** Sera employé pour une gestion d'état efficace et réactive, simplifiant la logique de l'interface utilisateur.
*   **Backend :** Firebase fournira un ensemble de services backend robustes et évolutifs.
    *   **Firebase Authentication :** Gérera l'inscription et la connexion des marchands de manière sécurisée, notamment via l'authentification par email/mot de passe et potentiellement par numéro de téléphone.
    *   **Cloud Firestore :** Servira de base de données NoSQL pour stocker toutes les informations du projet, y compris les comptes des marchands, les zones WiFi, les types de tickets et les tickets eux-mêmes.
*   **API de Paiement :** L'API Freemopay v2 sera intégrée pour permettre les paiements par Mobile Money.

### **2. Espace Marchand : Gestion de la Plateforme**

#### **2.1. Création de Compte Marchand**

La première étape pour un nouvel utilisateur sera de créer un compte marchand. Le formulaire d'inscription collectera les informations suivantes :

*   **Nom :** Nom complet du marchand ou de son entreprise.
*   **Email :** Adresse email qui servira d'identifiant principal.
*   **Numéro de téléphone :** Pour des raisons de contact et de vérification.
*   **Mot de passe & Confirmer le mot de passe :** Pour sécuriser l'accès au compte.
*   **merchantAppKey & merchantSecretKey :** Les clés d'API fournies par Freemopay pour authentifier les requêtes de paiement. Ces clés devront être stockées de manière sécurisée.
*   **callbackUrl :** L'URL de webhook que Freemopay utilisera pour notifier la plateforme du statut des transactions (SUCCESS ou FAILED).

#### **2.2. Gestion des Zones WiFi**

Une fois son compte créé, le marchand pourra définir une ou plusieurs zones WiFi, correspondant chacune à un routeur physique :

*   **nomZone :** Un nom facilement identifiable pour la zone (ex: "Restaurant Le Gourmet - Etage 1").
*   **description :** Une description plus détaillée de l'emplacement de la zone.
*   **type de routeur :** Informations sur le modèle du routeur (ex: MikroTik hAP ac²).

Ces informations seront stockées dans une collection `wifiZones` dans Firestore, liée au compte du marchand.

#### **2.3. Gestion des Types de Tickets**

Pour chaque zone WiFi, le marchand pourra créer différents types de tickets (forfaits) avec des caractéristiques spécifiques :

*   **Nom :** Un nom commercial pour le ticket (ex: "Forfait 1 Heure", "Pass Journée").
*   **Description :** Une brève description des avantages du ticket.
*   **Prix :** Le montant que le client final devra payer.
*   **Validité :** La durée pendant laquelle le ticket reste valide après la première utilisation (ex: 24 heures).
*   **expirationApresCreation :** La durée après laquelle le ticket expire s'il n'a jamais été utilisé.
*   **nbMaxUtilisations :** Le nombre maximum de fois que le ticket peut être utilisé (généralement 1).
*   **isActif :** Un booléen pour activer ou désactiver la vente de ce type de ticket.

Ces types de tickets seront stockés dans une sous-collection de la zone WiFi correspondante dans Firestore.

#### **2.4. Importation des Tickets depuis Mikhmon**

Le marchand générera des lots de tickets (vouchers) sur son serveur Mikhmon (un gestionnaire de Hotspot pour MikroTik). Il exportera ensuite ces tickets sous un format CSV contenant les champs suivants :

*   **Username**
*   **Password**
*   **Profile**
*   **Limit-uptime**
*   **Limit-bytes-total**
*   **Comment**

La plateforme permettra au marchand d'uploader ce fichier CSV pour un type de ticket spécifique. Un script côté backend (potentiellement un Cloud Function) lira le fichier et créera des documents individuels pour chaque ticket dans une sous-collection du type de ticket correspondant dans Firestore. Chaque ticket aura un statut initial (par exemple, "disponible").

### **3. Portail Captif : Expérience Client Final**

Lorsqu'un client final se connectera au réseau WiFi d'une zone, il sera redirigé vers le portail captif développé en Flutter Web.

#### **3.1. Affichage des Offres**

Le portail affichera la liste des types de tickets disponibles pour cette zone WiFi, avec leur nom, description, prix et validité.

#### **3.2. Processus de Paiement**

1.  **Sélection du Ticket :** Le client clique sur le ticket qu'il souhaite acheter.
2.  **Popup de Paiement :** Une fenêtre modale s'ouvrira, affichant un résumé du forfait sélectionné et un champ pour saisir son numéro de téléphone (au format `2376xxxxxxxx`).
3.  **Initiation du Paiement :** En cliquant sur "Payer", l'application enverra une requête `POST` à l'endpoint `/api/v2/payment` de Freemopay. Cette requête utilisera l'authentification `Basic Auth` avec la `merchantAppKey` et la `merchantSecretKey` du marchand. Le corps de la requête contiendra :
    *   `payer` : Le numéro de téléphone du client.
    *   `amount` : Le prix du ticket.
    *   `externalId` : Un identifiant unique généré par la plateforme pour cette transaction.
    *   `description` : La description du ticket.
    *   `callback` : L'URL de callback du marchand.
4.  **Confirmation sur Mobile :** Le client recevra une notification sur son téléphone pour valider le paiement Mobile Money.

#### **3.3. Réception et Validation du Ticket**

*   **Callback de Freemopay :** Une fois le paiement validé (ou échoué), Freemopay enverra une requête `POST` au `callbackUrl` fourni par le marchand. Le payload de cette requête contiendra le statut final (`SUCCESS` ou `FAILED`) et l'`externalId` de la transaction.
*   **Mise à jour du Statut du Ticket :** Un Cloud Function sur Firebase écoutera cette URL de callback.
    *   Si le statut est `SUCCESS`, la fonction recherchera la transaction correspondante via son `externalId`. Elle sélectionnera ensuite un ticket "disponible" du type acheté, le marquera comme "vendu" et y associera les informations de la transaction (numéro de téléphone de l'acheteur, référence de la transaction Freemopay).
    *   Si le statut est `FAILED`, la transaction sera marquée comme échouée dans la base de données.
*   **Affichage du Ticket au Client :** Côté client, l'application interrogera périodiquement le statut de la transaction (ou utilisera des listeners temps réel de Firestore). Dès que le paiement est confirmé, le portail affichera les identifiants (`Username` et `Password`) du ticket au client pour qu'il puisse se connecter à internet.

### **4. Fonctionnalité "Récupérer mon Ticket"**

Le portail captif inclura un lien "Récupérer mon ticket". Cette fonctionnalité permettra à un utilisateur qui aurait fermé la page après le paiement de retrouver ses identifiants :

1.  **Saisie de la Référence de Transaction :** L'utilisateur devra saisir le numéro de la transaction (ou son numéro de téléphone utilisé pour le paiement).
2.  **Recherche dans la Base de Données :** L'application interrogera Firestore pour trouver une transaction correspondante.
3.  **Affichage des Identifiants :** Si une transaction valide est trouvée, les identifiants (`Username` et `Password`) du ticket associé lui seront de nouveau affichés.






---

### Modélisation de la Base de Données Firestore

#### Vue d'ensemble de la Structure

```
merchants (collection)
└── {merchantId} (document)
    ├── freemopayCredentials (subcollection, accès restreint)
    │   └── {credentialId} (document)
    ├── wifiZones (subcollection)
    │   └── {zoneId} (document)
    │       └── ticketTypes (subcollection)
    │           └── {typeId} (document)
    │               └── tickets (subcollection)
    │                   └── {ticketId} (document)
    └── transactions (subcollection, pour un suivi par marchand)

transactions (collection, top-level pour les callbacks)
└── {transactionId} (document)
```

---

### 1. Collection `merchants`

C'est la collection principale qui contient tous les comptes marchands. Le **Document ID** `{merchantId}` devrait idéalement être l'**UID** de l'utilisateur fourni par Firebase Authentication. Cela simplifie énormément la gestion des règles de sécurité.

**Collection :** `merchants`

**Document :** `{merchantId}` (par ex: `uid_de_firebase_auth`)

```json
{
  "uid": "uid_de_firebase_auth",
  "name": "Le Restaurant du Coin",
  "email": "contact@restaurantducoin.com",
  "phoneNumber": "+237699887766",
  "createdAt": "2023-10-27T10:00:00Z" // Timestamp
}
```

#### 1.1 Sous-collection `freemopayCredentials` (Sécurité Renforcée)

Il est **fortement déconseillé** de stocker les clés d'API directement dans le document principal du marchand, qui pourrait être lu par l'application client. On les isole dans une sous-collection avec des règles de sécurité très strictes, autorisant la lecture uniquement par des fonctions Cloud (backend).

**Chemin :** `merchants/{merchantId}/freemopayCredentials/{credentialId}`

```json
{
  "merchantAppKey": "SECURED_APP_KEY",
  "merchantSecretKey": "SECURED_SECRET_KEY", // Idéalement, chiffrer cette valeur
  "callbackUrl": "https://us-central1-monprojet.cloudfunctions.net/freemopayWebhook"
}
```

---

### 2. Sous-collection `wifiZones`

Chaque marchand peut avoir plusieurs zones WiFi. Elles sont stockées dans une sous-collection de son document.

**Chemin :** `merchants/{merchantId}/wifiZones/{zoneId}` (Firestore auto-ID pour `{zoneId}`)

```json
{
  "nameZone": "Restaurant - Terrasse",
  "description": "Zone WiFi couvrant la terrasse extérieure",
  "routerType": "MikroTik hAP ac²",
  "isActive": true,
  "createdAt": "2023-10-27T10:05:00Z" // Timestamp
}
```

---

### 3. Sous-collection `ticketTypes`

Chaque zone WiFi a ses propres types de tickets (forfaits).

**Chemin :** `merchants/{merchantId}/wifiZones/{zoneId}/ticketTypes/{typeId}` (Firestore auto-ID pour `{typeId}`)

```json
{
  "name": "Pass Soirée",
  "description": "Accès illimité de 18h à minuit",
  "price": 500, // En XAF
  "validity": "6h", // Pour affichage
  "validityInSeconds": 21600, // Pour la logique interne
  "expirationAfterCreation": 30, // En jours
  "nbMaxUtilisations": 1,
  "isActive": true,
  "createdAt": "2023-10-27T10:10:00Z",

  // --- Champs de dénormalisation pour la performance ---
  "stats": {
    "totalTicketsCount": 500,
    "availableTicketsCount": 450,
    "soldTicketsCount": 50
  }
}
```
**Note sur `stats` :** Ces compteurs sont mis à jour par des Cloud Functions à chaque import (pour `totalTicketsCount`) ou vente (pour `available` et `sold`). Cela évite de devoir compter tous les documents de la sous-collection `tickets` à chaque affichage, ce qui serait très coûteux.

---

### 4. Sous-collection `tickets`

C'est ici que sont stockés les tickets individuels importés depuis Mikhmon.

**Chemin :** `merchants/{merchantId}/wifiZones/{zoneId}/ticketTypes/{typeId}/tickets/{ticketId}` (Firestore auto-ID pour `{ticketId}`)

```json
{
  // --- Données de Mikhmon ---
  "username": "user-abc1",
  "password": "pwd-xyz2",
  "profile": "Forfait_Soiree",
  "limitUptime": "6h",
  "limitBytesTotal": "0", // 0 pour illimité
  "comment": "Import du 27/10/2023",

  // --- Champs de gestion interne ---
  "status": "available", // "available", "locked", "sold"
  "transactionId": null, // Sera rempli avec l'ID de la transaction après la vente
  "soldAt": null, // Timestamp de la vente
  "buyerPhoneNumber": null // Numéro de téléphone de l'acheteur
}
```
**Note sur `status` :**
*   `available` : Le ticket est disponible à la vente.
*   `locked` : Un client a initié un paiement pour ce ticket. Il est temporairement réservé. Si le paiement échoue ou expire, une fonction Cloud le repasse en `available`.
*   `sold` : Le ticket est vendu et ne peut plus être utilisé.

---

### 5. Collection `transactions` (Top-Level)

Il est préférable d'avoir une collection racine pour les transactions afin de les traiter facilement via une Cloud Function qui écoute le webhook de Freemopay, sans avoir à connaître le marchand ou la zone à l'avance. Le **Document ID** `{transactionId}` doit être l'**`externalId`** que vous générez et envoyez à Freemopay.

**Collection :** `transactions`

**Document :** `{transactionId}` (votre `externalId` unique, ex: `trans_1698398400_abc`)

```json
{
  "externalId": "trans_1698398400_abc",
  "freemopayReference": null, // Rempli par la réponse initiale de Freemopay
  "status": "pending", // "pending", "success", "failed", "cancelled"
  "amount": 500,
  "buyerPhoneNumber": "2376xxxxxxxx",
  "description": "Achat Pass Soirée",

  // --- Références pour lier les données ---
  "merchantId": "uid_de_firebase_auth",
  "zoneId": "id_de_la_zone_wifi",
  "ticketTypeId": "id_du_type_de_ticket",
  "ticketId": "id_du_ticket_verrouille", // L'ID du ticket qui a été "locked"

  // --- Timestamps et Audit ---
  "createdAt": "2023-10-27T11:20:00Z",
  "updatedAt": "2023-10-27T11:20:00Z",
  "freemopayCallbackPayload": {} // Pour stocker la réponse complète du webhook pour le débogage
}
```

### Logique d'Interaction avec ce Modèle

1.  **Achat d'un Ticket :**
    *   Le client choisit un `ticketType`.
    *   L'application backend (Cloud Function) fait une requête sur la sous-collection `tickets` correspondante : `.../tickets.where('status', '==', 'available').limit(1).get()`.
    *   Elle trouve un ticket disponible, met son `status` à `locked` et récupère son `{ticketId}`.
    *   Elle crée un document dans la collection `transactions` avec le statut `pending` et toutes les références (`merchantId`, `zoneId`, `ticketTypeId`, `ticketId`).
    *   Elle envoie la requête de paiement à Freemopay avec l'`externalId` de la transaction.

2.  **Callback de Freemopay :**
    *   Freemopay appelle votre webhook (`callbackUrl`) avec le résultat et l'`externalId`.
    *   Votre Cloud Function reçoit la requête. Grâce à l'`externalId`, elle retrouve instantanément le document de transaction : `db.collection('transactions').doc(externalId).get()`.
    *   **Si `SUCCESS` :**
        *   Elle met à jour le statut de la transaction à `success`.
        *   Elle utilise le `ticketId` stocké dans la transaction pour retrouver le ticket (`.../tickets/{ticketId}`).
        *   Elle met à jour le statut du ticket à `sold`, et renseigne `transactionId`, `soldAt`, `buyerPhoneNumber`.
        *   Elle met à jour les compteurs (`stats`) sur le document `ticketType` (décrémente `availableTicketsCount`, incrémente `soldTicketsCount`).
    *   **Si `FAILED` :**
        *   Elle met à jour le statut de la transaction à `failed`.
        *   Elle remet le statut du ticket à `available` pour qu'il puisse être vendu à quelqu'un d'autre.

3.  **Récupérer mon Ticket :**
    *   L'utilisateur fournit son numéro de téléphone.
    *   L'application interroge la collection `transactions` : `.where('buyerPhoneNumber', '==', numero).where('status', '==', 'success').orderBy('createdAt', 'desc').limit(1).get()`.
    *   Elle récupère le `ticketId` de la transaction trouvée, puis va chercher les informations (`username`, `password`) du document ticket correspondant.