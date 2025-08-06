// lib/features/zones/controllers/zones_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/zone_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';

class ZonesController extends GetxController {
  final ZoneService _zoneService = Get.find<ZoneService>();
  final LoggerService _logger = LoggerService.to;

  // États réactifs
  var isLoading = true.obs;
  var zones = <ZoneModel>[].obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'all'.obs; // all, active, inactive
  var stats = RxMap<String, dynamic>({});

  // Getters pour les zones filtrées
  List<ZoneModel> get filteredZones {
    var filteredList = zones.where((zone) {
      // Filtre par recherche
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!zone.name.toLowerCase().contains(query) &&
            !zone.description.toLowerCase().contains(query) &&
            !zone.routerType.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtre par statut
      switch (selectedFilter.value) {
        case 'active':
          return zone.isActive;
        case 'inactive':
          return !zone.isActive;
        default:
          return true;
      }
    }).toList();

    return filteredList;
  }

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 ZonesController initialisé', category: 'CONTROLLER');
    fetchZones();
    fetchStats();
  }

  // Récupérer toutes les zones
  Future<void> fetchZones() async {
    try {
      isLoading.value = true;
      _logger.debug('Récupération des zones', category: 'ZONES_CONTROLLER');

      final fetchedZones = await _zoneService.getZones();
      zones.assignAll(fetchedZones);

      _logger.info('✅ ${fetchedZones.length} zones chargées',
          category: 'ZONES_CONTROLLER',
          data: {'count': fetchedZones.length});

    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des zones',
          error: e, stackTrace: stackTrace, category: 'ZONES_CONTROLLER');
      
      Get.snackbar(
        'Erreur',
        'Impossible de charger les zones: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Récupérer les statistiques
  Future<void> fetchStats() async {
    try {
      _logger.debug('Récupération des statistiques des zones');
      
      final fetchedStats = await _zoneService.getZoneStats();
      stats.assignAll(fetchedStats);

      _logger.info('✅ Statistiques des zones chargées',
          category: 'ZONES_CONTROLLER');

    } catch (e) {
      _logger.error('Erreur lors du chargement des statistiques',
          error: e, category: 'ZONES_CONTROLLER');
    }
  }

  // Navigation vers l'ajout d'une zone
  void goToAddZone() {
    _logger.logNavigation('/dashboard/zones/add');
    Get.toNamed('/dashboard/zones/add');
  }

  // Navigation vers les détails d'une zone
  void goToZoneDetails(String zoneId) {
    _logger.logUserAction('view_zone_details', details: {'zoneId': zoneId});
    _logger.logNavigation('/dashboard/zones/$zoneId', params: {'zoneId': zoneId});
    Get.toNamed('/dashboard/zones/$zoneId');
  }

  // Basculer le statut d'une zone
  Future<void> toggleZoneStatus(String zoneId, bool newStatus) async {
    try {
      _logger.debug('Changement du statut de la zone: $zoneId -> $newStatus');

      await _zoneService.toggleZoneStatus(zoneId, newStatus);
      
      // Mettre à jour localement
      final zoneIndex = zones.indexWhere((z) => z.id == zoneId);
      if (zoneIndex != -1) {
        zones[zoneIndex] = zones[zoneIndex].copyWith(
          isActive: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      Get.snackbar(
        'Succès',
        'Statut de la zone ${newStatus ? 'activé' : 'désactivé'}',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Rafraîchir les statistiques
      fetchStats();

    } catch (e, stackTrace) {
      _logger.error('Erreur lors du changement de statut',
          error: e, stackTrace: stackTrace, category: 'ZONES_CONTROLLER');
      
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Supprimer une zone
  Future<void> deleteZone(String zoneId) async {
    try {
      // Confirmation
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette zone ?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _logger.debug('Suppression de la zone: $zoneId');

      await _zoneService.deleteZone(zoneId);
      
      // Retirer de la liste locale
      zones.removeWhere((z) => z.id == zoneId);

      Get.snackbar(
        'Succès',
        'Zone supprimée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Rafraîchir les statistiques
      fetchStats();

    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la suppression',
          error: e, stackTrace: stackTrace, category: 'ZONES_CONTROLLER');
      
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la zone: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _logger.debug('Recherche mise à jour: $query', category: 'ZONES_CONTROLLER');
  }

  // Filtre
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    _logger.debug('Filtre mis à jour: $filter', category: 'ZONES_CONTROLLER');
  }

  // Rafraîchissement pull-to-refresh
  Future<void> refreshZones() async {
    _logger.debug('Rafraîchissement des zones', category: 'ZONES_CONTROLLER');
    await fetchZones();
    await fetchStats();
  }

  // Écouter les changements en temps réel
  void startRealtimeListener() {
    _logger.debug('Démarrage du listener temps réel des zones');
    
    _zoneService.watchZones().listen(
      (updatedZones) {
        zones.assignAll(updatedZones);
        _logger.debug('Zones mises à jour via stream: ${updatedZones.length}');
      },
      onError: (error) {
        _logger.error('Erreur dans le stream des zones',
            error: error, category: 'ZONES_CONTROLLER');
      },
    );
  }

  @override
  void onClose() {
    _logger.debug('ZonesController fermé', category: 'ZONES_CONTROLLER');
    super.onClose();
  }
}