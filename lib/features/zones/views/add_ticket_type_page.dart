import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/add_ticket_type_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class AddTicketTypePage extends GetView<AddTicketTypeController> {
  const AddTicketTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Le binding est fait dans les routes, pas besoin de Get.put() ici

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Forfait')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: controller.nameController,
                labelText: 'Nom du forfait',
                hintText: 'ex: Pass Journée',
                validator:
                    (v) => Validators.validateNotEmpty(v, 'Nom du forfait'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.descriptionController,
                labelText: 'Description',
                hintText: 'ex: Accès illimité pendant 24h',
                validator: (v) => Validators.validateNotEmpty(v, 'Description'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.priceController,
                labelText: 'Prix (XAF)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => Validators.validateNotEmpty(v, 'Prix'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.validityController,
                labelText: 'Validité',
                hintText: 'ex: 24 Heures, 7 Jours',
                validator: (v) => Validators.validateNotEmpty(v, 'Validité'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              const Divider(height: 30),
              Text(
                'Paramètres Avancés',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              CustomTextField(
                controller: controller.expirationAfterCreationController,
                labelText: 'Expiration si non utilisé (en jours)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => Validators.validateNotEmpty(v, 'Expiration'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomTextField(
                controller: controller.nbMaxUtilisationsController,
                labelText: 'Nombre max. d\'utilisations',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator:
                    (v) => Validators.validateNotEmpty(
                      v,
                      'Nombre max. d\'utilisations',
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              Obx(
                () => SwitchListTile.adaptive(
                  title: const Text('Activer ce forfait'),
                  subtitle: const Text(
                    'Rend ce forfait visible et achetable par les clients.',
                  ),
                  value: controller.isActive.value,
                  onChanged: controller.toggleIsActive,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding * 2),
              Obx(
                () => CustomButton(
                  text: 'Enregistrer le Forfait',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.saveTicketType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
