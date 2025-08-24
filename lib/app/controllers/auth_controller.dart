import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/auth_service.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/app/services/notification_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final MerchantService _merchantService = Get.find<MerchantService>();
  final LoggerService _logger = LoggerService.to;

  // États réactifs
  var isLoading = false.obs;
  var currentUser = Rx<User?>(null);
  var merchantData = Rx<Map<String, dynamic>?>(null);

  // Getters
  bool get isLoggedIn => currentUser.value != null;
  bool get isEmailVerified => currentUser.value?.emailVerified ?? false;
  String get userName => merchantData.value?['name'] ?? '';
  String get userEmail => currentUser.value?.email ?? '';

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 AuthController initialisé');
    _initAuthListener();
  }

  // Écouter les changements d'authentification
  void _initAuthListener() {
    _logger.debug('Configuration de l\'écouteur d\'authentification');

    _authService.authStateChanges.listen((User? user) async {
      _logger.logEvent('auth_state_changed', {
        'userId': user?.uid,
        'email': user?.email,
        'emailVerified': user?.emailVerified,
        'isAnonymous': user?.isAnonymous,
        'creationTime': user?.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String(),
      });

      currentUser.value = user;

      if (user != null) {
        _logger.info('👤 Utilisateur connecté: ${user.email}');

        try {
          await _loadMerchantData(user.uid);
          _handleUserStateChange(user);
        } catch (e, stackTrace) {
          _logger.error(
            'Erreur lors du chargement des données après connexion',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      // else {
      //   _logger.info('👤 Utilisateur déconnecté');
      //   merchantData.value = null;
      //   // Décommentez si vous voulez forcer la redirection
      //   // Get.offAllNamed('/login');
      // }
    });
  }

  // Charger les données du marchand
  Future<void> _loadMerchantData(String uid) async {
    _logger.debug('Chargement des données marchand pour UID: $uid');

    try {
      final data = await _merchantService.getMerchantData(uid);
      merchantData.value = data;

      _logger.info('✅ Données marchand chargées avec succès',
          category: 'DATA',
          data: {
            'uid': uid,
            'merchantName': data?['name'],
            'hasApiKeys': data?['appKey'] != null,
          });
    } catch (e, stackTrace) {
      _logger.error(
        'Impossible de charger les données marchand',
        error: e,
        stackTrace: stackTrace,
        category: 'DATA',
      );
      Get.snackbar('Erreur', 'Impossible de charger les données utilisateur');
    }
  }

  // Gérer les changements d'état utilisateur
  void _handleUserStateChange(User user) {
    final currentRoute = Get.currentRoute;

    _logger.debug('Gestion du changement d\'état utilisateur',
        category: 'NAVIGATION',
        data: {
          'currentRoute': currentRoute,
          'emailVerified': user.emailVerified,
          'userId': user.uid,
        });

    // Ne pas rediriger si on est déjà sur la bonne page
    if (currentRoute == '/dashboard' ||
        currentRoute == '/email-verification' ||
        currentRoute.startsWith('/dashboard/')) {
      _logger.debug('Déjà sur la bonne route, pas de redirection nécessaire');
      return;
    }

    if (!user.emailVerified) {
      _logger.logNavigation('/email-verification', params: {
        'reason': 'email_not_verified',
        'userEmail': user.email,
      });
      Get.offAllNamed('/email-verification');
    } else {
      _logger.logNavigation('/dashboard', params: {
        'reason': 'user_authenticated',
        'userEmail': user.email,
      });
      Get.offAllNamed('/dashboard');
    }
  }

  // Inscription
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String appKey,
    required String secretKey,
    required String callbackUrl,
  }) async {
    _logger.logUserAction('signup_attempt', details: {
      'email': email,
      'name': name,
      'phone': phone,
      'hasAppKey': appKey.isNotEmpty,
      'hasSecretKey': secretKey.isNotEmpty,
      'callbackUrl': callbackUrl,
    });

    try {
      isLoading.value = true;
      _logger.debug('Début du processus d\'inscription pour $email');

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'appKey': appKey,
        'secretKey': secretKey,
        'callbackUrl': callbackUrl,
      };

      await _authService.signUp(
        email: email,
        password: password,
        userData: userData,
      );

      _logger.info('✅ Inscription réussie', category: 'AUTH', data: {
        'email': email,
        'name': name,
      });

      _logger.logUserAction('signup_success', details: {
        'email': email,
      });

      Get.snackbar(
        'Succès',
        'Compte créé ! Vérifiez votre email pour l\'activer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Échec de l\'inscription',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
        data: {
          'email': email,
          'errorMessage': e.toString(),
        },
      );

      _logger.logUserAction('signup_failed', details: {
        'email': email,
        'error': e.toString(),
      });

      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
      _logger.debug('Fin du processus d\'inscription');
    }
  }

  // Connexion
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _logger.logUserAction('signin_attempt', details: {
      'email': email,
    });

    try {
      isLoading.value = true;
      _logger.debug('Tentative de connexion pour $email');

      await _authService.signIn(email: email, password: password);

      _logger.info('✅ Connexion réussie', category: 'AUTH', data: {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.logUserAction('signin_success', details: {
        'email': email,
      });
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Échec de la connexion',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
        data: {
          'email': email,
          'errorMessage': e.toString(),
        },
      );

      _logger.logUserAction('signin_failed', details: {
        'email': email,
        'error': e.toString(),
      });

      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
      _logger.debug('Fin de la tentative de connexion');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _logger.logUserAction('signout_attempt', details: {
      'email': userEmail,
      'userName': userName,
    });

    try {
      _logger.debug('Déconnexion de l\'utilisateur: $userEmail');

      // Supprimer le token FCM avant la déconnexion
      try {
        if (Get.isRegistered<NotificationService>()) {
          final notificationService = Get.find<NotificationService>();
          await notificationService.clearFCMToken();
          _logger.info('🗑️ Token FCM supprimé lors de la déconnexion');
        }
      } catch (e) {
        _logger.error('Erreur lors de la suppression du token FCM', error: e);
        // Continuer la déconnexion même si la suppression du token échoue
      }

      await _authService.signOut();
      Get.offAllNamed('/login');
      _logger.info('✅ Déconnexion réussie', category: 'AUTH', data: {
        'email': userEmail,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.logUserAction('signout_success', details: {
        'email': userEmail,
      });

      Get.snackbar('Déconnexion', 'Vous avez été déconnecté avec succès.');
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Erreur lors de la déconnexion',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
      );

      Get.snackbar('Erreur', e.toString());
    }
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    _logger.logUserAction('password_reset_attempt', details: {
      'email': email,
    });

    try {
      isLoading.value = true;
      _logger.debug('Demande de réinitialisation de mot de passe pour $email');

      await _authService.resetPassword(email);

      _logger
          .info('✅ Email de réinitialisation envoyé', category: 'AUTH', data: {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.logUserAction('password_reset_sent', details: {
        'email': email,
      });

      Get.snackbar(
        'Email envoyé',
        'Vérifiez votre boîte mail pour réinitialiser votre mot de passe.',
      );
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Erreur lors de la réinitialisation du mot de passe',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
        data: {
          'email': email,
        },
      );

      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Renvoyer email de vérification
  Future<void> resendEmailVerification() async {
    _logger.logUserAction('email_verification_resend', details: {
      'email': userEmail,
    });

    try {
      isLoading.value = true;
      _logger.debug('Renvoi de l\'email de vérification pour $userEmail');

      await _authService.sendEmailVerification();

      _logger.info('✅ Email de vérification renvoyé', category: 'AUTH', data: {
        'email': userEmail,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Get.snackbar('Email envoyé', 'Email de vérification renvoyé.');
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Erreur lors du renvoi de l\'email de vérification',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
      );

      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Recharger l'état utilisateur
  Future<void> refreshUser() async {
    _logger.debug('Rafraîchissement des données utilisateur');

    try {
      await _authService.reloadUser();
      // Forcer la mise à jour
      currentUser.value = FirebaseAuth.instance.currentUser;

      _logger
          .info('✅ Données utilisateur rafraîchies', category: 'AUTH', data: {
        'email': currentUser.value?.email,
        'emailVerified': currentUser.value?.emailVerified,
        'uid': currentUser.value?.uid,
      });

      _logger.logEvent('user_data_refreshed', {
        'email': currentUser.value?.email,
        'emailVerified': currentUser.value?.emailVerified,
      });
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Impossible de rafraîchir les données utilisateur',
        error: e,
        stackTrace: stackTrace,
        category: 'AUTH',
      );

      Get.snackbar('Erreur', 'Impossible de rafraîchir les données.');
    }
  }

  @override
  void onClose() {
    _logger.info('🔚 AuthController fermé');
    super.onClose();
  }
}
