// lib/features/zones/views/zones_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/zones_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_list_item.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_stats_card.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';

class ZonesPage extends GetView<ZonesController> {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ZonesController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Zones WiFi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshZones,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddZone,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Zone'),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          Expanded(child: _buildZonesList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() => controller.stats.isNotEmpty
        ? ZoneStatsCard(stats: controller.stats)
        : const SizedBox.shrink());
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une zone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: controller.updateSearchQuery,
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Filtres
          Row(
            children: [
              _buildFilterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Actifs', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('Inactifs', 'inactive'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() => FilterChip(
      label: Text(label),
      selected: controller.selectedFilter.value == value,
      onSelected: (selected) {
        if (selected) {
          controller.updateFilter(value);
        }
      },
      selectedColor: Get.theme.primaryColor.withOpacity(0.2),
      checkmarkColor: Get.theme.primaryColor,
    ));
  }

  Widget _buildZonesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredZones = controller.filteredZones;

      if (controller.zones.isEmpty) {
        return _buildEmptyState();
      }

      if (filteredZones.isEmpty) {
        return _buildNoResultsState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshZones,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: filteredZones.length,
          itemBuilder: (context, index) {
            final zone = filteredZones[index];
            return ZoneListItem(
              zone: zone,
              onTap: () => controller.goToZoneDetails(zone.id),
              onToggleStatus: (newStatus) => controller.toggleZoneStatus(zone.id, newStatus),
              onDelete: () => controller.deleteZone(zone.id),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune zone WiFi',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première zone pour commencer',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.goToAddZone,
            icon: const Icon(Icons.add),
            label: const Text('Créer ma première zone'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune zone ne correspond à vos critères',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              controller.updateSearchQuery('');
              controller.updateFilter('all');
            },
            icon: const Icon(Icons.clear),
            label: const Text('Effacer les filtres'),
          ),
        ],
      ),
    );
  }
}