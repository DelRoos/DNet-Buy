import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LoggerService _logger = LoggerService.to;
  late final MerchantService _merchantService;
  late final AuthController _authController;
  
  var isInitialized = false.obs;
  var fcmToken = ''.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    
    // Initialiser les services dépendants
    _merchantService = Get.find<MerchantService>();
    _authController = Get.find<AuthController>();
    
    await initialize();
  }

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    try {
      _logger.info('🔔 Initialisation du service de notifications');

      // Demander les permissions avec gestion d'erreur
      await _requestPermissions();
      
      // Obtenir le token FCM avec gestion d'erreur
      await _getFCMToken();
      
      // Configurer les handlers avec gestion d'erreur
      _setupMessageHandlers();
      
      isInitialized.value = true;
      _logger.info('✅ Service de notifications initialisé avec succès');
      
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de l\'initialisation des notifications',
          error: e, stackTrace: stackTrace);
      // Ne pas faire planter l'app, juste marquer comme non initialisé
      isInitialized.value = false;
    }
  }

  /// Demander les permissions pour les notifications
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.info('Permissions notifications: ${settings.authorizationStatus}');
    } catch (e) {
      _logger.error('Erreur lors de la demande de permissions', error: e);
      // Continuer sans permissions plutôt que de planter
    }
  }

  /// Obtenir et sauvegarder le token FCM
  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        fcmToken.value = token;
        _logger.info('Token FCM obtenu: ${token.substring(0, 20)}...');
        
        // Sauvegarder le token côté serveur pour l'utilisateur actuel
        await _saveTokenToServer(token);
      }
    } catch (e) {
      _logger.error('Erreur lors de l\'obtention du token FCM', error: e);
    }
  }

  /// Sauvegarder le token côté serveur
  Future<void> _saveTokenToServer(String token) async {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId != null) {
        _logger.info('💾 Sauvegarde du token FCM pour l\'utilisateur: $userId');
        await _merchantService.saveFCMToken(userId, token);
        
        // Configurer l'écoute en temps réel des changements de token
        _setupTokenListener();
        
        _logger.info('✅ Token FCM sauvegardé et listener configuré');
      } else {
        _logger.error('Impossible de sauvegarder le token: utilisateur non connecté');
      }
    } catch (e) {
      _logger.error('Erreur lors de la sauvegarde du token FCM', error: e);
    }
  }

  /// Configurer l'écoute en temps réel du token FCM
  void _setupTokenListener() {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId != null) {
        // Écouter les changements de token FCM en temps réel
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          _logger.info('🔄 Token FCM mis à jour: ${newToken.substring(0, 20)}...');
          fcmToken.value = newToken;
          
          // Sauvegarder le nouveau token
          try {
            await _merchantService.updateFCMToken(userId, newToken);
            _logger.info('✅ Nouveau token FCM sauvegardé');
          } catch (e) {
            _logger.error('Erreur lors de la sauvegarde du nouveau token', error: e);
          }
        });
        
        _logger.info('🎧 Listener de token FCM configuré');
      }
    } catch (e) {
      _logger.error('Erreur lors de la configuration du listener de token', error: e);
    }
  }

  /// Configurer les handlers de messages
  void _setupMessageHandlers() {
    try {
      // Message reçu quand l'app est en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Message cliqué quand l'app est en background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Vérifier si l'app a été ouverte via une notification
      _checkInitialMessage();
    } catch (e) {
      _logger.error('Erreur lors de la configuration des handlers', error: e);
    }
  }

  /// Gérer les messages en foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('📱 Notification reçue en foreground: ${message.messageId}');
    
    // Afficher une notification locale
    _showLocalNotification(message);
  }

  /// Gérer les messages en background (clic sur notification)
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    _logger.info('🔔 Notification cliquée en background: ${message.messageId}');
    
    // Naviguer vers la page appropriée
    await _handleNotificationTap(message);
  }

  /// Vérifier si l'app a été ouverte via une notification
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.info('🚀 App ouverte via notification: ${initialMessage.messageId}');
        await _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      _logger.error('Erreur lors de la vérification du message initial', error: e);
      // Ne pas faire planter l'app
    }
  }

  /// Afficher une notification locale
  void _showLocalNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Nouvelle notification';
    final body = message.notification?.body ?? '';
    
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: _getNotificationColor(message.data['type']),
      colorText: Colors.white,
      icon: Icon(_getNotificationIcon(message.data['type']), color: Colors.white),
      duration: const Duration(seconds: 4),
      onTap: (_) => _handleNotificationTap(message),
    );
  }

  /// Gérer le clic sur une notification
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    
    _logger.info('📱 Gestion du clic notification: $type');
    
    switch (type) {
      case 'transaction_failed':
      case 'transaction_completed':
      case 'ticket_reserved':
      case 'ticket_released':
        await _navigateToTransactionDetails(data);
        break;
      
      default:
        _logger.error('Type de notification non géré: $type');
    }
  }

  /// Naviguer vers les détails de transaction
  Future<void> _navigateToTransactionDetails(Map<String, dynamic> data) async {
    final zoneId = data['zoneId'];
    final zoneName = data['zoneName'] ?? 'Zone';
    final transactionId = data['transactionId'];
    
    if (zoneId == null || transactionId == null) {
      _logger.error('Données manquantes pour la navigation', 
          data: data);
      return;
    }

    try {
      // Naviguer vers la page des transactions
      await Get.toNamed(
        '/zones/$zoneId/transactions',
        arguments: {
          'zoneId': zoneId,
          'zoneName': zoneName,
          'targetTransactionId': transactionId, // Ajouter l'ID cible
        },
      );

      // Attendre un peu que la page soit chargée
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Essayer d'ouvrir automatiquement le BottomSheet
      await _openTransactionBottomSheet(transactionId);
      
    } catch (e) {
      _logger.error('Erreur lors de la navigation vers la transaction', 
          error: e);
      
      // Fallback: aller au dashboard
      Get.offAllNamed('/dashboard');
    }
  }

  /// Ouvrir le BottomSheet pour une transaction spécifique
  Future<void> _openTransactionBottomSheet(String transactionId) async {
    try {
      // Tenter de récupérer le contrôleur des transactions de zone
      final controller = Get.find<dynamic>();
      
      if (controller.runtimeType.toString().contains('ZoneTransactions')) {
        _logger.info('🎯 Contrôleur trouvé, recherche de la transaction: $transactionId');
        
        // Vérifier si le contrôleur a une méthode pour trouver une transaction
        final transactions = controller.transactions;
        if (transactions != null) {
          // Chercher la transaction dans la liste
          final transaction = transactions.firstWhereOrNull(
            (t) => t.id == transactionId
          );
          
          if (transaction != null) {
            _logger.info('🎯 Transaction trouvée, ouverture du BottomSheet');
            // Appeler la méthode d'affichage des détails
            controller.showTransactionDetails(transaction);
          } else {
            _logger.error('Transaction $transactionId non trouvée dans la liste');
            // Si pas trouvée, recharger les transactions et réessayer
            await controller.refreshTransactions();
            await Future.delayed(const Duration(milliseconds: 500));
            
            final refreshedTransaction = transactions.firstWhereOrNull(
              (t) => t.id == transactionId
            );
            
            if (refreshedTransaction != null) {
              controller.showTransactionDetails(refreshedTransaction);
            }
          }
        }
      } else {
        _logger.error('Contrôleur de transactions non trouvé: ${controller.runtimeType}');
      }
      
    } catch (e) {
      _logger.error('Erreur lors de l\'ouverture du BottomSheet', error: e);
    }
  }

  /// Obtenir la couleur selon le type de notification
  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'transaction_failed':
        return Colors.red.shade600;
      case 'transaction_completed':
        return Colors.green.shade600;
      case 'ticket_reserved':
        return Colors.blue.shade600;
      case 'ticket_released':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Obtenir l'icône selon le type de notification
  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'transaction_failed':
        return Icons.error;
      case 'transaction_completed':
        return Icons.check_circle;
      case 'ticket_reserved':
        return Icons.lock;
      case 'ticket_released':
        return Icons.lock_open;
      default:
        return Icons.notifications;
    }
  }

  /// Envoyer une notification de test
  Future<void> sendTestNotification() async {
    _logger.info('📤 Envoi de notification de test');
    
    Get.snackbar(
      'Notification Test',
      'Service de notifications opérationnel !',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Supprimer le token FCM lors de la déconnexion
  Future<void> clearFCMToken() async {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId != null) {
        await _merchantService.removeFCMToken(userId);
        fcmToken.value = '';
        _logger.info('🗑️ Token FCM supprimé lors de la déconnexion');
      }
    } catch (e) {
      _logger.error('Erreur lors de la suppression du token FCM', error: e);
    }
  }

  @override
  void onClose() {
    _logger.info('🔔 Service de notifications fermé');
    super.onClose();
  }
}