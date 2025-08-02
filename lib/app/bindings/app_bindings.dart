import 'package:get/get.dart';

// Pour la simulation, on va créer un AuthController basique
class AuthController extends GetxController {
  var isLoggedIn = false.obs; // .obs rend la variable réactive

  // Simule une connexion
  Future<void> login(String email, String password) async {
    print('Simulating login for $email...');
    await Future.delayed(const Duration(seconds: 2));
    isLoggedIn.value = true;
    print('Login successful!');
  }

  // Simule une déconnexion
  void logout() {
    isLoggedIn.value = false;
  }
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // On injecte le AuthController pour qu'il soit disponible partout dans l'app
    // lazyPut ne le crée que lorsqu'il est utilisé pour la première fois
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
