import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/portal/controllers/portal_controller.dart';

class PortalPage extends GetView<PortalController> {
  const PortalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(controller.ticketTypeDetails.value?.name ??
              'Acheter un forfait')),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                switch (controller.pageStatus.value) {
                  case PaymentPageStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case PaymentPageStatus.idle:
                    return _buildInitialView();
                  case PaymentPageStatus.checking:
                    return _buildPendingView("Vérification...");
                  case PaymentPageStatus.pending:
                    return _buildPendingView(
                        "Paiement en attente. Veuillez valider sur votre téléphone.");
                  case PaymentPageStatus.fetchingCredentials:
                    return _buildPendingView(
                        "Récupération de vos identifiants..."); // ✅ NOUVEAU CAS
                  case PaymentPageStatus.outOfStock:
                    return _buildOutOfStockView();
                  case PaymentPageStatus.success:
                    return _buildSuccessView();
                  case PaymentPageStatus.failed:
                    return _buildFailedView();
                }
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Vue initiale avec le formulaire de paiement
  Widget _buildInitialView() {
    final ticket = controller.ticketTypeDetails.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ticket.name,
            style: Get.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(ticket.description, style: Get.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Chip(
            label:
                Text('${ticket.price} XAF', style: Get.textTheme.titleMedium)),
        const SizedBox(height: 32),
        CustomTextField(
          controller: controller.phoneController,
          labelText: "Numéro de téléphone",
          validator: Validators.validateCameroonianPhoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Obx(() => ElevatedButton(
              onPressed: controller.isPhoneNumberValid.value &&
                      controller.pageStatus.value == PaymentPageStatus.idle
                  ? controller.initiatePaymentProcess
                  : null,
              child: const Text('Payer'),
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            )),
      ],
    );
  }

  // Vue pendant l'attente
  Widget _buildPendingView(String message) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(message,
            style: Get.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text("Cette page se mettra à jour automatiquement.",
            style: Get.textTheme.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }

  // Vue en cas de stock épuisé
  Widget _buildOutOfStockView() {
    return Column(
      children: [
        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        Text("Forfait Épuisé",
            style: Get.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            "Désolé, ce forfait n'est plus disponible pour le moment. Veuillez contacter le support par WhatsApp.",
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: () {/* Logique pour ouvrir WhatsApp */},
            icon: const Icon(Icons.chat),
            label: const Text("Contacter le Support")),
      ],
    );
  }

// Vue en cas de succès
  Widget _buildSuccessView() {
    final ticket = controller.finalTicket.value;

    // ✅ VÉRIFIER SI LE TICKET EST DISPONIBLE
    if (ticket == null) {
      return Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text("Récupération de vos identifiants...",
              style: Get.textTheme.titleLarge, textAlign: TextAlign.center),
        ],
      );
    }

    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text("Paiement Réussi !",
            style: Get.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Vos identifiants de connexion :",
                  style: Get.textTheme.titleMedium),
              const SizedBox(height: 16),
              _credentialRow("Utilisateur", ticket.username),
              const SizedBox(height: 8),
              _credentialRow("Mot de passe", ticket.password),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.copyCredentials,
                icon: const Icon(Icons.copy),
                label: const Text("Copier les identifiants"),
              )
            ],
          ),
        )),
        const SizedBox(height: 16),
        Text("En cas d'oubli, retrouvez vos identifiants à tout moment.",
            textAlign: TextAlign.center),
        TextButton(
            onPressed: () => Get.toNamed('/retrieve-ticket'),
            child: const Text("Récupérer mon ticket")),
      ],
    );
  }

  // Vue en cas d'échec
  Widget _buildFailedView() {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text("Paiement Échoué",
            style: Get.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (controller.errorMessage.value.isNotEmpty)
          Text(controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: controller.retryPayment,
          child: const Text("Réessayer"),
        ),
      ],
    );
  }

  // Helper pour afficher une ligne d'identifiant
  Widget _credentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Get.textTheme.bodyLarge),
        Text(value,
            style: Get.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}
