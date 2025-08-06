// lib/features/zones/controllers/ticket_management_controller.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dnet_buy/app/services/ticket_service.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_model.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketManagementController extends GetxController {
  final TicketTypeService _ticketTypeService = Get.find<TicketTypeService>();
  final TicketService _ticketService = Get.find<TicketService>();
  final LoggerService _logger = LoggerService.to;

  final String zoneId;
  final String? ticketTypeId; // Ajouté comme paramètre optionnel

  // États réactifs
  var isLoading = false.obs;
  var ticketTypes = <TicketTypeModel>[].obs;
  var ticketType =
      Rx<TicketTypeModel?>(null); // Pour stocker un type de ticket spécifique
  var isUploading = false.obs; // Pour l'état d'upload
  var tickets = <TicketModel>[].obs; // Liste de tickets génériques

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
      loadTickets(); // Charger aussi les tickets
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

      _logger.debug(
          'Détails du type de ticket chargés: ${loadedTicketType?.name}');
    } catch (e) {
      _logger.error('Erreur lors du chargement des détails du type de ticket',
          error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les tickets pour le type de ticket actuel
  Future<void> loadTickets() async {
    if (ticketTypeId == null) return;
    try {
      isLoading.value = true;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('zoneId', isEqualTo: zoneId)
          .where('ticketTypeId', isEqualTo: ticketTypeId)
          .orderBy('createdAt', descending: true)
          .get();

      final loadedTickets = querySnapshot.docs
          .map((doc) => TicketModel.fromFirestore(doc))
          .toList();
      tickets.assignAll(loadedTickets);
      _logger.debug('${loadedTickets.length} tickets chargés.');
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des tickets',
          error: e, stackTrace: stackTrace);
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


void pickAndUploadCsv() async {
  try {
    isUploading.value = true;

    _logger.logUserAction('csv_import_initiated', details: {
      'zoneId': zoneId,
      'ticketTypeId': ticketTypeId,
    });

    // 1. Sélectionner le fichier
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.bytes == null) {
      _logger.info('Aucun fichier sélectionné.', category: 'CSV_IMPORT');
      return;
    }

    final fileBytes = result.files.single.bytes!;
    final csvString = utf8.decode(fileBytes);

final List<List<dynamic>> rows = const CsvToListConverter(
  fieldDelimiter: ',',
).convert(csvString);

// Log pour inspection
_logger.debug('Nombre de lignes CSV: ${rows.length}', category: 'CSV_IMPORT');
_logger.debug('Contenu brut du CSV:\n$csvString', category: 'CSV_IMPORT');


    if (rows.isEmpty) {
      _logger.warning('Fichier CSV vide.', category: 'CSV_IMPORT');
      Get.snackbar('Erreur', 'Le fichier CSV est vide.');
      return;
    }

    // 🔍 Log des colonnes
    final headers = rows.first.map((e) => e.toString()).toList();
    _logger.debug('Colonnes détectées dans le CSV: $headers',
        category: 'CSV_IMPORT');

    // 🔍 Log du contenu ligne par ligne
    for (int i = 1; i < rows.length; i++) {
      _logger.debug('Ligne $i: ${rows[i]}', category: 'CSV_IMPORT');
    }

    if (rows.length < 2) {
      Get.snackbar('Erreur', 'Le fichier CSV ne contient que l\'en-tête.');
      return;
    }

    // 3. Traiter chaque ligne
    int successCount = 0;
    int duplicateCount = 0;
    int errorCount = 0;

    for (final row in rows.skip(1)) {
      if (row.length < 2) {
        _logger.warning('Ligne ignorée (colonnes insuffisantes): $row',
            category: 'CSV_IMPORT');
        errorCount++;
        continue;
      }

      final username = row[0].toString().trim();
      final password = row[1].toString().trim();

      if (username.isEmpty || password.isEmpty) {
        _logger.warning('Ligne ignorée (username ou password vide): $row',
            category: 'CSV_IMPORT');
        errorCount++;
        continue;
      }

      try {
        final bool exists = await _ticketService.doesTicketExist(username, zoneId);
        if (exists) {
          duplicateCount++;
          _logger.debug('Ticket déjà existant ignoré: $username',
              category: 'CSV_IMPORT');
        } else {
          await _ticketService.createTicket({
            'username': username,
            'password': password,
            'zoneId': zoneId,
            'ticketTypeId': ticketTypeId,
          });
          successCount++;
          _logger.debug('Ticket créé pour $username', category: 'CSV_IMPORT');
        }
      } catch (e) {
        errorCount++;
        _logger.error(
          'Erreur lors de la création du ticket pour $username',
          error: e,
          category: 'CSV_IMPORT',
        );
      }
    }

    // 4. Résumé structuré
    _logger.logEvent('csv_ticket_import', {
      'zoneId': zoneId,
      'ticketTypeId': ticketTypeId,
      'columns': headers,
      'totalLines': rows.length - 1,
      'created': successCount,
      'duplicates': duplicateCount,
      'errors': errorCount,
    });

    Get.snackbar(
      'Importation terminée',
      '$successCount ticket(s) créé(s), $duplicateCount doublon(s), $errorCount erreur(s).',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );

    await loadTickets();
  } catch (e, stackTrace) {
    _logger.error(
      'Erreur lors de l\'importation du fichier CSV',
      error: e,
      stackTrace: stackTrace,
      category: 'CSV_IMPORT',
    );
    Get.snackbar(
      'Erreur d\'importation',
      'Un problème est survenu: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
    );
  } finally {
    isUploading.value = false;
  }
}

}
