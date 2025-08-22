// lib/features/zones/views/zone_details_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_info_card.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_stats_overview.dart';
import 'package:dnet_buy/features/zones/views/widgets/ticket_type_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';

class ZoneDetailsPage extends GetView<ZoneDetailsController> {
  const ZoneDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Le contrôleur est injecté via le routing avec le zoneId
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.zone.value == null) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de la zone
                ZoneInfoCard(zone: controller.zone.value!),

                const SizedBox(height: AppConstants.defaultPadding * 1.5),

                // Statistiques rapides
                Obx(() => controller.zoneStats.isNotEmpty
                    ? ZoneStatsOverview(stats: controller.zoneStats)
                    : const SizedBox.shrink()),

                const SizedBox(height: AppConstants.defaultPadding * 1.5),

                // Section des types de tickets
                _buildTicketTypesSection(),

                const SizedBox(height: AppConstants.defaultPadding * 1.5),

                // Section des transactions (lien vers page dédiée)
                _buildTransactionsLinkSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.zone.value?.name ?? 'Chargement...',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (controller.zone.value != null)
                Text(
                  controller.zone.value!.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: controller.zone.value!.isActive
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
            ],
          )),
      actions: [
        // Menu d'actions
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier la zone'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Obx(() => ListTile(
                    leading: Icon(
                      controller.zone.value?.isActive == true
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    title: Text(
                      controller.zone.value?.isActive == true
                          ? 'Désactiver la zone'
                          : 'Activer la zone',
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: controller.goToAddTicketType,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau Forfait'),
      backgroundColor: Get.theme.primaryColor,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Zone non trouvée',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette zone n\'existe pas ou vous n\'y avez pas accès',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Forfaits WiFi',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Row(
                  children: [
                    Text(
                      'Filtre: ',
                      style: Get.textTheme.bodySmall,
                    ),
                    DropdownButton<String>(
                      value: controller.selectedFilter.value,
                      onChanged: (value) =>
                          controller.updateFilter(value ?? 'all'),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tous'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Actifs'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactifs'),
                        ),
                      ],
                    ),
                  ],
                )),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _buildTicketTypesList(),
      ],
    );
  }

  Widget _buildTicketTypesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.ticketTypes.isEmpty) {
        return _buildEmptyTicketsState();
      }

      if (controller.filteredTicketTypes.isEmpty) {
        return _buildNoTicketsResultsState();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredTicketTypes.length,
        itemBuilder: (context, index) {
          final ticketType = controller.filteredTicketTypes[index];
          return TicketTypeListItem(
            ticketType: ticketType,
            onTap: () => controller.goToTicketTypeDetails(ticketType.id),
            onToggleStatus: (newStatus) =>
                controller.toggleTicketTypeStatus(ticketType.id, newStatus),
            onDelete: () => controller.deleteTicketType(ticketType.id),
            onEdit: () => controller.editTicketType(ticketType.id),
          );
        },
      );
    });
  }

  Widget _buildEmptyTicketsState() {
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
            onPressed: controller.goToAddTicketType,
            icon: const Icon(Icons.add),
            label: const Text('Créer un forfait'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTicketsResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun forfait trouvé',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun forfait ne correspond au filtre sélectionné',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => controller.updateFilter('all'),
            icon: const Icon(Icons.clear),
            label: const Text('Afficher tous les forfaits'),
          ),
        ],
      ),
    );
  }

  // Widget _buildEmptyTicketTypesState() {
  //   return Container(
  //     padding: const EdgeInsets.all(32),
  //     child: Column(
  //       children: [
  //         Icon(
  //           Icons.receipt_long,
  //           size: 80,
  //           color: Colors.grey.shade400,
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Aucun forfait créé',
  //           style: Get.textTheme.headlineSmall?.copyWith(
  //             color: Colors.grey.shade600,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Créez votre premier forfait WiFi pour cette zone',
  //           style: Get.textTheme.bodyMedium?.copyWith(
  //             color: Colors.grey.shade500,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 24),
  //         ElevatedButton.icon(
  //           onPressed: controller.goToAddTicketType,
  //           icon: const Icon(Icons.add),
  //           label: const Text('Créer un forfait'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNoResultsState() {
  //   return Container(
  //     padding: const EdgeInsets.all(32),
  //     child: Column(
  //       children: [
  //         Icon(
  //           Icons.filter_list_off,
  //           size: 80,
  //           color: Colors.grey.shade400,
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Aucun forfait trouvé',
  //           style: Get.textTheme.headlineSmall?.copyWith(
  //             color: Colors.grey.shade600,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Aucun forfait ne correspond au filtre sélectionné',
  //           style: Get.textTheme.bodyMedium?.copyWith(
  //             color: Colors.grey.shade500,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 16),
  //         TextButton.icon(
  //           onPressed: () => controller.updateFilter('all'),
  //           icon: const Icon(Icons.clear),
  //           label: const Text('Afficher tous les forfaits'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTransactionsLinkSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Consultez toutes les transactions de cette zone',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques rapides
          _buildQuickTransactionStats(),
          
          const SizedBox(height: 16),
          
          // Bouton pour aller à la page des transactions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToTransactionsPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Voir toutes les transactions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTransactionStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStat(
              'Total',
              '---', // Placeholder - sera chargé dynamiquement
              Icons.receipt,
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.blue.shade200,
          ),
          Expanded(
            child: _buildQuickStat(
              'Succès',
              '---', // Placeholder
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.blue.shade200,
          ),
          Expanded(
            child: _buildQuickStat(
              'Revenus',
              '--- XAF', // Placeholder
              Icons.payments,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _goToTransactionsPage() {
    final zoneName = controller.zone.value?.name ?? 'Zone';
    
    // Navigation vers la page des transactions
    Get.toNamed(
      '/zones/${controller.zoneId}/transactions',
      arguments: {
        'zoneId': controller.zoneId,
        'zoneName': zoneName,
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        controller.editZone();
        break;
      case 'toggle_status':
        final currentStatus = controller.zone.value?.isActive ?? false;
        controller.toggleZoneStatus(!currentStatus);
        break;
      case 'refresh':
        controller.refreshData();
        break;
    }
  }
}
