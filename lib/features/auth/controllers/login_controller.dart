import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';

class LoginController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;

  // Getters pour l'état de chargement
  bool get isLoading => _authController.isLoading.value;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> loginUser() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await _authController.signIn(
      email: emailController.text.trim(),
      password: passwordController.text,
    );
  }

  Future<void> forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      Get.snackbar('Erreur', 'Veuillez saisir votre email');
      return;
    }

    await _authController.resetPassword(emailController.text.trim());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
