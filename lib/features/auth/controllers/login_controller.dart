import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;

  var isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> loginUser() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    print('Simulation de la requête de connexion...');
    await Future.delayed(const Duration(seconds: 2));
    print('Réponse reçue.');

    Get.offAllNamed("/dashboard");

    isLoading.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
