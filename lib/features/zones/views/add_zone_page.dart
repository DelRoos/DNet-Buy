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
    // Le contrôleur est injecté via bindings ou Get.put
    // On s'assure qu'il est initialisé
    if (!Get.isRegistered<AddZoneController>()) {
      Get.put(AddZoneController());
    }

    return Scaffold(
      appBar: AppBar(
        // Titre dynamique selon le mode
        title: Obx(() => Text(controller.isEditMode.value
            ? 'Modifier la Zone WiFi'
            : 'Ajouter une Zone WiFi')),
        actions: [
          TextButton(
            onPressed: controller.resetForm,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
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
                _buildTagsSection(context),
                const SizedBox(height: AppConstants.defaultPadding * 3),
                _buildSaveButton(),
              ],
            ),
          ),
        );
      }),
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
        Obx(() => Text(
              controller.isEditMode.value
                  ? 'Modifier la Zone WiFi'
                  : 'Nouvelle Zone WiFi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            )),
        const SizedBox(height: 8),
        Obx(() => Text(
              controller.isEditMode.value
                  ? 'Mettez à jour les informations de la zone WiFi'
                  : 'Configurez une nouvelle zone de couverture WiFi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            )),
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
              hintText: 'ex: Zone Cafétéria',
              prefixIcon: Icons.label,
              validator: controller.validateName,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: controller.descriptionController,
              labelText: 'Description *',
              hintText: 'ex: Zone WiFi pour les clients de la cafétéria',
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
              'Équipement',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Dropdown des types de routeurs prédéfinis
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type de routeur *',
                hintText: 'Sélectionnez un type de routeur',
                prefixIcon: Icon(Icons.router),
                border: OutlineInputBorder(),
              ),
              value: controller.selectedRouterType.value.isNotEmpty
                  ? controller.selectedRouterType.value
                  : null,
              items: controller.routerTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedRouterType.value = value;
                }
              },
              validator: (value) {
                return (value == null || value.isEmpty)
                    ? 'Veuillez sélectionner un type de routeur'
                    : null;
              },
            ),

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

// Dans la classe AddZonePage, modifiez la méthode _buildTagsSection()

  Widget _buildTagsSection(BuildContext context) {
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
                    controller: controller.tagController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un tag...',
                      prefixIcon: Icon(Icons.tag),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        controller.addTag(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    if (controller.tagController.text.isNotEmpty) {
                      controller.addTag(controller.tagController.text);
                    }
                  },
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Affichage des tags
            Obx(() => controller.tags.isEmpty
                ? Center(
                    child: Text(
                      'Aucun tag ajouté',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => controller.removeTag(tag),
                              backgroundColor: Colors.grey.shade200,
                            ))
                        .toList(),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      onPressed: controller.saveZone,
      isLoading: controller.isLoading.value,
      text: controller.isEditMode.value
          ? 'Mettre à jour la zone'
          : 'Créer la zone',
      icon: controller.isEditMode.value ? Icons.save : Icons.add,
    );
  }
}
