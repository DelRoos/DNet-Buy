import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/auth/controllers/register_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class RegisterPage extends GetView<RegisterController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RegisterController());

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
                  Image.asset('assets/images/logo.png', height: 60),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Center(
                    child: Text(
                      'Créer votre compte DNet',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),

                  CustomTextField(
                    controller: controller.nameController,
                    labelText: "Nom de l'entreprise",
                    validator: (val) => Validators.validateNotEmpty(val, 'Nom'),
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.emailController,
                    labelText: "Adresse Email",
                    validator: Validators.validateEmail,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.phoneController,
                    labelText: "Numéro de téléphone",
                    validator: Validators.validateCameroonianPhoneNumber,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Obx(
                    () => CustomTextField(
                      controller: controller.passwordController,
                      labelText: "Mot de passe",
                      obscureText: !controller.isPasswordVisible.value,
                      validator: Validators.validatePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Obx(
                    () => CustomTextField(
                      controller: controller.confirmPasswordController,
                      labelText: "Confirmer le mot de passe",
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      validator: (val) {
                        if (val != controller.passwordController.text) {
                          return 'Les mots de passe ne correspondent pas.';
                        }
                        return null;
                      },
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  const Divider(height: 30),

                  CustomTextField(
                    controller: controller.appKeyController,
                    labelText: "Freemopay App Key",
                    validator:
                        (val) => Validators.validateNotEmpty(val, 'App Key'),
                    prefixIcon: Icons.vpn_key_outlined,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.secretKeyController,
                    labelText: "Freemopay Secret Key",
                    validator:
                        (val) => Validators.validateNotEmpty(val, 'Secret Key'),
                    prefixIcon: Icons.vpn_key_outlined,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.callbackUrlController,
                    labelText: "Callback URL",
                    validator:
                        (val) =>
                            Validators.validateNotEmpty(val, 'Callback URL'),
                    prefixIcon: Icons.link_outlined,
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: AppConstants.defaultPadding * 2),

                  Obx(
                    () => CustomButton(
                      text: "S'inscrire",
                      isLoading: controller.isLoading,
                      onPressed: controller.registerUser,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),

                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: "Vous avez déjà un compte ? "),
                          TextSpan(
                            text: 'Connectez-vous',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Get.back(),
                          ),
                        ],
                      ),
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