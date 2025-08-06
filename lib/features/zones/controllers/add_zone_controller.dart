// lib/features/zones/controllers/add_zone_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/zone_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';
import 'package:dnet_buy/features/zones/controllers/zones_controller.dart';

class AddZoneController extends GetxController {
  final ZoneService _zoneService = Get.find<ZoneService>();
  final LoggerService _logger = LoggerService.to;

  // Clé du formulaire
  final formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final routerTypeController = TextEditingController();
  final tagController = TextEditingController();

  // États réactifs
  var isLoading = false.obs;
  var selectedRouterType = ''.obs;
  var tags = <String>[].obs;
  var isEditMode = false.obs;
  var zoneId = ''.obs;
  var zone = Rx<ZoneModel?>(null);

  // Types de routeurs prédéfinis
  final List<String> routerTypes = [
    'MikroTik hAP ac²',
    'MikroTik hAP ac³',
    'Ubiquiti UniFi AP',
    'Ubiquiti Dream Machine',
    'TP-Link Archer',
    'Netgear Nighthawk',
    'Autre'
  ];

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 AddZoneController initialisé', category: 'CONTROLLER');

    // Vérifier si nous sommes en mode édition via les arguments de route
    if (Get.arguments != null && Get.arguments['zoneId'] != null) {
      zoneId.value = Get.arguments['zoneId'];
      isEditMode.value = true;
      _loadZoneData();
    }
    // Vérifier si nous sommes en mode édition via les paramètres de route
    else if (Get.parameters.containsKey('zoneId')) {
      zoneId.value = Get.parameters['zoneId']!;
      isEditMode.value = true;
      _loadZoneData();
    }

    // Écouter les changements du type de routeur sélectionné
    selectedRouterType.listen((type) {
      if (type.isNotEmpty && type != 'Autre') {
        routerTypeController.text = type;
      }
    });
  }

  // Charger les données de la zone en mode édition
  Future<void> _loadZoneData() async {
    try {
      isLoading.value = true;
      _logger.debug(
          'Chargement des données de la zone pour édition: ${zoneId.value}',
          category: 'ADD_ZONE_CONTROLLER');

      final loadedZone = await _zoneService.getZone(zoneId.value);
      if (loadedZone != null) {
        zone.value = loadedZone;

        // Remplir les champs avec les données existantes
        nameController.text = loadedZone.name;
        descriptionController.text = loadedZone.description;
        routerTypeController.text = loadedZone.routerType;

        // Sélectionner le type de routeur s'il correspond à un type prédéfini
        if (routerTypes.contains(loadedZone.routerType)) {
          selectedRouterType.value = loadedZone.routerType;
        } else {
          selectedRouterType.value = 'Autre';
          routerTypeController.text = loadedZone.routerType;
        }

        // Charger les tags
        tags.assignAll(loadedZone.tags ?? []);

        _logger.debug('Données de la zone chargées pour édition',
            data: {
              'zoneId': loadedZone.id,
              'name': loadedZone.name,
              'description': loadedZone.description,
              'routerType': loadedZone.routerType,
              'tags': loadedZone.tags,
            },
            category: 'ADD_ZONE_CONTROLLER');
      } else {
        _logger.error('Zone non trouvée: ${zoneId.value}',
            category: 'ADD_ZONE_CONTROLLER');

        Get.snackbar(
          'Erreur',
          'Zone non trouvée',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );

        // Retourner à la page précédente si la zone n'existe pas
        Get.back();
      }
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des données de la zone',
          error: e, stackTrace: stackTrace, category: 'ADD_ZONE_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de charger les données de la zone: ${e.toString()}',
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

  // Sauvegarder la zone (création ou mise à jour)
  Future<void> saveZone() async {
    try {
      if (!formKey.currentState!.validate()) {
        _logger.warning('Formulaire invalide', category: 'ADD_ZONE_CONTROLLER');
        return;
      }

      isLoading.value = true;

      // Préparer les données
      final zoneData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'routerType': routerTypeController.text.trim(),
        'tags': tags.toList(),
      };

      _logger.debug(
          isEditMode.value
              ? 'Mise à jour de la zone: ${zoneId.value}'
              : 'Création d\'une nouvelle zone',
          data: zoneData,
          category: 'ADD_ZONE_CONTROLLER');

      String successMessage;
      String operationId;

      if (isEditMode.value) {
        // Mode édition - mettre à jour une zone existante
        await _zoneService.updateZone(zoneId.value, zoneData);
        operationId = zoneId.value;

        _logger.logUserAction('zone_updated_success', details: {
          'zoneId': zoneId.value,
          'zoneName': zoneData['name'],
        });

        successMessage =
            'Zone WiFi "${zoneData['name']}" mise à jour avec succès';
      } else {
        // Mode création - créer une nouvelle zone
        operationId = await _zoneService.createZone(zoneData);

        _logger.logUserAction('zone_created_success', details: {
          'zoneId': operationId,
          'zoneName': zoneData['name'],
        });

        successMessage = 'Zone WiFi "${zoneData['name']}" créée avec succès';
      }

      // Rafraîchir les données des autres contrôleurs
      _refreshRelatedControllers();

      // Rediriger vers la liste des zones
      Get.until((route) => Get.currentRoute == '/dashboard/zones');

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
      _logger.error('Erreur lors de la $action de la zone',
          error: e, stackTrace: stackTrace, category: 'ADD_ZONE_CONTROLLER');

      Get.snackbar(
        'Erreur',
        'Impossible de ${isEditMode.value ? "modifier" : "créer"} la zone: ${e.toString()}',
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
      // Rafraîchir la liste des zones
      if (Get.isRegistered<ZonesController>()) {
        final zonesController = Get.find<ZonesController>();
        zonesController.refreshZones();
      }

      // Rafraîchir les détails de la zone si en mode édition
      if (isEditMode.value && Get.isRegistered<ZoneDetailsController>()) {
        final detailsController = Get.find<ZoneDetailsController>();
        detailsController.refreshData();
      }
    } catch (e) {
      _logger.error('Erreur lors du rafraîchissement des contrôleurs',
          error: e, category: 'ADD_ZONE_CONTROLLER');
    }
  }

  // Ajouter un tag
  void addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !tags.contains(trimmedTag)) {
      tags.add(trimmedTag);
      tagController.clear(); // Vider le champ après ajout
      _logger.debug('Tag ajouté: $trimmedTag', category: 'ADD_ZONE_CONTROLLER');
    }
  }

  // Supprimer un tag
  void removeTag(String tag) {
    tags.remove(tag);
    _logger.debug('Tag supprimé: $tag', category: 'ADD_ZONE_CONTROLLER');
  }

  // Valider le nom de la zone
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom de la zone est requis';
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

  // Valider le type de routeur
  String? validateRouterType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le type de routeur est requis';
    }
    if (value.trim().length < 3) {
      return 'Le type de routeur doit contenir au moins 3 caractères';
    }
    return null;
  }

  // Réinitialiser le formulaire
  void resetForm() {
    if (isEditMode.value) {
      // En mode édition, recharger les données originales
      _loadZoneData();
    } else {
      // En mode création, vider le formulaire
      nameController.clear();
      descriptionController.clear();
      routerTypeController.clear();
      selectedRouterType.value = '';
      tags.clear();
    }
    _logger.debug('Formulaire réinitialisé', category: 'ADD_ZONE_CONTROLLER');
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    routerTypeController.dispose();
    tagController.dispose();
    _logger.debug('AddZoneController fermé', category: 'ADD_ZONE_CONTROLLER');
    super.onClose();
  }
}
