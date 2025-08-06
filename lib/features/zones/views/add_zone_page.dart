// lib/features/zones/views/add_zone_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/add_zone_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class AddZonePage extends GetView<AddZoneController> {
  const AddZonePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddZoneController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Zone WiFi'),
        actions: [
          TextButton(
            onPressed: controller.resetForm,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildBasicInfoSection(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildRouterSection(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildTagsSection(),
              const SizedBox(height: AppConstants.defaultPadding * 3),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.wifi,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Nouvelle Zone WiFi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configurez une nouvelle zone de couverture WiFi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: controller.nameController,
              labelText: 'Nom de la zone *',
              hintText: 'ex: Restaurant - Terrasse',
              prefixIcon: Icons.location_on,
              validator: controller.validateName,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: controller.descriptionController,
              labelText: 'Description *',
              hintText: 'ex: Couverture extérieure près de la fontaine',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: controller.validateDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration routeur',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Sélection du type de routeur
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedRouterType.value.isEmpty 
                  ? null 
                  : controller.selectedRouterType.value,
              decoration: const InputDecoration(
                labelText: 'Type de routeur',
                prefixIcon: Icon(Icons.router),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Sélectionnez un type'),
              items: controller.routerTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                controller.selectedRouterType.value = value ?? '';
              },
            )),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Champ personnalisé si "Autre" est sélectionné
            Obx(() => controller.selectedRouterType.value == 'Autre'
                ? CustomTextField(
                    controller: controller.routerTypeController,
                    labelText: 'Type de routeur personnalisé *',
                    hintText: 'ex: Mon Routeur Custom v2.1',
                    prefixIcon: Icons.settings_input_antenna,
                    validator: controller.validateRouterType,
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags (optionnel)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des mots-clés pour organiser vos zones',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Champ d'ajout de tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un tag...',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      controller.addTag(value);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Affichage des tags
            Obx(() => controller.tags.isEmpty
                ? Text(
                    'Aucun tag ajouté',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: controller.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => controller.removeTag(tag),
                        backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                        deleteIconColor: Get.theme.primaryColor,
                      );
                    }).toList(),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => CustomButton(
        text: 'Créer la Zone WiFi',
        isLoading: controller.isLoading.value,
        onPressed: controller.saveZone,
        icon: Icons.add_location,
      ),
    );
  }
}