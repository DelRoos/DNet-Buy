import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class ForgotPasswordPage extends GetView<AuthController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  Text(
                    'Réinitialiser votre mot de passe',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Entrez votre adresse email pour recevoir un lien de réinitialisation.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  CustomTextField(
                    controller: emailController,
                    labelText: 'Adresse Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding * 2),
                  Obx(
                    () => CustomButton(
                      text: 'Envoyer le lien',
                      isLoading: controller.isLoading.value,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await controller.resetPassword(
                            emailController.text.trim(),
                          );
                          Get.back();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Retour à la connexion'),
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
