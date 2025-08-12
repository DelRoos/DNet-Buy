import 'package:dnet_buy/features/zones/models/ticket_model.dart';
import 'package:dnet_buy/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/dashboard/views/widgets/stat_card.dart';
import 'package:dnet_buy/features/zones/controllers/ticket_management_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/ticket_type_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';

class TicketManagementPage extends GetView<TicketManagementController> {
  const TicketManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() =>
            Text(controller.ticketType.value?.name ?? 'Gestion des Tickets')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si un type de ticket spécifique est sélectionné
        if (controller.ticketTypeId != null &&
            controller.ticketType.value != null) {
          return _buildTicketTypeManagementView();
        }

        // Sinon, afficher la liste des types de tickets
        if (controller.ticketTypes.isEmpty) {
          return _buildEmptyState();
        }

        return _buildTicketTypesListView();
      }),
      floatingActionButton: controller.ticketTypeId == null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTicketTypeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau Forfait'),
            )
          : null,
    );
  }

  // Informations sur le type de ticket
  Widget _buildTicketTypeInfo() {
    final ticketType = controller.ticketType.value!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du forfait',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ListTile(
              title: const Text('Description'),
              subtitle: Text(ticketType.description),
            ),
            const Divider(),
            ListTile(
              title: const Text('Prix'),
              subtitle: Text('${ticketType.price} XAF'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Validité'),
              subtitle: Text(
                  FormatUtils.formatValidityHours(ticketType.validityHours)),
            ),
            ListTile(
              title: const Text('Vitesse de téléchargement'),
              subtitle: ticketType.rateLimit != null
                  ? Text(ticketType.rateLimit!)
                  : const Text('Aucune limite définie'),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Ajouter après les boutons existants
                TextButton.icon(
                  onPressed: controller.copyPublicTicketLink,
                  icon: const Icon(Icons.share, color: Colors.blue),
                  label: const Text('Copier Lien Public'),
                ),
                TextButton.icon(
                  onPressed: () => controller.editTicketType(ticketType.id),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => controller.toggleTicketTypeStatus(
                      ticketType.id, !ticketType.isActive),
                  icon: Icon(
                    ticketType.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: ticketType.isActive ? Colors.orange : Colors.green,
                  ),
                  label: Text(ticketType.isActive ? 'Désactiver' : 'Activer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section d'importation de tickets
  Widget _buildTicketsImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Importer des Tickets',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uploadez ici un fichier CSV ou Excel (XLS/XLSX) contenant les tickets',
            ),
            const SizedBox(height: 16),
            Obx(
              () => CustomButton(
                text: 'Choisir un fichier (CSV, XLS, XLSX)',
                icon: Icons.upload_file,
                isLoading: controller.isUploading.value,
                onPressed: controller.pickAndUploadCsv,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Améliorer l'affichage des tickets pour montrer les ventes manuelles
  Widget _buildTicketsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tickets (${controller.tickets.length})',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() {
              final availableCount = controller.tickets
                  .where((t) => t.status == 'available')
                  .length;
              final soldCount =
                  controller.tickets.where((t) => t.status == 'used').length;

              return Chip(
                label: Text('$availableCount dispo • $soldCount vendus'),
                backgroundColor: Colors.blue.shade100,
                labelStyle: TextStyle(color: Colors.blue.shade800),
              );
            }),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding / 2),
        Obx(() {
          if (controller.tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
                child: Column(
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun ticket importé',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Importez des tickets via CSV pour commencer les ventes',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.tickets.length,
            itemBuilder: (context, index) {
              final ticket = controller.tickets[index];
              return _buildTicketCard(ticket);
            },
          );
        }),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'used':
        return Colors.orange;
      case 'reserved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'used':
        return Icons.sell;
      case 'reserved':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'used':
        return 'Vendu';
      case 'reserved':
        return 'Réservé';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
// Dans la méthode _buildTicketTypeManagementView, ajouter un bouton pour la vente manuelle

  Widget _buildTicketActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.goToManualSale,
                    icon: const Icon(Icons.sell),
                    label: const Text('Vente manuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickAndUploadCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importer CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Mise à jour de la méthode _showTicketDetails
  void _showTicketDetails(TicketModel ticket) {
    Get.dialog(
      SelectionArea(
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                _getStatusIcon(ticket.status),
                color: _getStatusColor(ticket.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket.isAvailable ? 'Ticket disponible' : 'Détails du ticket',
                  style: TextStyle(
                    color: _getStatusColor(ticket.status),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: Get.width * 0.9,
            child: SingleChildScrollView(
              child: Obx(() {
                // Si on est en mode vente manuelle pour ce ticket
                if (controller.selectedTicketForSale.value?.id == ticket.id) {
                  return _buildManualSaleForm(ticket);
                }
        
                // Sinon, afficher les détails normaux
                return _buildTicketDetails(ticket);
              }),
            ),
          ),
          actions: _buildDialogActions(ticket),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

// Construire les détails du ticket
  Widget _buildTicketDetails(TicketModel ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Informations de base
        _buildDetailSection(
          'Informations du ticket',
          [
            _buildDetailRow('Nom d\'utilisateur', ticket.username),
            _buildDetailRow('Mot de passe', ticket.password),
            _buildDetailRow('Statut', ticket.statusDisplay),
            _buildDetailRow('Créé le', _formatDate(ticket.createdAt)),
          ],
        ),

        // Informations de vente (si vendu)
        if (ticket.isSold) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Informations de vente',
            [
              if (ticket.soldAt != null)
                _buildDetailRow('Vendu le', _formatDate(ticket.soldAt!)),
              if (ticket.buyerPhoneNumber != null)
                _buildDetailRow('Numéro client', ticket.buyerPhoneNumber!),
              if (ticket.saleType != null)
                _buildDetailRow('Type de vente', ticket.saleTypeDisplay),
              if (ticket.paymentReference != null)
                _buildDetailRow('Référence paiement', ticket.paymentReference!),
              if (ticket.transactionId != null)
                _buildDetailRow('Transaction ID', ticket.transactionId!),
            ],
          ),
        ],

        // Informations administratives (vente manuelle)
        if (ticket.isManualSale) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Informations administratives',
            [
              if (ticket.saleDescription != null &&
                  ticket.saleDescription!.isNotEmpty)
                _buildDetailRow('Description', ticket.saleDescription!),
              if (ticket.adminUserId != null)
                _buildDetailRow('Vendu par', ticket.adminUserId!),
            ],
          ),
        ],

        // Informations d'utilisation
        if (ticket.firstUsedAt != null) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Informations d\'utilisation',
            [
              _buildDetailRow(
                  'Première utilisation', _formatDate(ticket.firstUsedAt!)),
            ],
          ),
        ],
      ],
    );
  }

