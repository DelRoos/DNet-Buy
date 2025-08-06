// lib/features/zones/controllers/add_ticket_type_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';

class AddTicketTypeController extends GetxController {
  final String zoneId;
  AddTicketTypeController({required this.zoneId});

  final TicketTypeService _ticketTypeService = Get.find<TicketTypeService>();
  final LoggerService _logger = LoggerService.to;

  // Clé du formulaire
  final formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final validityController = TextEditingController();
  final expirationAfterCreationController = TextEditingController(text: '30');
  final nbMaxUtilisationsController = TextEditingController(text: '1');

  // États réactifs
  var isLoading = false.obs;
  var isActive = true.obs;
  var selectedValidityType = 'hours'.obs; // hours, days, weeks
  var validityHours = 24.obs;

  // Options prédéfinies
  final List<Map<String, dynamic>> validityPresets = [
    {'label': '1 Heure', 'hours': 1, 'display': '1h'},
    {'label': '3 Heures', 'hours': 3, 'display': '3h'},
    {'label': '6 Heures', 'hours': 6, 'display': '6h'},
    {'label': '12 Heures', 'hours': 12, 'display': '12h'},
    {'label': '24 Heures', 'hours': 24, 'display': '1 jour'},
    {'label': '48 Heures', 'hours': 48, 'display': '2 jours'},
    {'label': '72 Heures', 'hours': 72, 'display': '3 jours'},
    {'label': '7 Jours', 'hours': 168, 'display': '1 semaine'},
    {'label': '30 Jours', 'hours': 720, 'display': '1 mois'},
  ];

  final List<String> pricePresets = [
    '500',
    '1000',
    '1500',
    '2000',
    '2500',
    '5000',
  ];

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 AddTicketTypeController initialisé pour zone: $zoneId', 
        category: 'CONTROLLER');
    
    // Écouter les changements des heures de validité
    validityHours.listen((hours) {
      _updateValidityDisplay();
    });
  }

  // Sauvegarder le type de ticket
  Future<void> saveTicketType() async {
    try {
      if (!formKey.currentState!.validate()) {
        _logger.warning('Formulaire invalide', category: 'ADD_TICKET_TYPE_CONTROLLER');
        return;
      }

      isLoading.value = true;
      _logger.debug('Création d\'un nouveau type de ticket', category: 'ADD_TICKET_TYPE_CONTROLLER');

      // Préparer les données
      final ticketTypeData = {
        'zoneId': zoneId,
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': int.parse(priceController.text.trim()),
        'validity': validityController.text.trim(),
        'validityHours': validityHours.value,
        'expirationAfterCreation': int.parse(expirationAfterCreationController.text.trim()),
        'nbMaxUtilisations': int.parse(nbMaxUtilisationsController.text.trim()),
        'isActive': isActive.value,
      };

      _logger.debug('Données du type de ticket à créer', 
          data: ticketTypeData, category: 'ADD_TICKET_TYPE_CONTROLLER');

      // Créer le type de ticket
      final ticketTypeId = await _ticketTypeService.createTicketType(ticketTypeData);

      _logger.logUserAction('ticket_type_created_success', details: {
        'ticketTypeId': ticketTypeId,
        'ticketTypeName': ticketTypeData['name'],
        'zoneId': zoneId,
      });

      Get.snackbar(
        'Succès',
        'Forfait "${ticketTypeData['name']}" créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      // Actualiser les données dans le contrôleur parent
      if (Get.isRegistered<ZoneDetailsController>()) {
        Get.find<ZoneDetailsController>().fetchData();
      }

      // Retourner à la page précédente
      Get.back();

    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la création du type de ticket',
          error: e, stackTrace: stackTrace, category: 'ADD_TICKET_TYPE_CONTROLLER');
      
      Get.snackbar(
        'Erreur',
        'Impossible de créer le forfait: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour l'affichage de la validité
  void _updateValidityDisplay() {
    final hours = validityHours.value;
    String display;
    
    if (hours < 24) {
      display = '${hours}h';
    } else if (hours < 168) {
      final days = (hours / 24).round();
      display = '$days jour${days > 1 ? 's' : ''}';
    } else if (hours < 720) {
      final weeks = (hours / 168).round();
      display = '$weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      final months = (hours / 720).round();
      display = '$months mois';
    }
    
    validityController.text = display;
  }

  // Sélectionner un preset de validité
  void selectValidityPreset(Map<String, dynamic> preset) {
    validityHours.value = preset['hours'];
    _logger.debug('Preset de validité sélectionné: ${preset['label']}',
        category: 'ADD_TICKET_TYPE_CONTROLLER');
  }

  // Sélectionner un preset de prix
  void selectPricePreset(String price) {
    priceController.text = price;
    _logger.debug('Preset de prix sélectionné: $price F',
        category: 'ADD_TICKET_TYPE_CONTROLLER');
  }

  // Basculer le statut actif
  void toggleIsActive(bool value) {
    isActive.value = value;
    _logger.debug('Statut actif changé: $value', category: 'ADD_TICKET_TYPE_CONTROLLER');
  }

  // Validation du nom
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

  // Validation de la description
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

  // Validation du prix
  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prix est requis';
    }
    
    final price = int.tryParse(value.trim());
    if (price == null) {
      return 'Le prix doit être un nombre entier';
    }
    if (price <= 0) {
      return 'Le prix doit être supérieur à 0';
    }
    if (price > 100000) {
      return 'Le prix ne peut pas dépasser 100,000 F';
    }
    return null;
  }

  // Validation de l'expiration
  String? validateExpiration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'expiration est requise';
    }
    
    final days = int.tryParse(value.trim());
    if (days == null) {
      return 'L\'expiration doit être un nombre de jours';
    }
    if (days <= 0) {
      return 'L\'expiration doit être supérieure à 0';
    }
    if (days > 365) {
      return 'L\'expiration ne peut pas dépasser 365 jours';
    }
    return null;
  }

  // Validation du nombre max d'utilisations
  String? validateMaxUsages(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nombre max d\'utilisations est requis';
    }
    
    final usages = int.tryParse(value.trim());
    if (usages == null) {
      return 'Doit être un nombre entier';
    }
    if (usages <= 0) {
      return 'Doit être supérieur à 0';
    }
    if (usages > 100) {
      return 'Ne peut pas dépasser 100 utilisations';
    }
    return null;
  }

  // Réinitialiser le formulaire
  void resetForm() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    validityController.clear();
    expirationAfterCreationController.text = '30';
    nbMaxUtilisationsController.text = '1';
    isActive.value = true;
    validityHours.value = 24;
    selectedValidityType.value = 'hours';
    _logger.debug('Formulaire réinitialisé', category: 'ADD_TICKET_TYPE_CONTROLLER');
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    validityController.dispose();
    expirationAfterCreationController.dispose();
    nbMaxUtilisationsController.dispose();
    _logger.debug('AddTicketTypeController fermé', category: 'ADD_TICKET_TYPE_CONTROLLER');
    super.onClose();
  }
}