import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';

class RegisterController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final appKeyController = TextEditingController();
  final secretKeyController = TextEditingController();
  final callbackUrlController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  // Getters pour l'état de chargement
  bool get isLoading => _authController.isLoading.value;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> registerUser() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await _authController.signUp(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text,
      appKey: appKeyController.text.trim(),
      secretKey: secretKeyController.text.trim(),
      callbackUrl: callbackUrlController.text.trim(),
    );
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
