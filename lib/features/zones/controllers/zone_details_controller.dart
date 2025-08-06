// lib/features/zones/controllers/zone_details_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/zone_service.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class ZoneDetailsController extends GetxController {
  final String zoneId;
  ZoneDetailsController({required this.zoneId});

  final ZoneService _zoneService = Get.find<ZoneService>();
  final TicketTypeService _ticketTypeService = Get.find<TicketTypeService>();
  final LoggerService _logger = LoggerService.to;

  // États réactifs
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  var zone = Rx<ZoneModel?>(null);
  var ticketTypes = <TicketTypeModel>[].obs;
  var zoneStats = RxMap<String, dynamic>({});
  var selectedFilter = 'all'.obs; // all, active, inactive

  // Getters
  List<TicketTypeModel> get filteredTicketTypes {
    switch (selectedFilter.value) {
      case 'active':
        return ticketTypes.where((tt) => tt.isActive).toList();
      case 'inactive':
        return ticketTypes.where((tt) => !tt.isActive).toList();
      default:
        return ticketTypes.toList();
    }
  }

  bool get hasActiveTicketTypes => ticketTypes.any((tt) => tt.isActive);
  int get totalRevenue =>
      ticketTypes.fold(0, (sum, tt) => sum + (tt.ticketsSold * tt.price));

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 ZoneDetailsController initialisé pour zone: $zoneId',
        category: 'CONTROLLER');
    fetchData();
  }

  // Récupérer toutes les données
  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      _logger.debug('Récupération des données de la zone: $zoneId');

      // Récupérer les données en parallèle
      final results = await Future.wait([
        _zoneService.getZone(zoneId),
        _ticketTypeService.getTicketTypes(zoneId),
      ]);

      zone.value = results[0] as ZoneModel?;
      ticketTypes.assignAll(results[1] as List<TicketTypeModel>);

      if (zone.value == null) {
        throw Exception('Zone non trouvée');
      }

      // Calculer les statistiques
      await _calculateZoneStats();

      _logger.info('✅ Données de la zone chargées',
          category: 'ZONE_DETAILS_CONTROLLER',
          data: {
            'zoneId': zoneId,
            'zoneName': zone.value?.name,
            'ticketTypesCount': ticketTypes.length
          });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des données de la zone',
          error: e,
          stackTrace: stackTrace,
          category: 'ZONE_DETAILS_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rafraîchir les données
  Future<void> refreshData() async {
    isRefreshing.value = true;
    await fetchData();
    isRefreshing.value = false;
  }

// Mettre à jour le filtre
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    _filterTicketTypes();
    _logger.debug('Filtre mis à jour: $filter');
  }

