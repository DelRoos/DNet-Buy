import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/settings/controllers/settings_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres du Compte')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildSectionCard(
                title: 'Informations Personnelles',
                formKey: controller.personalInfoFormKey,
                children: [
                  CustomTextField(
                    controller: controller.nameController,
                    labelText: "Nom de l'entreprise",
                    validator: (v) => Validators.validateNotEmpty(v, 'Nom'),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.emailController,
                    labelText: "Email de contact",
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.phoneController,
                    labelText: "Téléphone principal",
                    validator: Validators.validateCameroonianPhoneNumber,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.supportPhoneController,
                    labelText: "Téléphone du support client",
                    validator: Validators.validateCameroonianPhoneNumber,
                    keyboardType: TextInputType.phone,
                  ),
                ],
                saveButton: Obx(
                  () => CustomButton(
                    text: 'Enregistrer les modifications',
                    isLoading: controller.isSavingPersonalInfo.value,
                    onPressed: controller.savePersonalInfo,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSectionCard(
                title: 'Changer de Mot de Passe',
                formKey: controller.passwordFormKey,
                children: [
                  CustomTextField(
                    controller: controller.currentPasswordController,
                    labelText: 'Mot de passe actuel',
                    obscureText: true,
                    validator: (v) => Validators.validateNotEmpty(
                      v,
                      'Mot de passe actuel',
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.newPasswordController,
                    labelText: 'Nouveau mot de passe',
                    obscureText: true,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.confirmNewPasswordController,
                    labelText: 'Confirmer le nouveau mot de passe',
                    obscureText: true,
                    validator: (v) {
                      if (v != controller.newPasswordController.text)
                        return 'Les mots de passe ne correspondent pas.';
                      return null;
                    },
                  ),
                ],
                saveButton: Obx(
                  () => CustomButton(
                    text: 'Changer le mot de passe',
                    isLoading: controller.isChangingPassword.value,
                    onPressed: controller.changePassword,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSectionCard(
                title: 'Configuration API Freemopay',
                formKey: controller.apiKeysFormKey,
                children: [
                  Obx(
                    () => CustomTextField(
                      controller: controller.appKeyController,
                      labelText: 'Merchant App Key',
                      obscureText: !controller.areApiKeysVisible.value,
                      validator: (v) =>
                          Validators.validateNotEmpty(v, 'App Key'),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Obx(
                    () => CustomTextField(
                      controller: controller.secretKeyController,
                      labelText: 'Merchant Secret Key',
                      obscureText: !controller.areApiKeysVisible.value,
                      validator: (v) =>
                          Validators.validateNotEmpty(v, 'Secret Key'),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomTextField(
                    controller: controller.callbackUrlController,
                    labelText: 'Callback URL',
                    validator: (v) =>
                        Validators.validateNotEmpty(v, 'Callback URL'),
                    keyboardType: TextInputType.url,
                  ),
                  Obx(
                    () => SwitchListTile.adaptive(
                      title: const Text('Afficher les clés'),
                      value: controller.areApiKeysVisible.value,
                      onChanged: (val) => controller.toggleApiKeysVisibility(),
                    ),
                  ),
                ],
                saveButton: Obx(
                  () => CustomButton(
                    text: 'Enregistrer les clés API',
                    isLoading: controller.isSavingApiKeys.value,
                    onPressed: controller.saveApiKeys,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Widget helper pour construire une section
  Widget _buildSectionCard({
    required String title,
    required GlobalKey<FormState> formKey,
    required List<Widget> children,
    required Widget saveButton,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              ...children,
              const SizedBox(height: AppConstants.defaultPadding),
              saveButton,
            ],
          ),
        ),
      ),
    );
  }
}
