import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/zones_controller.dart';

class AddZoneController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final routerTypeController = TextEditingController();

  var isLoading = false.obs;

  Future<void> saveZone() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));

      print('Nouvelle zone sauvegardée : ${nameController.text}');
      isLoading.value = false;

      Get.back();
      Get.find<ZonesController>().fetchZones();
      Get.snackbar('Succès', 'La zone "${nameController.text}" a été ajoutée.');
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    routerTypeController.dispose();
    super.onClose();
  }
}
