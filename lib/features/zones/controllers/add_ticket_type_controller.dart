// lib/features/zones/controllers/add_ticket_type_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';
import 'package:dnet_buy/features/zones/controllers/ticket_management_controller.dart';

class AddTicketTypeController extends GetxController {
  final TicketTypeService _ticketTypeService = Get.find<TicketTypeService>();
  final LoggerService _logger = LoggerService.to;

  // Clé du formulaire
  final formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final validityDaysController = TextEditingController();
  final downloadLimitController = TextEditingController();
  final uploadLimitController = TextEditingController();
  final sessionTimeController = TextEditingController();
  final notesController = TextEditingController();

  // États réactifs
  var isLoading = false.obs;
  var hasDownloadLimit = false.obs;
  var hasUploadLimit = false.obs;
  var hasSessionTimeLimit = false.obs;
  var isEditMode = false.obs;
  var ticketTypeId = ''.obs;
  var zoneId = ''.obs;
  var ticketType = Rx<TicketTypeModel?>(null);

  // Options de validité prédéfinies (en jours)
  final List<int> validityOptions = [1, 3, 7, 14, 30, 60, 90, 180, 365];

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 AddTicketTypeController initialisé',
        category: 'CONTROLLER');

    // Obtenir l'ID de la zone des arguments (création et édition)
    if (Get.arguments != null) {
      if (Get.arguments['zoneId'] != null) {
        zoneId.value = Get.arguments['zoneId'];
      }

      // Vérifier si nous sommes en mode édition
      if (Get.arguments['ticketTypeId'] != null) {
        ticketTypeId.value = Get.arguments['ticketTypeId'];
        isEditMode.value = true;
        _loadTicketTypeData();
      }
    }

    // Initialiser les écouteurs pour les limites
    _initLimitListeners();
  }

  void _initLimitListeners() {
    // Écouteurs pour activer/désactiver les champs selon les toggles
    hasDownloadLimit.listen((enabled) {
      if (!enabled) {
        downloadLimitController.text = '';
      }
    });

    hasUploadLimit.listen((enabled) {
      if (!enabled) {
        uploadLimitController.text = '';
      }
    });

    hasSessionTimeLimit.listen((enabled) {
      if (!enabled) {
        sessionTimeController.text = '';
      }
    });
  }

  // Charger les données du type de ticket en mode édition
  Future<void> _loadTicketTypeData() async {
    try {
      isLoading.value = true;
      _logger.debug(
          'Chargement des données du ticket pour édition: ${ticketTypeId.value}',
          category: 'ADD_TICKET_TYPE_CONTROLLER');

      final loadedTicketType =
          await _ticketTypeService.getTicketType(ticketTypeId.value);
      if (loadedTicketType != null) {
        ticketType.value = loadedTicketType;
        zoneId.value = loadedTicketType.zoneId;

        // Remplir les champs avec les données existantes
        nameController.text = loadedTicketType.name;
        descriptionController.text = loadedTicketType.description;
        priceController.text = loadedTicketType.price.toString();
        validityDaysController.text = loadedTicketType.validityHours.toString();

        _logger.debug('Données du ticket chargées pour édition',
            data: {
              'ticketTypeId': loadedTicketType.id,
              'name': loadedTicketType.name,
              'price': loadedTicketType.price,
            },
            category: 'ADD_TICKET_TYPE_CONTROLLER');
      } else {
        _logger.error('Type de ticket non trouvé: ${ticketTypeId.value}',
            category: 'ADD_TICKET_TYPE_CONTROLLER');

        Get.snackbar(
          'Erreur',
          'Type de ticket non trouvé',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );

        // Retourner à la page précédente si le type de ticket n'existe pas
        Get.back();
      }
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des données du ticket',
          error: e,
          stackTrace: stackTrace,
          category: 'ADD_TICKET_TYPE_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de charger les données du ticket: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );

      // Retourner à la page précédente en cas d'erreur
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  // Sauvegarder le type de ticket (création ou mise à jour)
  Future<void> saveTicketType() async {
    try {
      if (!formKey.currentState!.validate()) {
        _logger.warning('Formulaire invalide',
            category: 'ADD_TICKET_TYPE_CONTROLLER');
        return;
      }

      isLoading.value = true;

      // Préparer les données de base
      final ticketTypeData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.parse(priceController.text),
        'validityDays': int.parse(validityDaysController.text),
        'zoneId': zoneId.value,
      };

      // Ajouter les limites si activées
      if (hasDownloadLimit.value && downloadLimitController.text.isNotEmpty) {
        ticketTypeData['downloadLimit'] =
            int.parse(downloadLimitController.text);
      } else {
        ticketTypeData['downloadLimit'] = 0;
      }

      if (hasUploadLimit.value && uploadLimitController.text.isNotEmpty) {
        ticketTypeData['uploadLimit'] = int.parse(uploadLimitController.text);
      } else {
        ticketTypeData['uploadLimit'] = 0;
      }

      if (hasSessionTimeLimit.value && sessionTimeController.text.isNotEmpty) {
        ticketTypeData['sessionTimeLimit'] =
            int.parse(sessionTimeController.text);
      } else {
        ticketTypeData['sessionTimeLimit'] = 0;
      }

      // Ajouter les notes si présentes
      if (notesController.text.isNotEmpty) {
        ticketTypeData['notes'] = notesController.text.trim();
      }

      _logger.debug(
          isEditMode.value
              ? 'Mise à jour du type de ticket: ${ticketTypeId.value}'
              : 'Création d\'un nouveau type de ticket',
          data: ticketTypeData,
          category: 'ADD_TICKET_TYPE_CONTROLLER');

      String successMessage;
      String operationId;

      if (isEditMode.value) {
        // Mode édition - mettre à jour un type de ticket existant
        await _ticketTypeService.updateTicketType(
            ticketTypeId.value, ticketTypeData);
        operationId = ticketTypeId.value;

        _logger.logUserAction('ticket_type_updated_success', details: {
          'ticketTypeId': ticketTypeId.value,
          'ticketTypeName': ticketTypeData['name'],
          'zoneId': zoneId.value
        });

        successMessage =
            'Forfait "${ticketTypeData['name']}" mis à jour avec succès';
      } else {
        // Mode création - créer un nouveau type de ticket
        operationId = await _ticketTypeService.createTicketType(ticketTypeData);

        _logger.logUserAction('ticket_type_created_success', details: {
          'ticketTypeId': operationId,
          'ticketTypeName': ticketTypeData['name'],
          'zoneId': zoneId.value
        });

        successMessage = 'Forfait "${ticketTypeData['name']}" créé avec succès';
      }

      // Rafraîchir les données des autres contrôleurs
      _refreshRelatedControllers();

      // Rediriger vers la page de détails de la zone
      Get.until(
          (route) => Get.currentRoute == '/dashboard/zones/${zoneId.value}');

      // Afficher le message de succès après la redirection
      Get.snackbar(
        'Succès',
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e, stackTrace) {
      final action = isEditMode.value ? 'mise à jour' : 'création';
      _logger.error('Erreur lors de la $action du type de ticket',
          error: e,
          stackTrace: stackTrace,
          category: 'ADD_TICKET_TYPE_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de ${isEditMode.value ? "modifier" : "créer"} le forfait: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rafraîchir les contrôleurs liés pour mettre à jour les données
  void _refreshRelatedControllers() {
    try {
      // Rafraîchir les détails de la zone
      if (Get.isRegistered<ZoneDetailsController>()) {
        final detailsController = Get.find<ZoneDetailsController>();
        if (detailsController.zoneId == zoneId.value) {
          detailsController.refreshData();
        }
      }

      // Rafraîchir la gestion des tickets si disponible
      if (Get.isRegistered<TicketManagementController>()) {
        final ticketManagementController =
            Get.find<TicketManagementController>();
        if (ticketManagementController.zoneId == zoneId.value) {
          ticketManagementController.refreshData();
        }
      }
    } catch (e) {
      _logger.error('Erreur lors du rafraîchissement des contrôleurs',
          error: e, category: 'ADD_TICKET_TYPE_CONTROLLER');
    }
  }

  // Valider le nom du forfait
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du forfait est requis';
    }
    if (value.trim().length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }
    if (value.trim().length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    return null;
  }

  // Valider la description
  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La description est requise';
    }
    if (value.trim().length < 10) {
      return 'La description doit contenir au moins 10 caractères';
    }
    if (value.trim().length > 200) {
      return 'La description ne peut pas dépasser 200 caractères';
    }
    return null;
  }

  // Valider le prix
  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est requis';
    }

    try {
      final price = double.parse(value);
      if (price <= 0) {
        return 'Le prix doit être supérieur à 0';
      }
    } catch (e) {
      return 'Veuillez entrer un prix valide';
    }

    return null;
  }

  // Valider la durée de validité
  String? validateValidityDays(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La durée de validité est requise';
    }

    try {
      final days = int.parse(value);
      if (days <= 0) {
        return 'La durée doit être supérieure à 0';
      }
      if (days > 1000) {
        return 'La durée ne peut pas dépasser 1000 jours';
      }
    } catch (e) {
      return 'Veuillez entrer une durée valide';
    }

    return null;
  }

  // Valider la limite de téléchargement
  String? validateDownloadLimit(String? value) {
    if (!hasDownloadLimit.value) return null;

    if (value == null || value.trim().isEmpty) {
      return 'La limite de téléchargement est requise';
    }

    try {
      final limit = int.parse(value);
      if (limit <= 0) {
        return 'La limite doit être supérieure à 0';
      }
    } catch (e) {
      return 'Veuillez entrer une limite valide';
    }

    return null;
  }

  // Valider la limite d'upload
  String? validateUploadLimit(String? value) {
    if (!hasUploadLimit.value) return null;

    if (value == null || value.trim().isEmpty) {
      return 'La limite d\'envoi est requise';
    }

    try {
      final limit = int.parse(value);
      if (limit <= 0) {
        return 'La limite doit être supérieure à 0';
      }
    } catch (e) {
      return 'Veuillez entrer une limite valide';
    }

    return null;
  }

  // Valider la limite de temps de session
  String? validateSessionTimeLimit(String? value) {
    if (!hasSessionTimeLimit.value) return null;

    if (value == null || value.trim().isEmpty) {
      return 'La limite de temps de session est requise';
    }

    try {
      final limit = int.parse(value);
      if (limit <= 0) {
        return 'La limite doit être supérieure à 0';
      }
    } catch (e) {
      return 'Veuillez entrer une limite valide';
    }

    return null;
  }

  // Réinitialiser le formulaire
  void resetForm() {
    if (isEditMode.value) {
      // En mode édition, recharger les données originales
      _loadTicketTypeData();
    } else {
      // En mode création, vider le formulaire
      nameController.clear();
      descriptionController.clear();
      priceController.clear();
      validityDaysController.text = '1'; // Valeur par défaut
      downloadLimitController.clear();
      uploadLimitController.clear();
      sessionTimeController.clear();
      notesController.clear();

      // Réinitialiser les toggles
      hasDownloadLimit.value = false;
      hasUploadLimit.value = false;
      hasSessionTimeLimit.value = false;
    }
    _logger.debug('Formulaire réinitialisé',
        category: 'ADD_TICKET_TYPE_CONTROLLER');
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    validityDaysController.dispose();
    downloadLimitController.dispose();
    uploadLimitController.dispose();
    sessionTimeController.dispose();
    notesController.dispose();
    _logger.debug('AddTicketTypeController fermé',
        category: 'ADD_TICKET_TYPE_CONTROLLER');
    super.onClose();
  }
}
