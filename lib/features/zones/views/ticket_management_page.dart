import 'package:dnet_buy/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
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

  // Vue pour la gestion d'un type de ticket spécifique
  Widget _buildTicketTypeManagementView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTicketTypeInfo(),
          const SizedBox(height: AppConstants.defaultPadding * 1.5),
          _buildTicketsImportSection(),
          const SizedBox(height: AppConstants.defaultPadding * 1.5),
          _buildTicketsList(),
        ],
      ),
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
              subtitle: Text(FormatUtils.formatValidityHours(ticketType.validityHours)),
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


  // Liste des tickets importés
  Widget _buildTicketsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tickets Importés',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding / 2),
        Obx(() {
          if (controller.tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
                child: Text(
                  'Aucun ticket importé',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
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
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Utilisateur: ${ticket.username}'),
                  subtitle: Text('Mot de passe: ${ticket.password}'),
                  trailing: Chip(
                    label: Text(
                      ticket.status == 'sold' ? 'Vendu' : 'Disponible',
                    ),
                    backgroundColor: ticket.status == 'sold'
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    labelStyle: TextStyle(
                      color: ticket.status == 'sold'
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
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
