# Configuration des Push Notifications

## État Actuel
✅ **Système complet implémenté et configuré**
✅ **Configuration Android terminée**
✅ **Gestion des tokens FCM en temps réel**
✅ **Cloud Functions adaptées pour cibler les marchands**

## Notifications Implémentées
1. **Transactions échouées** - Notification envoyée quand une transaction échoue
2. **Tickets réservés/libérés** - Notification pour les changements de statut des tickets
3. **Nouvelles ventes** - Notification quand une transaction se termine avec succès
4. **Navigation automatique** - Clic sur notification → Page transactions + BottomSheet

## Fonctionnalités Implémentées

### 1. Gestion des Tokens FCM
- **Sauvegarde automatique** du token dans `merchants.fcmTokens.current`
- **Écoute en temps réel** des changements de token
- **Suppression automatique** lors de la déconnexion
- **Structure**: `{ current: "token", lastUpdated: timestamp, deviceInfo: {...} }`

### 2. Cloud Functions Ciblées
- **Notifications par marchand** - Chaque notification est envoyée uniquement au marchand concerné
- **Récupération via merchantId** - Utilise le merchantId des transactions/zones
- **Logs détaillés** - Suivi des envois et erreurs

### 3. Configuration Android Complète
- **Permissions** - POST_NOTIFICATIONS, WAKE_LOCK, VIBRATE
- **Services Firebase** - FlutterFirebaseMessagingService configuré
- **Icônes et couleurs** - Configuration des notifications natives
- **Handler background** - Gestion des messages en arrière-plan

### 4. Navigation Automatique
- **Clic sur notification** → Page transactions + BottomSheet
- **Données contextuelles** - transactionId, zoneId, zoneName dans les notifications
- **Fallback navigation** - Retour au dashboard si erreur

## Architecture Technique

### NotificationService
- Gestion FCM (Firebase Cloud Messaging)
- Handlers pour foreground/background
- Navigation automatique vers transactions
- Ouverture automatique du BottomSheet

### Cloud Functions Modifiées
- `processTransaction` - Notifications pour échecs/succès
- `reserveTicket` - Notification réservation
- `releaseTicket` - Notification libération
- Fonction utilitaire `sendPushNotification`

### Flux de Notification
1. Action utilisateur (transaction, réservation, etc.)
2. Cloud Function détecte l'événement
3. Récupération des tokens FCM utilisateur
4. Envoi notification via Firebase Admin SDK
5. App reçoit notification
6. Navigation automatique vers la transaction

## Notes Techniques
- Toutes les erreurs sont capturées pour éviter les crashes
- Service désactivé si configuration manquante
- Logs détaillés pour debugging
- Fallback sur dashboard si navigation échoue