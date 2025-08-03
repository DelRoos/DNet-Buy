import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';
import 'package:dnet_buy/app/services/auth_service.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';

class SettingsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  final MerchantService _merchantService = Get.find<MerchantService>();

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
    super.onInit();
    loadUserSettings();
  }

  Future<void> loadUserSettings() async {
    try {
      isLoading.value = true;
      
      final merchantData = _authController.merchantData.value;
      if (merchantData != null) {
        nameController.text = merchantData['name'] ?? '';
        emailController.text = merchantData['email'] ?? '';
        phoneController.text = merchantData['phone'] ?? '';
        supportPhoneController.text = merchantData['supportPhone'] ?? '';
        callbackUrlController.text = merchantData['callbackUrl'] ?? '';
        
        // Les clés API sont chiffrées, ne pas les afficher directement
        appKeyController.text = '••••••••••••••••';
        secretKeyController.text = '••••••••••••••••';
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les paramètres');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePersonalInfo() async {
    if (!personalInfoFormKey.currentState!.validate()) return;

    try {
      isSavingPersonalInfo.value = true;
      
      final uid = _authController.currentUser.value?.uid;
      if (uid == null) return;

      final data = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'supportPhone': supportPhoneController.text.trim(),
      };

      await _merchantService.updatePersonalInfo(uid, data);
      Get.snackbar('Succès', 'Informations mises à jour avec succès');
      
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isSavingPersonalInfo.value = false;
    }
  }

  Future<void> changePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;

    try {
      isChangingPassword.value = true;

      await _authService.updatePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      // Nettoyer les champs
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();

      Get.snackbar('Succès', 'Mot de passe modifié avec succès');
      
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isChangingPassword.value = false;
    }
  }

  Future<void> saveApiKeys() async {
    if (!apiKeysFormKey.currentState!.validate()) return;

    try {
      isSavingApiKeys.value = true;
      
      final uid = _authController.currentUser.value?.uid;
      if (uid == null) return;

      // En production, chiffrer les clés avant de les sauvegarder
      final keys = {
        'appKey': appKeyController.text.trim(),
        'secretKey': secretKeyController.text.trim(),
      };

      await _merchantService.updateApiKeys(uid, keys);
      Get.snackbar('Succès', 'Clés API mises à jour avec succès');
      
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isSavingApiKeys.value = false;
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