import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/auth_service.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final MerchantService _merchantService = Get.find<MerchantService>();

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
    _initAuthListener();
  }

  // Écouter les changements d'authentification
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      currentUser.value = user;

      if (user != null) {
        await _loadMerchantData(user.uid);
        _handleUserStateChange(user);
      }
      //  else {
      //   merchantData.value = null;
      //   Get.offAllNamed('/login');
      // }
    });
  }

  // Charger les données du marchand
  Future<void> _loadMerchantData(String uid) async {
    try {
      final data = await _merchantService.getMerchantData(uid);
      merchantData.value = data;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données utilisateur');
    }
  }

  // Gérer les changements d'état utilisateur
  void _handleUserStateChange(User user) {
    final currentRoute = Get.currentRoute;

    // Ne pas rediriger si on est déjà sur la bonne page
    if (currentRoute == '/dashboard' ||
        currentRoute == '/email-verification' ||
        currentRoute.startsWith('/dashboard/')) {
      return;
    }

    if (!user.emailVerified) {
      Get.offAllNamed('/email-verification');
    } else {
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
    try {
      isLoading.value = true;

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

      Get.snackbar(
        'Succès',
        'Compte créé ! Vérifiez votre email pour l\'activer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Connexion
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      Get.snackbar('Déconnexion', 'Vous avez été déconnecté avec succès.');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    }
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _authService.resetPassword(email);
      Get.snackbar(
        'Email envoyé',
        'Vérifiez votre boîte mail pour réinitialiser votre mot de passe.',
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Renvoyer email de vérification
  Future<void> resendEmailVerification() async {
    try {
      isLoading.value = true;
      await _authService.sendEmailVerification();
      Get.snackbar('Email envoyé', 'Email de vérification renvoyé.');
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Recharger l'état utilisateur
  Future<void> refreshUser() async {
    try {
      await _authService.reloadUser();
      // Forcer la mise à jour
      currentUser.value = FirebaseAuth.instance.currentUser;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de rafraîchir les données.');
    }
  }
}
