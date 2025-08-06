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
    // Le contrôleur est injecté via bindings ou Get.put
    if (!Get.isRegistered<AddTicketTypeController>()) {
      Get.put(AddTicketTypeController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value
            ? 'Modifier le Forfait'
            : 'Ajouter un Forfait')),
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
                _buildPricingSection(),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                // _buildLimitsSection(),
                // const SizedBox(height: AppConstants.defaultPadding * 2),
                // _buildNotesSection(),
                // const SizedBox(height: AppConstants.defaultPadding * 3),
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
          Icons.confirmation_number,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Obx(() => Text(
              controller.isEditMode.value
                  ? 'Modifier le Forfait'
                  : 'Nouveau Forfait',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            )),
        const SizedBox(height: 8),
        Obx(() => Text(
              controller.isEditMode.value
                  ? 'Mettez à jour les détails de ce forfait WiFi'
                  : 'Configurez un nouveau type de ticket WiFi',
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

            // Prix
            CustomTextField(
              controller: controller.priceController,
              labelText: 'Prix (XAF) *',
              hintText: 'ex: 500',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: controller.validatePrice,
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Durée de validité
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.validityDaysController,
                    labelText: 'Validité (heures) *',
                    hintText: 'ex: 10',
                    prefixIcon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    validator: controller.validateValidityDays,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: DropdownButton<int>(
                    hint: const Text('Options'),
                    onChanged: (value) {
                      if (value != null) {
                        controller.validityDaysController.text =
                            value.toString();
                      }
                    },
                    items: controller.validityOptions.map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text(days == 1 ? '$days jour' : '$days jours'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limites (optionnel)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Définissez des limites d\'utilisation pour ce forfait',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Limite de téléchargement
            Row(
              children: [
                Obx(() => Switch(
                      value: controller.hasDownloadLimit.value,
                      onChanged: (value) =>
                          controller.hasDownloadLimit.value = value,
                      activeColor: Get.theme.primaryColor,
                    )),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => CustomTextField(
                        controller: controller.downloadLimitController,
                        labelText: 'Limite téléchargement (MB)',
                        hintText: 'ex: 1000',
                        prefixIcon: Icons.download,
                        keyboardType: TextInputType.number,
                        readOnly: controller.hasDownloadLimit.value,
                        validator: controller.validateDownloadLimit,
                      )),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Limite d'envoi
            Row(
              children: [
                Obx(() => Switch(
                      value: controller.hasUploadLimit.value,
                      onChanged: (value) =>
                          controller.hasUploadLimit.value = value,
                      activeColor: Get.theme.primaryColor,
                    )),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => CustomTextField(
                        controller: controller.uploadLimitController,
                        labelText: 'Limite envoi (MB)',
                        hintText: 'ex: 500',
                        prefixIcon: Icons.upload,
                        keyboardType: TextInputType.number,
                        readOnly: controller.hasUploadLimit.value,
                        validator: controller.validateUploadLimit,
                      )),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Limite de temps de session
            Row(
              children: [
                Obx(() => Switch(
                      value: controller.hasSessionTimeLimit.value,
                      onChanged: (value) =>
                          controller.hasSessionTimeLimit.value = value,
                      activeColor: Get.theme.primaryColor,
                    )),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => CustomTextField(
                        controller: controller.sessionTimeController,
                        labelText: 'Limite de session (minutes)',
                        hintText: 'ex: 120',
                        prefixIcon: Icons.timer,
                        keyboardType: TextInputType.number,
                        readOnly: controller.hasSessionTimeLimit.value,
                        validator: controller.validateSessionTimeLimit,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (optionnel)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des notes internes sur ce forfait',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                hintText: 'ex: Forfait promotionnel pour la saison touristique',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => CustomButton(
          onPressed: controller.saveTicketType,
          isLoading: controller.isLoading.value,
          text: controller.isEditMode.value
              ? 'Mettre à jour le forfait'
              : 'Créer le forfait',
          icon: controller.isEditMode.value ? Icons.save : Icons.add,
        ));
  }
}
