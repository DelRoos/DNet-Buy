// lib/features/zones/views/add_ticket_type_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/add_ticket_type_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class AddTicketTypePage extends GetView<AddTicketTypeController> {
  const AddTicketTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Le contrôleur est injecté via le routing avec le zoneId
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Forfait WiFi'),
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
              _buildHeader(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildBasicInfoSection(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildPricingSection(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildValiditySection(),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              _buildAdvancedSettingsSection(),
              const SizedBox(height: AppConstants.defaultPadding * 3),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.receipt_long,
          size: 64,
          color: Get.theme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Nouveau Forfait',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configurez un nouveau type de ticket WiFi',
          style: Get.textTheme.bodyMedium?.copyWith(
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
              labelText: 'Nom du forfait *',
              hintText: 'ex: Pass Journée',
              prefixIcon: Icons.label,
              validator: controller.validateName,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: controller.descriptionController,
              labelText: 'Description *',
              hintText: 'ex: Accès WiFi illimité pendant 24 heures',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: controller.validateDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarification',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            CustomTextField(
              controller: controller.priceController,
              labelText: 'Prix (F CFA) *',
              hintText: '1000',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: controller.validatePrice,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Prix suggérés',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: controller.pricePresets.map((price) {
                return ActionChip(
                  label: Text('$price F'),
                  onPressed: () => controller.selectPricePreset(price),
                  backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValiditySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durée de validité',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Affichage de la validité actuelle
            CustomTextField(
              controller: controller.validityController,
              labelText: 'Validité',
              prefixIcon: Icons.schedule,
              readOnly: true,
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Slider pour ajuster les heures
            Obx(() => Column(
              children: [
                Text(
                  'Durée: ${controller.validityHours.value} heure(s)',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Slider(
                  value: controller.validityHours.value.toDouble(),
                  min: 1,
                  max: 720, // 30 jours
                  divisions: 100,
                  label: '${controller.validityHours.value}h',
                  onChanged: (value) {
                    controller.validityHours.value = value.toInt();
                  },
                ),
              ],
            )),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            Text(
              'Durées populaires',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: controller.validityPresets.map((preset) {
                return Obx(() => FilterChip(
                  label: Text(preset['label']),
                  selected: controller.validityHours.value == preset['hours'],
                  onSelected: (selected) {
                    if (selected) {
                      controller.selectValidityPreset(preset);
                    }
                  },
                  selectedColor: Get.theme.primaryColor.withOpacity(0.2),
                ));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres avancés',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.expirationAfterCreationController,
                    labelText: 'Expiration après création (jours)',
                    hintText: '30',
                    prefixIcon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    validator: controller.validateExpiration,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: CustomTextField(
                    controller: controller.nbMaxUtilisationsController,
                    labelText: 'Utilisations max',
                    hintText: '1',
                    prefixIcon: Icons.repeat,
                    keyboardType: TextInputType.number,
                    validator: controller.validateMaxUsages,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Switch pour activer/désactiver
            Obx(() => SwitchListTile(
              title: const Text('Forfait actif'),
              subtitle: Text(
                controller.isActive.value 
                    ? 'Le forfait sera disponible à la vente'
                    : 'Le forfait sera désactivé',
              ),
              value: controller.isActive.value,
              onChanged: controller.toggleIsActive,
              activeColor: Get.theme.primaryColor,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => CustomButton(
        text: 'Créer le Forfait',
        isLoading: controller.isLoading.value,
        onPressed: controller.saveTicketType,
        icon: Icons.save,
      ),
    );
  }
}