// Filtrer les types de tickets
  void _filterTicketTypes() {
    switch (selectedFilter.value) {
      case 'active':
        filteredTicketTypes.assignAll(ticketTypes.where((t) => t.isActive));
        break;
      case 'inactive':
        filteredTicketTypes.assignAll(ticketTypes.where((t) => !t.isActive));
        break;
      case 'all':
      default:
        filteredTicketTypes.assignAll(ticketTypes);
        break;
    }
  }

  // Calculer les statistiques de la zone
  Future<void> _calculateZoneStats() async {
    try {
      final stats = {
        'totalTicketTypes': ticketTypes.length,
        'activeTicketTypes': ticketTypes.where((tt) => tt.isActive).length,
        'inactiveTicketTypes': ticketTypes.where((tt) => !tt.isActive).length,
        'totalTicketsGenerated':
            ticketTypes.fold(0, (sum, tt) => sum + tt.totalTicketsGenerated),
        'totalTicketsSold':
            ticketTypes.fold(0, (sum, tt) => sum + tt.ticketsSold),
        'totalTicketsAvailable':
            ticketTypes.fold(0, (sum, tt) => sum + tt.ticketsAvailable),
        'totalRevenue': totalRevenue,
        'averagePrice': ticketTypes.isNotEmpty
            ? (ticketTypes.fold(0, (sum, tt) => sum + tt.price) /
                    ticketTypes.length)
                .round()
            : 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      zoneStats.assignAll(stats);

      _logger.debug('Statistiques de la zone calculées',
          category: 'ZONE_DETAILS_CONTROLLER', data: stats);
    } catch (e) {
      _logger.error('Erreur lors du calcul des statistiques',
          error: e, category: 'ZONE_DETAILS_CONTROLLER');
    }
  }

// lib/features/zones/controllers/zone_details_controller.dart
  void goToAddTicketType() {
    _logger.logUserAction('add_ticket_type', details: {
      'zoneId': zoneId,
    });

    _logger.logNavigation('/dashboard/zones/$zoneId/tickets/add', params: {});

    // Utiliser la route définie dans AppPages
    try {
      Get.toNamed('/dashboard/zones/$zoneId/tickets/add', arguments: {
        'zoneId': zoneId,
      });
    } catch (e) {
      _logger.error('Erreur de navigation vers l\'ajout de ticket', error: e);
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la page d\'ajout de forfait',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Navigation vers les détails d'un type de ticket
  void goToTicketTypeDetails(String ticketTypeId) {
    _logger.logUserAction('view_ticket_type_details',
        details: {'zoneId': zoneId, 'ticketTypeId': ticketTypeId});
    _logger.logNavigation('/dashboard/zones/$zoneId/ticket/$ticketTypeId');
    Get.toNamed('/dashboard/zones/$zoneId/tickets/$ticketTypeId/manage');
  }

  // Copier le lien de paiement
  void copyPaymentLink(String ticketTypeId) {
    try {
      // TODO: Récupérer l'ID marchand depuis les services
      const merchantId = 'simulated_merchant_id';

      final paymentUrl = _ticketTypeService.generatePaymentLink(
          zoneId, ticketTypeId, merchantId);

      Clipboard.setData(ClipboardData(text: paymentUrl));

      Get.snackbar(
        'Lien Copié',
        'Le lien de paiement a été copié dans le presse-papiers',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      _logger.logUserAction('payment_link_copied', details: {
        'zoneId': zoneId,
        'ticketTypeId': ticketTypeId,
      });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la copie du lien de paiement',
          error: e,
          stackTrace: stackTrace,
          category: 'ZONE_DETAILS_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de copier le lien',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Basculer le statut d'un type de ticket
  Future<void> toggleTicketTypeStatus(
      String ticketTypeId, bool newStatus) async {
    try {
      _logger.debug(
          'Changement du statut du type de ticket: $ticketTypeId -> $newStatus');

      await _ticketTypeService.toggleTicketTypeStatus(ticketTypeId, newStatus);

      // Mettre à jour localement
      final index = ticketTypes.indexWhere((tt) => tt.id == ticketTypeId);
      if (index != -1) {
        ticketTypes[index] = ticketTypes[index].copyWith(
          isActive: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Recalculer les statistiques
      await _calculateZoneStats();

      Get.snackbar(
        'Succès',
        'Statut du forfait ${newStatus ? 'activé' : 'désactivé'}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du changement de statut du type de ticket',
          error: e,
          stackTrace: stackTrace,
          category: 'ZONE_DETAILS_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
// lib/features/zones/controllers/zone_details_controller.dart

  void editTicketType(String ticketTypeId) {
    // Vérifier que les IDs ne sont pas nuls
    if (ticketTypeId.isEmpty || zoneId.isEmpty) {
      _logger.error(
          'Tentative de modification d\'un ticket avec des IDs invalides',
          error: 'ticketTypeId: $ticketTypeId, zoneId: $zoneId');

      Get.snackbar(
        'Erreur',
        'Impossible de modifier ce forfait, identifiants invalides',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    _logger.logUserAction('edit_ticket_type', details: {
      'ticketTypeId': ticketTypeId,
      'zoneId': zoneId,
    });

    _logger.logNavigation('/dashboard/zones/$zoneId/tickets/$ticketTypeId/edit',
        params: {'zoneId': zoneId, 'ticketTypeId': ticketTypeId});

    // Utiliser arguments plutôt que parameters pour plus de fiabilité
    Get.toNamed(
      '/dashboard/zones/$zoneId/tickets/$ticketTypeId/edit',
      arguments: {
        'zoneId': zoneId,
        'ticketTypeId': ticketTypeId,
      },
    );
  }

  // Supprimer un type de ticket
  Future<void> deleteTicketType(String ticketTypeId) async {
    try {
      // Confirmation
      final ticketType = ticketTypes.firstWhere((tt) => tt.id == ticketTypeId);

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer le forfait "${ticketType.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _logger.debug('Suppression du type de ticket: $ticketTypeId');

      await _ticketTypeService.deleteTicketType(ticketTypeId);

      // Retirer de la liste locale
      ticketTypes.removeWhere((tt) => tt.id == ticketTypeId);

      // Recalculer les statistiques
      await _calculateZoneStats();

      Get.snackbar(
        'Succès',
        'Forfait supprimé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la suppression du type de ticket',
          error: e,
          stackTrace: stackTrace,
          category: 'ZONE_DETAILS_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le forfait: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

//  // Mettre à jour le filtre
//  void updateFilter(String filter) {
//    selectedFilter.value = filter;
//    _logger.debug('Filtre mis à jour: $filter', category: 'ZONE_DETAILS_CONTROLLER');
//  }

  // Basculer le statut de la zone
  Future<void> toggleZoneStatus(bool newStatus) async {
    try {
      _logger.debug('Changement du statut de la zone: $zoneId -> $newStatus');

      await _zoneService.toggleZoneStatus(zoneId, newStatus);

      // Mettre à jour localement
      if (zone.value != null) {
        zone.value = zone.value!.copyWith(
          isActive: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      Get.snackbar(
        'Succès',
        'Statut de la zone ${newStatus ? 'activé' : 'désactivé'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du changement de statut de la zone',
          error: e,
          stackTrace: stackTrace,
          category: 'ZONE_DETAILS_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut de la zone: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Modifier la zone
  void editZone() {
    _logger.logNavigation('/dashboard/zones/$zoneId/edit');
    Get.toNamed('/dashboard/zones/$zoneId/edit');
  }

  // Écouter les changements en temps réel
  void startRealtimeListener() {
    _logger.debug('Démarrage du listener temps réel pour la zone: $zoneId');

    _ticketTypeService.watchTicketTypes(zoneId).listen(
      (updatedTicketTypes) {
        ticketTypes.assignAll(updatedTicketTypes);
        _calculateZoneStats();
        _logger.debug(
            'Types de tickets mis à jour via stream: ${updatedTicketTypes.length}');
      },
      onError: (error) {
        _logger.error('Erreur dans le stream des types de tickets',
            error: error, category: 'ZONE_DETAILS_CONTROLLER');
      },
    );
  }

  @override
  void onClose() {
    _logger.debug('ZoneDetailsController fermé pour zone: $zoneId',
        category: 'ZONE_DETAILS_CONTROLLER');
    super.onClose();
  }
}