// Construire le formulaire de vente manuelle
  Widget _buildManualSaleForm(TicketModel ticket) {
    return Form(
      key: controller.manualSaleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informations du ticket sélectionné
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket sélectionné pour la vente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Utilisateur: ${ticket.username}'),
                Text('Mot de passe: ${ticket.password}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formulaire de vente
          Text(
            'Informations de vente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),

          // Numéro de téléphone
          TextFormField(
            controller: controller.manualSalePhoneController,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone du client *',
              hintText: '+237XXXXXXXXX ou 6XXXXXXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
            validator: controller.validatePhoneNumber,
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: controller.manualSaleDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              hintText: 'Ex: Vente en magasin, client fidèle...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              isDense: true,
            ),
            maxLines: 2,
            maxLength: 500,
            validator: controller.validateDescription,
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les identifiants seront automatiquement copiés après la vente',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Construire les actions du dialog
  List<Widget> _buildDialogActions(TicketModel ticket) {
    return [
      // Bouton Annuler/Fermer
      TextButton(
        onPressed: () {
          controller.closeManualSaleForm();
          Get.back();
        },
        child: Text(controller.selectedTicketForSale.value?.id == ticket.id
            ? 'Annuler'
            : 'Fermer'),
      ),

      // Actions selon l'état
      if (controller.selectedTicketForSale.value?.id == ticket.id) ...[
        // Mode vente manuelle - Bouton vendre
        Obx(() => ElevatedButton.icon(
              onPressed: controller.isSellingManually.value
                  ? null
                  : controller.sellTicketManually,
              icon: controller.isSellingManually.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sell),
              label: Text(
                  controller.isSellingManually.value ? 'Vente...' : 'Vendre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            )),
      ] else ...[
        // Mode normal - Actions selon le statut du ticket
        if (ticket.isAvailable)
          ElevatedButton.icon(
            onPressed: () => controller.openManualSaleForm(ticket),
            icon: const Icon(Icons.sell),
            label: const Text('Vendre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),

        if (ticket.isSold)
          ElevatedButton.icon(
            onPressed: () {
              final credentials =
                  'Nom d\'utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}';
              Clipboard.setData(ClipboardData(text: credentials));
              Get.back();
              Get.snackbar(
                'Copié!',
                'Les identifiants ont été copiés dans le presse-papiers',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green.shade100,
                colorText: Colors.green.shade800,
                duration: const Duration(seconds: 2),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    ];
  }

// Mettre à jour _buildTicketCard pour permettre le clic sur tous les tickets
  Widget _buildTicketCard(TicketModel ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(ticket.status),
          child: Icon(
            _getStatusIcon(ticket.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Utilisateur: ${ticket.username}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mot de passe: ${ticket.password}'),
            if (ticket.isSold && ticket.soldAt != null)
              Text(
                'Vendu le ${_formatDate(ticket.soldAt!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            if (ticket.buyerPhoneNumber != null)
              Text(
                'Client: ${ticket.buyerPhoneNumber}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            if (ticket.saleDescription != null &&
                ticket.saleDescription!.isNotEmpty)
              Text(
                'Note: ${ticket.saleDescription}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(ticket.statusDisplay),
              backgroundColor: _getStatusColor(ticket.status).withOpacity(0.1),
              labelStyle: TextStyle(
                color: _getStatusColor(ticket.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (ticket.isManualSale)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MANUEL',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (ticket.isOnlineSale)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EN LIGNE',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        // Permettre le clic sur tous les tickets (disponibles et vendus)
        onTap: () => _showTicketDetails(ticket),
      ),
    );
  }

// // Modifier la méthode _buildTicketTypeManagementView pour inclure les actions
  Widget _buildTicketTypeManagementView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketTypeInfo(),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildTicketActions(), // Ajouter cette ligne
          const SizedBox(height: AppConstants.defaultPadding),
          _buildTicketsImportSection(),
          const SizedBox(height: AppConstants.defaultPadding * 1.5),
          _buildTicketsList(),
        ],
      ),
    );
  }

  // Vue pour la liste des types de tickets
  Widget _buildTicketTypesListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: AppConstants.defaultPadding * 1.5),
          _buildTicketTypesSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun forfait disponible',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier forfait WiFi',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTicketTypeDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Créer un forfait'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Statistiques calculées à partir des types de tickets
    final totalTicketTypes = controller.ticketTypes.length;
    final activeTicketTypes =
        controller.ticketTypes.where((t) => t.isActive).length;
    final inactiveTicketTypes = totalTicketTypes - activeTicketTypes;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppConstants.defaultPadding / 2,
      mainAxisSpacing: AppConstants.defaultPadding / 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          icon: Icons.all_inclusive,
          value: totalTicketTypes.toString(),
          label: 'Total',
          color: Colors.blue,
        ),
        StatCard(
          icon: Icons.check_circle_outline,
          value: activeTicketTypes.toString(),
          label: 'Actifs',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.pause_circle_outline,
          value: inactiveTicketTypes.toString(),
          label: 'Inactifs',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTicketTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forfaits WiFi',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),

        // Liste des types de tickets
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.ticketTypes.length,
          itemBuilder: (context, index) {
            final ticketType = controller.ticketTypes[index];
            return TicketTypeListItem(
              ticketType: ticketType,
              onTap: () => _showTicketTypeDetailsDialog(ticketType),
              onToggleStatus: (newStatus) =>
                  controller.toggleTicketTypeStatus(ticketType.id, newStatus),
              onDelete: () => controller.deleteTicketType(ticketType.id),
              onEdit: () => controller.editTicketType(ticketType.id),
            );
          },
        ),
      ],
    );
  }

  // Afficher la boîte de dialogue des détails du type de ticket
  void _showTicketTypeDetailsDialog(ticketType) {
    Get.dialog(
      AlertDialog(
        title: Text(ticketType.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${ticketType.description}'),
              const SizedBox(height: 8),
              Text('Prix: ${ticketType.price} XAF'),
              const SizedBox(height: 8),
              Text(
                  'Validité: ${FormatUtils.formatValidityHours(ticketType.validityHours)}'),
              const SizedBox(height: 8),
              if (ticketType.rateLimit != null &&
                  ticketType.rateLimit!.isNotEmpty)
                Text('Débit: ${ticketType.rateLimit}'),
              if (ticketType.downloadLimit != null &&
                  ticketType.downloadLimit! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      'Limite de téléchargement: ${ticketType.downloadLimit} MB'),
                ),
              if (ticketType.uploadLimit != null && ticketType.uploadLimit! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Limite d\'envoi: ${ticketType.uploadLimit} MB'),
                ),
              if (ticketType.sessionTimeLimit != null &&
                  ticketType.sessionTimeLimit! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      'Limite de session: ${ticketType.sessionTimeLimit} minutes'),
                ),
              if (ticketType.notes != null && ticketType.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Notes: ${ticketType.notes}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.editTicketType(ticketType.id);
            },
            child: const Text('Modifier'),
          ),
          // Ajouter après les boutons existants
          TextButton.icon(
            onPressed: controller.copyPublicTicketLink,
            icon: const Icon(Icons.share, color: Colors.blue),
            label: const Text('Copier Lien Public'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Naviguer vers la gestion des tickets pour ce type
              Get.toNamed(
                  '/dashboard/zones/${controller.zoneId}/tickets/${ticketType.id}/manage');
            },
            child: const Text('Gérer les tickets'),
          ),
        ],
      ),
    );
  }

  // Afficher la boîte de dialogue pour ajouter un type de ticket
  void _showAddTicketTypeDialog() {
    // Rediriger vers la page d'ajout de type de ticket
    Get.toNamed('/dashboard/zones/${controller.zoneId}/tickets/add',
        arguments: {
          'zoneId': controller.zoneId,
        });
  }
}
