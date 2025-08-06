import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/ticket_retrieval/controllers/ticket_retrieval_controller.dart';
import 'package:dnet_buy/features/portal/views/widgets/ticket_details_dialog.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';

class TicketRetrievalPage extends GetView<TicketRetrievalController> {
  const TicketRetrievalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(TicketRetrievalController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récupérer mon ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Text(
              'Retrouvez votre ticket',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez l\'identifiant de transaction qui vous a été fourni lors de l\'achat.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Formulaire
            _buildRetrievalForm(context),
            const SizedBox(height: 32),

            // Résultat
            Obx(() => _buildResultSection(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrievalForm(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.transactionIdController,
            decoration: const InputDecoration(
              labelText: 'ID de transaction',
              hintText: 'Entrez l\'ID reçu par SMS ou affiché après l\'achat',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.receipt),
            ),
            validator: controller.validateTransactionId,
            enabled: controller.status.value != RetrievalStatus.loading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.status.value == RetrievalStatus.loading
                      ? null
                      : controller.retrieveTicket,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: controller.status.value == RetrievalStatus.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Rechercher'),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    switch (controller.status.value) {
      case RetrievalStatus.idle:
        return const SizedBox();

      case RetrievalStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );

      case RetrievalStatus.error:
        return _buildErrorMessage(context);

      case RetrievalStatus.success:
        return _buildTicketResult(context);
    }
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Ticket non trouvé',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: controller.resetForm,
            child: const Text('Réessayer avec un autre ID'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketResult(BuildContext context) {
    final ticket = controller.retrievedTicket.value!;
    final isExpired = ticket.isExpired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Ticket trouvé!',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations du ticket
          Text(
            ticket.ticketTypeName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isExpired ? 'Expiré' : 'Actif',
              style: TextStyle(
                color: isExpired ? Colors.red.shade800 : Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Identifiants
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Identifiants de connexion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCredentialRow('Utilisateur', ticket.username),
                  const SizedBox(height: 8),
                  _buildCredentialRow('Mot de passe', ticket.password),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _copyCredentials(context, ticket),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier les identifiants'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.resetForm,
                  child: const Text('Nouvelle recherche'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showTicketDetails(context, ticket),
                  child: const Text('Détails complets'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:'),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  void _copyCredentials(BuildContext context, ticket) {
    final credentials =
        'Utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}';
    Clipboard.setData(ClipboardData(text: credentials));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identifiants copiés dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, ticket) {
    showDialog(
      context: context,
      builder: (context) => TicketDetailsDialog(ticket: ticket),
    );
  }
}
