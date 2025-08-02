import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';

class AddTicketTypeController extends GetxController {
  final String zoneId;
  AddTicketTypeController({required this.zoneId});

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final validityController = TextEditingController();
  final expirationAfterCreationController = TextEditingController();
  final nbMaxUtilisationsController = TextEditingController(
    text: '1',
  );

  var isActive = true.obs;
  var isLoading = false.obs;

  void toggleIsActive(bool value) {
    isActive.value = value;
  }

  Future<void> saveTicketType() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));

      print(
        'Nouveau forfait sauvegardé pour la zone $zoneId : ${nameController.text}',
      );
      isLoading.value = false;

      Get.back();
      Get.find<ZoneDetailsController>().fetchData();
      Get.snackbar(
        'Succès',
        'Le forfait "${nameController.text}" a été ajouté.',
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    validityController.dispose();
    expirationAfterCreationController.dispose();
    nbMaxUtilisationsController.dispose();
    super.onClose();
  }
}
