import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';
import 'package:dnet_buy/features/ticket_retrieval/controllers/ticket_retrieval_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/utils/validators.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';
import 'package:dnet_buy/shared/widgets/custom_textfield.dart';

class TicketRetrievalPage extends GetView<TicketRetrievalController> {
  const TicketRetrievalPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(TicketRetrievalController());

    return Scaffold(
      appBar: AppBar(title: const Text('Récupérer mon Ticket')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _buildForm(context),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Obx(() => _buildResultView(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Retrouvez vos identifiants',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez l\'identifiant de la transaction (reçu par SMS ou affiché après le paiement).',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding * 2),
          CustomTextField(
            controller: controller.transactionIdController,
            labelText: 'Identifiant de la transaction',
            hintText: 'ex: a67691ed-3185-4153...',
            validator: (v) => Validators.validateNotEmpty(v, 'Identifiant'),
            prefixIcon: Icons.receipt_long,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Obx(
            () => CustomButton(
              text: 'Rechercher',
              isLoading: controller.searchStatus.value == SearchStatus.loading,
              onPressed: controller.findTicket,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context) {
    switch (controller.searchStatus.value) {
      case SearchStatus.idle:
        return const SizedBox.shrink();
      case SearchStatus.loading:
        return const CircularProgressIndicator();
      case SearchStatus.found:
        return _buildFoundTicketCard(context, controller.foundTicket.value!);
      case SearchStatus.notFound:
        return _buildErrorCard(
          context,
          icon: Icons.search_off,
          title: 'Transaction non trouvée',
          message:
              'Aucun ticket ne correspond à cet identifiant. Veuillez vérifier votre saisie.',
        );
      case SearchStatus.error:
        return _buildErrorCard(
          context,
          icon: Icons.cloud_off,
          title: 'Erreur de Connexion',
          message: controller.errorMessage.value,
        );
    }
  }

  Widget _buildFoundTicketCard(
    BuildContext context,
    PurchasedTicketModel ticket,
  ) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 8),
            Text(
              'Ticket retrouvé !',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Utilisateur', ticket.username),
            const Divider(),
            _buildCredentialRow('Mot de passe', ticket.password),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.resetSearch,
              child: const Text('Faire une autre recherche'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.resetSearch,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCredentialRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      IconButton(
        icon: const Icon(Icons.copy, size: 20),
        tooltip: 'Copier $label',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          Get.rawSnackbar(
            message: '$label copié !',
            snackPosition: SnackPosition.BOTTOM,
            borderRadius: 8,
            margin: const EdgeInsets.all(10),
          );
        },
      ),
    ],
  );
}
