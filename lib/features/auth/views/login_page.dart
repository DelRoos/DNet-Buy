import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/auth/controllers/login_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginController());

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 80),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Bienvenue sur DNet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Connectez-vous à votre espace marchand',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  CustomTextField(
                    controller: controller.emailController,
                    labelText: 'Adresse Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Obx(
                    () => CustomTextField(
                      controller: controller.passwordController,
                      labelText: 'Mot de passe',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !controller.isPasswordVisible.value,
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Lien mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed('/forgot-password'),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  Obx(
                    () => CustomButton(
                      text: 'Se connecter',
                      isLoading: controller.isLoading,
                      onPressed: controller.loginUser,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: "Vous n'avez pas de compte ? "),
                        TextSpan(
                          text: 'Inscrivez-vous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Get.toNamed('/register'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}