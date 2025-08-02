import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final personalInfoFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  final apiKeysFormKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final supportPhoneController = TextEditingController();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();

  final appKeyController = TextEditingController();
  final secretKeyController = TextEditingController();
  final callbackUrlController = TextEditingController();

  var isLoading = true.obs;
  var isSavingPersonalInfo = false.obs;
  var isChangingPassword = false.obs;
  var isSavingApiKeys = false.obs;

  var areApiKeysVisible = false.obs;

  @override
  void onInit() {
    loadUserSettings();
    super.onInit();
  }

  Future<void> loadUserSettings() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    nameController.text = 'Restaurant Le Gourmet';
    emailController.text = 'gourmet@dnet.com';
    phoneController.text = '699112233';
    supportPhoneController.text = '677445566';
    appKeyController.text = 'app_key_live_xxxxxxxxxxxx';
    secretKeyController.text = 'secret_key_live_xxxxxxxxxxxx';
    callbackUrlController.text = 'https://mon-backend.com/webhook/freemopay';

    isLoading.value = false;
  }


  Future<void> savePersonalInfo() async {
    if (personalInfoFormKey.currentState!.validate()) {
      isSavingPersonalInfo.value = true;
      await Future.delayed(const Duration(seconds: 2));
      isSavingPersonalInfo.value = false;
      Get.snackbar('Succès', 'Informations personnelles mises à jour.');
    }
  }

  Future<void> changePassword() async {
    if (passwordFormKey.currentState!.validate()) {
      isChangingPassword.value = true;
      await Future.delayed(const Duration(seconds: 2));
      isChangingPassword.value = false;

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();
      Get.snackbar('Succès', 'Mot de passe changé avec succès.');
    }
  }

  Future<void> saveApiKeys() async {
    if (apiKeysFormKey.currentState!.validate()) {
      isSavingApiKeys.value = true;
      await Future.delayed(const Duration(seconds: 2));
      isSavingApiKeys.value = false;
      Get.snackbar('Succès', 'Clés API Freemopay mises à jour.');
    }
  }

  void toggleApiKeysVisibility() {
    areApiKeysVisible.value = !areApiKeysVisible.value;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    supportPhoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    appKeyController.dispose();
    secretKeyController.dispose();
    callbackUrlController.dispose();
    super.onClose();
  }
}
