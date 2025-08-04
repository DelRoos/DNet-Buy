import 'package:dnet_buy/features/zones/controllers/add_zone_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddZonePage extends GetView<AddZoneController> {
  const AddZonePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddZoneController());

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une Zone WiFi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: controller.nameController,
                labelText: 'Nom de la zone',
                hintText: 'ex: Restaurant - Terrasse',
                validator: (v) =>
                    Validators.validateNotEmpty(v, 'Nom de la zone'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.descriptionController,
                labelText: 'Description',
                hintText: 'ex: Couverture extérieure',
                validator: (v) => Validators.validateNotEmpty(v, 'Description'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.routerTypeController,
                labelText: 'Type de routeur',
                hintText: 'ex: MikroTik hAP ac²',
                validator: (v) =>
                    Validators.validateNotEmpty(v, 'Type de routeur'),
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              Obx(
                () => CustomButton(
                  text: 'Enregistrer la Zone',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.saveZone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
