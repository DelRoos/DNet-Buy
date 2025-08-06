// lib/features/zones/controllers/ticket_management_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketManagementController extends GetxController {
  final TicketTypeService _ticketTypeService = Get.find<TicketTypeService>();
  final LoggerService _logger = LoggerService.to;

  final String zoneId;
  final String? ticketTypeId; // Ajouté comme paramètre optionnel

  // États réactifs
  var isLoading = false.obs;
  var ticketTypes = <TicketTypeModel>[].obs;
  var ticketType =
      Rx<TicketTypeModel?>(null); // Pour stocker un type de ticket spécifique
  var isUploading = false.obs; // Pour l'état d'upload
  var tickets = <dynamic>[].obs; // Liste de tickets génériques

  TicketManagementController(
      {required this.zoneId,
      this.ticketTypeId}); // Modification du constructeur

  @override
  void onInit() {
    super.onInit();
    _logger.info('TicketManagementController initialisé pour zone: $zoneId');

    loadTicketTypes();

    // Si un ticketTypeId est fourni, charger les détails de ce type de ticket
    if (ticketTypeId != null) {
      loadTicketTypeDetails();
    }
  }

  // Charger les détails d'un type de ticket spécifique
  Future<void> loadTicketTypeDetails() async {
    try {
      if (ticketTypeId == null) return;

      isLoading.value = true;
      final loadedTicketType =
          await _ticketTypeService.getTicketType(ticketTypeId!);
      ticketType.value = loadedTicketType;

      // Charger les tickets associés à ce type de ticket
      // Cette méthode dépendrait de votre implémentation
      // await loadTickets();

      _logger.debug(
          'Détails du type de ticket chargés: ${loadedTicketType?.name}');
    } catch (e) {
      _logger.error('Erreur lors du chargement des détails du type de ticket',
          error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les types de tickets
  Future<void> loadTicketTypes() async {
    try {
      isLoading.value = true;
      final types = await _ticketTypeService.getTicketTypes(zoneId);
      ticketTypes.assignAll(types);
      _logger.debug('Types de tickets chargés: ${types.length}');
    } catch (e) {
      _logger.error('Erreur lors du chargement des types de tickets', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // Rafraîchir les données
  Future<void> refreshData() async {
    await loadTicketTypes();
    if (ticketTypeId != null) {
      await loadTicketTypeDetails();
    }
  }

  // Éditer un type de ticket
  void editTicketType(String ticketTypeId) {
    _logger.logUserAction('edit_ticket_type', details: {
      'ticketTypeId': ticketTypeId,
      'zoneId': zoneId,
    });

    _logger.logNavigation('/dashboard/zones/$zoneId/tickets/$ticketTypeId/edit',
        params: {'zoneId': zoneId, 'ticketTypeId': ticketTypeId});

    Get.toNamed('/dashboard/zones/$zoneId/tickets/$ticketTypeId/edit',
        arguments: {
          'zoneId': zoneId,
          'ticketTypeId': ticketTypeId,
        });
  }

  // Changer le statut d'un type de ticket
  Future<void> toggleTicketTypeStatus(
      String ticketTypeId, bool newStatus) async {
    try {
      _logger.debug(
          'Changement du statut du type de ticket: $ticketTypeId -> $newStatus');

      await _ticketTypeService.toggleTicketTypeStatus(ticketTypeId, newStatus);

      // Mettre à jour localement
      final index = ticketTypes.indexWhere((t) => t.id == ticketTypeId);
      if (index != -1) {
        final updatedTicket = ticketTypes[index].copyWith(isActive: newStatus);
        ticketTypes[index] = updatedTicket;
      }

      // Si c'est le ticket courant, mettre à jour également
      if (this.ticketTypeId == ticketTypeId && ticketType.value != null) {
        ticketType.value = ticketType.value!.copyWith(isActive: newStatus);
      }

      _logger.logUserAction('ticket_type_status_changed', details: {
        'ticketTypeId': ticketTypeId,
        'newStatus': newStatus ? 'active' : 'inactive',
        'zoneId': zoneId,
      });

      Get.snackbar(
        'Succès',
        'Statut du forfait ${newStatus ? 'activé' : 'désactivé'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _logger.error('Erreur lors du changement de statut du type de ticket',
          error: e, category: 'TICKET_MANAGEMENT_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Supprimer un type de ticket
  Future<void> deleteTicketType(String ticketTypeId) async {
    try {
      // Confirmation
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer la suppression'),
          content:
              const Text('Êtes-vous sûr de vouloir supprimer ce forfait ?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Supprimer'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _logger.debug('Suppression du type de ticket: $ticketTypeId');

      await _ticketTypeService.deleteTicketType(ticketTypeId);

      // Retirer de la liste locale
      ticketTypes.removeWhere((t) => t.id == ticketTypeId);

      _logger.logUserAction('ticket_type_deleted', details: {
        'ticketTypeId': ticketTypeId,
        'zoneId': zoneId,
      });

      Get.snackbar(
        'Succès',
        'Forfait supprimé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _logger.error('Erreur lors de la suppression du type de ticket',
          error: e, category: 'TICKET_MANAGEMENT_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le forfait: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Méthode pour simuler le téléchargement d'un fichier CSV
  void pickAndUploadCsv() async {
    try {
      isUploading.value = true;

      // Simulation d'un téléchargement
      await Future.delayed(const Duration(seconds: 2));

      // Simulation de tickets chargés
      tickets.assignAll([
        {
          'id': '1',
          'username': 'user1',
          'password': 'pass1',
          'status': 'available'
        },
        {
          'id': '2',
          'username': 'user2',
          'password': 'pass2',
          'status': 'available'
        },
        {'id': '3', 'username': 'user3', 'password': 'pass3', 'status': 'sold'},
      ]);

      Get.snackbar(
        'Succès',
        'Fichier CSV importé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _logger.error('Erreur lors du téléchargement du fichier CSV', error: e);

      Get.snackbar(
        'Erreur',
        'Impossible d\'importer le fichier: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
    }
  }
}
