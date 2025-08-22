// lib/features/zones/controllers/ticket_management_controller.dart
import 'package:dnet_buy/app/services/manual_sale_service.dart';
import 'package:dnet_buy/features/manual_sale/controllers/manual_sale_controller.dart';
import 'package:dnet_buy/features/manual_sale/views/manual_sale_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
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
  final ManualSaleService _manualSaleService = Get.find<ManualSaleService>();
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

// États pour la vente manuelle
  var isSellingManually = false.obs;
  var selectedTicketForSale = Rx<TicketModel?>(null);

// Contrôleurs pour le formulaire de vente manuelle
  final manualSaleFormKey = GlobalKey<FormState>();
  final manualSalePhoneController = TextEditingController();
  final manualSaleDescriptionController = TextEditingController();

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

  @override
  void onClose() {
    manualSalePhoneController.dispose();
    manualSaleDescriptionController.dispose();
    super.onClose();
  }

// Validation du numéro de téléphone
  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro de téléphone requis';
    }

    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (value.startsWith('+237')) {
      if (digitsOnly.length != 12 || !digitsOnly.startsWith('237')) {
        return 'Format: +237XXXXXXXXX (9 chiffres après +237)';
      }
    } else if (value.startsWith('237')) {
      if (digitsOnly.length != 12) {
        return 'Format: 237XXXXXXXXX (12 chiffres au total)';
      }
    } else if (value.startsWith('6') || value.startsWith('2')) {
      if (digitsOnly.length != 9) {
        return 'Format: 6XXXXXXXX ou 2XXXXXXXX (9 chiffres)';
      }
    } else {
      return 'Format invalide. Utilisez: +237XXXXXXXXX, 237XXXXXXXXX, 6XXXXXXXX ou 2XXXXXXXX';
    }

    return null;
  }

// Validation de la description
  String? validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'Description trop longue (max 500 caractères)';
    }
    return null;
  }

