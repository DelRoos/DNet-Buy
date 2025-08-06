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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        // En-tête avec titre et filtres
        Row(
          children: [
            Expanded(
              child: Text(
                'Forfaits WiFi',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildFilterButtons(),
          ],
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Liste des types de tickets
        Obx(() => _buildTicketTypesList()),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Obx(() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip('Tous', 'all'),
        const SizedBox(width: 8),
        _buildFilterChip('Actifs', 'active'),
        const SizedBox(width: 8),
        _buildFilterChip('Inactifs', 'inactive'),
      ],
    ));
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: controller.selectedFilter.value == value,
      onSelected: (selected) {
        if (selected) {
          controller.updateFilter(value);
        }
      },
      selectedColor: Get.theme.primaryColor.withOpacity(0.2),
      checkmarkColor: Get.theme.primaryColor,
    );
  }

  Widget _buildTicketTypesList() {
    final filteredTicketTypes = controller.filteredTicketTypes;

    if (controller.ticketTypes.isEmpty) {
      return _buildEmptyTicketTypesState();
    }

    if (filteredTicketTypes.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTicketTypes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ticketType = filteredTicketTypes[index];
        return TicketTypeListItem(
          ticketType: ticketType,
          onTap: () => controller.goToTicketTypeDetails(ticketType.id),
          onCopyLink: () => controller.copyPaymentLink(ticketType.id),
          onToggleStatus: (newStatus) => controller.toggleTicketTypeStatus(ticketType.id, newStatus),
          onDelete: () => controller.deleteTicketType(ticketType.id),
        );
      },
    );
  }

  Widget _buildEmptyTicketTypesState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun forfait créé',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier forfait WiFi pour cette zone',
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

  Widget _buildNoResultsState() {
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