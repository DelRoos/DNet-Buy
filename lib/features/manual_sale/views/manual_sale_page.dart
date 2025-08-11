import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/manual_sale/controllers/manual_sale_controller.dart';
import 'package:dnet_buy/features/zones/models/ticket_model.dart';

class ManualSalePage extends GetView<ManualSaleController> {
  final List<TicketModel> availableTickets;

  const ManualSalePage({
    Key? key,
    required this.availableTickets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(ManualSaleController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vente manuelle de tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: controller.clearResults,
            tooltip: 'Effacer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildTicketSelection(),
            const SizedBox(height: 24),
            Obx(() => _buildSaleForm()),
            const SizedBox(height: 24),
            Obx(() => _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Vente manuelle de tickets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Sélectionnez un ticket disponible\n'
              '• Entrez le numéro du client\n'
              '• Ajoutez une description (optionnel)\n'
              '• Les identifiants seront automatiquement copiés',
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSelection() {
    final availableOnly =
        availableTickets.where((t) => t.status == 'available').toList();

    if (availableOnly.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Aucun ticket disponible',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionner un ticket à vendre:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: availableOnly.map((ticket) {
              return Obx(() => ListTile(
                    title: Text('${ticket.username}'),
                    subtitle: Text('Mot de passe: ${ticket.password}'),
                    trailing: controller.selectedTicket.value?.id == ticket.id
                        ? Icon(Icons.check_circle, color: Colors.green.shade600)
                        : const Icon(Icons.radio_button_unchecked),
                    selected: controller.selectedTicket.value?.id == ticket.id,
                    onTap: () => controller.selectTicket(ticket),
                  ));
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleForm() {
    if (controller.selectedTicket.value == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de vente',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Ticket sélectionné
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.confirmation_number,
                        color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ticket sélectionné: ${controller.selectedTicket.value!.username}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Mot de passe: ${controller.selectedTicket.value!.password}',
                            style: TextStyle(color: Colors.green.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: controller.deselectTicket,
                      icon: const Icon(Icons.close),
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Numéro de téléphone
              TextFormField(
                controller: controller.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone du client *',
                  hintText: '+237XXXXXXXXX ou 6XXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: controller.validatePhoneNumber,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Ex: Vente en magasin, client fidèle...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 500,
                validator: controller.validateDescription,
              ),
              const SizedBox(height: 16),

              // Bouton de vente
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      controller.isLoading.value ? null : controller.sellTicket,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sell),
                  label: Text(controller.isLoading.value
                      ? 'Vente en cours...'
                      : 'Vendre le ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = controller.lastSaleResult.value;
    if (result == null || !result.isSuccess) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Vente réussie!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow('Transaction ID:', result.transactionId!),
            _buildResultRow('Forfait:', result.ticketInfo!.planName),
            _buildResultRow('Montant:', result.ticketInfo!.formattedAmount),
            _buildResultRow('Client:', result.ticketInfo!.phoneNumber),
            _buildResultRow('Date:', _formatDate(result.ticketInfo!.saleDate)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Identifiants du client:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nom d\'utilisateur: ${result.credentials!.username}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mot de passe: ${result.credentials!.password}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.copyCredentials,
                icon: const Icon(Icons.copy),
                label: const Text('Copier les identifiants'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