// Ouvrir le formulaire de vente manuelle
  void openManualSaleForm(TicketModel ticket) {
    if (!ticket.isAvailable) {
      Get.snackbar(
        'Erreur',
        'Ce ticket n\'est pas disponible pour la vente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    selectedTicketForSale.value = ticket;
    manualSalePhoneController.clear();
    manualSaleDescriptionController.clear();

    _logger.logUserAction('manual_sale_form_opened', details: {
      'ticketId': ticket.id,
      'username': ticket.username,
    });
  }

// Fermer le formulaire de vente manuelle
  void closeManualSaleForm() {
    selectedTicketForSale.value = null;
    manualSalePhoneController.clear();
    manualSaleDescriptionController.clear();
    isSellingManually.value = false;
  }

// Effectuer la vente manuelle
  Future<void> sellTicketManually() async {
    if (!manualSaleFormKey.currentState!.validate()) return;
    if (selectedTicketForSale.value == null) return;

    try {
      isSellingManually.value = true;

      final result = await _manualSaleService.sellTicketManually(
        ticketId: selectedTicketForSale.value!.id,
        phoneNumber: manualSalePhoneController.text.trim(),
        description: manualSaleDescriptionController.text.trim().isEmpty
            ? null
            : manualSaleDescriptionController.text.trim(),
      );

      if (result.isSuccess) {
        // Copier automatiquement les identifiants
        final credentials =
            'Nom d\'utilisateur: ${result.credentials!.username}\nMot de passe: ${result.credentials!.password}';
        Clipboard.setData(ClipboardData(text: credentials));

        // Mettre à jour le ticket localement
        final ticketIndex =
            tickets.indexWhere((t) => t.id == selectedTicketForSale.value!.id);
        if (ticketIndex != -1) {
          tickets[ticketIndex] = selectedTicketForSale.value!.copyWith(
            status: 'used',
            soldAt: result.ticketInfo!.saleDate,
            buyerPhoneNumber: result.ticketInfo!.phoneNumber,
            saleType: 'manual',
            saleDescription: manualSaleDescriptionController.text.trim().isEmpty
                ? null
                : manualSaleDescriptionController.text.trim(),
            transactionId: result.transactionId,
            paymentReference: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        // Fermer le popup de détails
        Get.back();

        // Afficher le résultat de la vente
        _showSaleSuccessDialog(result);

        _logger.logUserAction('manual_sale_completed', details: {
          'transactionId': result.transactionId,
          'ticketId': selectedTicketForSale.value!.id,
          'phoneNumber': manualSalePhoneController.text.trim(),
        });

        // Réinitialiser le formulaire
        closeManualSaleForm();

        // Recharger les données
        await loadTickets();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de vendre le ticket: ${result.error}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      _logger.error('Erreur lors de la vente manuelle', error: e);
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSellingManually.value = false;
    }
  }

// Afficher le dialog de succès de vente
  void _showSaleSuccessDialog(ManualSaleResult result) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Vente réussie!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      'Transaction ID: ${result.transactionId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Forfait: ${result.ticketInfo!.planName}'),
                    Text('Montant: ${result.ticketInfo!.formattedAmount}'),
                    Text('Client: ${result.ticketInfo!.phoneNumber}'),
                    Text('Date: ${_formatDate(result.ticketInfo!.saleDate)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identifiants du client:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nom d\'utilisateur: ${result.credentials!.username}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    Text(
                      'Mot de passe: ${result.credentials!.password}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les identifiants ont été automatiquement copiés dans le presse-papiers',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final credentials = result.credentials!.formattedCredentials;
              Clipboard.setData(ClipboardData(text: credentials));
              Get.snackbar(
                'Copié!',
                'Identifiants copiés dans le presse-papiers',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Recopier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  // Ajouter cette méthode dans la classe TicketManagementController

// Navigation vers la vente manuelle
  void goToManualSale() {
    if (tickets.isEmpty) {
      Get.snackbar(
        'Information',
        'Aucun ticket disponible pour la vente',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final availableTickets =
        tickets.where((t) => t.status == 'available').toList();

    if (availableTickets.isEmpty) {
      Get.snackbar(
        'Information',
        'Aucun ticket disponible pour la vente',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _logger.logUserAction('navigate_to_manual_sale', details: {
      'ticketTypeId': ticketTypeId,
      'availableTickets': availableTickets.length,
    });

    Get.to(
      () => ManualSalePage(availableTickets: availableTickets),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ManualSaleController());
      }),
    );
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

  // Méthode pour générer et copier le lien public
  void copyPublicTicketLink() {
    try {
      if (ticketTypeId == null) {
        _logger.warning('Impossible de copier le lien: ticketTypeId est null');
        Get.snackbar(
          'Erreur',
          'Impossible de générer le lien pour ce forfait',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Construire l'URL publique avec les paramètres
      final baseUrl = _getBaseUrl();

      // Il y a différentes façons de construire l'URL selon le routage

      // Option 1: Avec le chemin et les paramètres dans la query string (plus sûr pour le web)
      final publicUrl =
          '$baseUrl/#/portal?zoneId=$zoneId&ticketTypeId=$ticketTypeId';

      // Option 2: Avec les paramètres intégrés à la route (selon votre configuration)
      // final publicUrl = '$baseUrl/#/portal/$zoneId/$ticketTypeId';

      // Copier dans le presse-papiers
      Clipboard.setData(ClipboardData(text: publicUrl));

      _logger.logUserAction('public_ticket_link_copied', details: {
        'zoneId': zoneId,
        'ticketTypeId': ticketTypeId,
        'url': publicUrl,
      });

      Get.snackbar(
        'Lien Public Copié',
        'Le lien public vers ce forfait a été copié dans le presse-papiers',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la copie du lien public',
          error: e,
          stackTrace: stackTrace,
          category: 'TICKET_MANAGEMENT_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de copier le lien',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

// Obtenir l'URL de base en fonction de la plateforme
  String _getBaseUrl() {
    if (GetPlatform.isWeb) {
      // En mode web, récupérer l'URL de base actuelle
      final uri = Uri.parse(Uri.base.toString());
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      return baseUrl;
    } else {
      // Pour les applications mobiles, utiliser l'URL de votre application web
      return 'https://dnet-29b02.web.app'; // Remplacer par votre URL réelle
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
        allowedExtensions: ['csv', 'xls', 'xlsx'],
      );

      if (result == null || result.files.single.bytes == null) {
        _logger.info('Aucun fichier sélectionné.', category: 'FILE_IMPORT');
        return;
      }

      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name.toLowerCase();

      // Déterminer le type de fichier et traiter en conséquence
      List<List<dynamic>> rows = [];

      if (fileName.endsWith('.csv')) {
        // Traitement CSV
        try {
          final csvString = utf8.decode(fileBytes);

          // Analyser le contenu pour déterminer le délimiteur probable
          String delimiter = ','; // Délimiteur par défaut

          // Vérifier si le contenu contient des points-virgules, des tabulations ou des virgules
          if (csvString.contains(';')) {
            delimiter = ';';
          } else if (csvString.contains('\t')) {
            delimiter = '\t';
          }

          // Tentative de parser avec le délimiteur détecté
          rows = CsvToListConverter(
            fieldDelimiter: delimiter,
            eol: '\n', // Explicitement spécifier le délimiteur de fin de ligne
            shouldParseNumbers:
                false, // Éviter la conversion automatique en nombres
          ).convert(csvString);

          // Si toujours une seule ligne, essayer de traiter manuellement
          if (rows.length <= 1 && csvString.contains('\n')) {
            // Split par ligne et puis par délimiteur
            final lines = csvString.split('\n');
            rows = [];
            for (var line in lines) {
              if (line.trim().isNotEmpty) {
                rows.add(line.split(delimiter).map((e) => e.trim()).toList());
              }
            }
          }

          _logger.debug('Fichier CSV traité avec délimiteur: $delimiter',
              category: 'FILE_IMPORT');
        } catch (e) {
          // Essayer avec un autre encodage si UTF-8 échoue
          try {
            final csvString = latin1.decode(fileBytes);

            // Même logique que ci-dessus pour déterminer le délimiteur
            String delimiter = ',';

            if (csvString.contains(';')) {
              delimiter = ';';
            } else if (csvString.contains('\t')) {
              delimiter = '\t';
            }

            rows = CsvToListConverter(
              fieldDelimiter: delimiter,
              eol: '\n',
              shouldParseNumbers: false,
            ).convert(csvString);

            // Traitement manuel si nécessaire
            if (rows.length <= 1 && csvString.contains('\n')) {
              final lines = csvString.split('\n');
              rows = [];
              for (var line in lines) {
                if (line.trim().isNotEmpty) {
                  rows.add(line.split(delimiter).map((e) => e.trim()).toList());
                }
              }
            }

            _logger.debug(
                'Fichier CSV traité (encodage latin1) avec délimiteur: $delimiter',
                category: 'FILE_IMPORT');
          } catch (e) {
            _logger.error('Erreur lors du décodage du fichier CSV',
                error: e, category: 'FILE_IMPORT');
            Get.snackbar(
              'Erreur de format',
              'Le fichier CSV n\'a pas pu être décodé. Vérifiez l\'encodage.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        }
      } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
        // Pour les fichiers Excel, ajoutez votre code ici en utilisant le package excel
        // ...
      } else {
        _logger.warning('Format de fichier non supporté.',
            category: 'FILE_IMPORT');
        Get.snackbar(
          'Format non supporté',
          'Formats supportés : CSV, XLS, XLSX',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Log pour inspection
      _logger.debug('Nombre de lignes: ${rows.length}',
          category: 'FILE_IMPORT');

      if (rows.isEmpty) {
        _logger.warning('Fichier vide.', category: 'FILE_IMPORT');
        Get.snackbar('Erreur', 'Le fichier est vide.');
        return;
      }

      // 🔍 Log des colonnes
      final headers =
          rows.isNotEmpty ? rows.first.map((e) => e.toString()).toList() : [];
      _logger.debug('Colonnes détectées: $headers', category: 'FILE_IMPORT');

      // 🔍 Log du contenu ligne par ligne
      for (int i = 1; i < rows.length; i++) {
        _logger.debug('Ligne $i: ${rows[i]}', category: 'FILE_IMPORT');
      }

      if (rows.length < 2) {
        Get.snackbar('Erreur', 'Le fichier ne contient que l\'en-tête.');
        return;
      }

      // 3. Traiter chaque ligne
      int successCount = 0;
      int duplicateCount = 0;
      int errorCount = 0;

      for (final row in rows.skip(1)) {
        if (row.length < 2) {
          _logger.warning('Ligne ignorée (colonnes insuffisantes): $row',
              category: 'FILE_IMPORT');
          errorCount++;
          continue;
        }

        final username = row[0].toString().trim();
        final password = row[1].toString().trim();

        if (username.isEmpty || password.isEmpty) {
          _logger.warning('Ligne ignorée (username ou password vide): $row',
              category: 'FILE_IMPORT');
          errorCount++;
          continue;
        }

        try {
          final bool exists =
              await _ticketService.doesTicketExist(username, zoneId);
          if (exists) {
            duplicateCount++;
            _logger.debug('Ticket déjà existant ignoré: $username',
                category: 'FILE_IMPORT');
          } else {
            await _ticketService.createTicket({
              'username': username,
              'password': password,
              'zoneId': zoneId,
              'ticketTypeId': ticketTypeId,
            });
            successCount++;
            _logger.debug('Ticket créé pour $username',
                category: 'FILE_IMPORT');
          }
        } catch (e) {
          errorCount++;
          _logger.error(
            'Erreur lors de la création du ticket pour $username',
            error: e,
            category: 'FILE_IMPORT',
          );
        }
      }

      // 4. Enregistrer les statistiques et afficher le résultat
      _logger.logEvent('file_import', {
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
        'Erreur lors de l\'importation du fichier',
        error: e,
        stackTrace: stackTrace,
        category: 'FILE_IMPORT',
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
