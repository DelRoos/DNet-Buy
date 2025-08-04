import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/portal/controllers/portal_controller.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

void showPaymentPopup(BuildContext context, TicketTypeModel ticketType) {
  final PortalController controller = Get.find();

  Get.defaultDialog(
    title: 'Finaliser votre achat',
    content: Obx(() {
      switch (controller.paymentStatus.value) {
        case PaymentStatus.idle:
          return _buildIdleView(context, ticketType, controller);
        case PaymentStatus.pending:
          return _buildPendingView(context, controller);
        case PaymentStatus.success:
          return _buildSuccessView(context, controller);
        case PaymentStatus.failed:
          return _buildFailedView(context, controller);
      }
    }),
    barrierDismissible: false,
  );
}

Widget _buildIdleView(
  BuildContext context,
  TicketTypeModel ticketType,
  PortalController controller,
) {
  return Column(
    children: [
      Text('Forfait: ${ticketType.name} - ${ticketType.price} XAF'),
      const SizedBox(height: 16),
      Obx(() {
        final errorText = !controller.isPhoneNumberValid.value &&
                controller.phoneController.text.isNotEmpty
            ? 'Numéro camerounais invalide'
            : null;

        return TextField(
          controller: controller.phoneController,
          decoration: InputDecoration(
            labelText: 'Votre numéro de téléphone',
            prefixText: '+237 ',
            errorText: errorText,
          ),
          keyboardType: TextInputType.phone,
          autofocus: true,
        );
      }),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () => controller.resetPayment(),
            child: const Text('Annuler'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isPhoneNumberValid.value
                  ? () => controller.initiatePayment(ticketType)
                  : null,
              child: const Text('Payer'),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildPendingView(BuildContext context, PortalController controller) {
  return Column(
    children: [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(controller.paymentMessage.value, textAlign: TextAlign.center),
    ],
  );
}

Widget _buildSuccessView(BuildContext context, PortalController controller) {
  return Column(
    children: [
      const Icon(Icons.check_circle, color: Colors.green, size: 50),
      const SizedBox(height: 16),
      Text(
        controller.paymentMessage.value,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Utilisateur: ${controller.finalTicket.value!.username}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Mot de passe: ${controller.finalTicket.value!.password}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: controller.resetPayment,
        child: const Text('Fermer'),
      ),
    ],
  );
}

Widget _buildFailedView(BuildContext context, PortalController controller) {
  return Column(
    children: [
      const Icon(Icons.error, color: Colors.red, size: 50),
      const SizedBox(height: 16),
      Text(controller.paymentMessage.value, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: controller.resetPayment,
        child: const Text('Fermer'),
      ),
    ],
  );
}
