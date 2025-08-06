// lib/features/zones/controllers/add_zone_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/zone_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';

class AddZoneController extends GetxController {
  final ZoneService _zoneService = Get.find<ZoneService>();
  final LoggerService _logger = LoggerService.to;

  // Clé du formulaire
  final formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final routerTypeController = TextEditingController();

  // États réactifs
  var isLoading = false.obs;
  var selectedRouterType = ''.obs;
  var tags = <String>[].obs;

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
    
    // Écouter les changements du type de routeur sélectionné
    selectedRouterType.listen((type) {
      if (type.isNotEmpty && type != 'Autre') {
        routerTypeController.text = type;
      }
    });
  }

  // Sauvegarder la zone
  Future<void> saveZone() async {
    try {
      if (!formKey.currentState!.validate()) {
        _logger.warning('Formulaire invalide', category: 'ADD_ZONE_CONTROLLER');
        return;
      }

      isLoading.value = true;
      _logger.debug('Création d\'une nouvelle zone', category: 'ADD_ZONE_CONTROLLER');

      // Préparer les données
      final zoneData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'routerType': routerTypeController.text.trim(),
        'tags': tags.toList(),
      };

      _logger.debug('Données de la zone à créer', 
          data: zoneData, category: 'ADD_ZONE_CONTROLLER');

      // Créer la zone
      final zoneId = await _zoneService.createZone(zoneData);

      _logger.logUserAction('zone_created_success', details: {
        'zoneId': zoneId,
        'zoneName': zoneData['name'],
      });

      Get.snackbar(
        'Succès',
        'Zone WiFi "${zoneData['name']}" créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      // Rediriger vers la liste des zones
      Get.back();
      Get.back();
      
      // Optionnel: rediriger vers les détails de la zone créée
      // Get.offNamed('/dashboard/zones/$zoneId');

    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la création de la zone',
          error: e, stackTrace: stackTrace, category: 'ADD_ZONE_CONTROLLER');
      
      Get.snackbar(
        'Erreur',
        'Impossible de créer la zone: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Ajouter un tag
  void addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !tags.contains(trimmedTag)) {
      tags.add(trimmedTag);
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
   nameController.clear();
   descriptionController.clear();
   routerTypeController.clear();
   selectedRouterType.value = '';
   tags.clear();
   _logger.debug('Formulaire réinitialisé', category: 'ADD_ZONE_CONTROLLER');
 }

 @override
 void onClose() {
   nameController.dispose();
   descriptionController.dispose();
   routerTypeController.dispose();
   _logger.debug('AddZoneController fermé', category: 'ADD_ZONE_CONTROLLER');
   super.onClose();
 }
}