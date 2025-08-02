import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final appKeyController = TextEditingController();
  final secretKeyController = TextEditingController();
  final callbackUrlController = TextEditingController();

  var isLoading = false.obs;

  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> registerUser() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    isLoading.value = true;
    print('Simulation de la création du compte...');
    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;
    print('Compte créé avec succès (simulation).');

    Get.snackbar(
      'Succès',
      'Votre compte a été créé. Veuillez vous connecter.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.offNamed('/login');
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    appKeyController.dispose();
    secretKeyController.dispose();
    callbackUrlController.dispose();
    super.onClose();
  }
}
