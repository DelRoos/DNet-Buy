import 'package:dnet_buy/features/user_ticket/models/user_ticket_model.dart';
import 'package:dnet_buy/features/user_ticket/services/user_tickets_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';

class UserTicketsController extends GetxController {
  final UserTicketsService _userTicketsService = UserTicketsService();
  final LoggerService _logger = LoggerService.to;

  // Contrôleurs de formulaire
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // États réactifs
  var isLoading = false.obs;
  var tickets = <UserTicketModel>[].obs;
  var searchedPhoneNumber = ''.obs;

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  // Validation du numéro de téléphone
  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro de téléphone requis';
    }
    
    // Supprimer tous les caractères non numériques pour la validation
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Vérifier les formats acceptés
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

  // Rechercher les tickets
  Future<void> searchTickets() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      tickets.clear();
      
      final phoneNumber = phoneController.text.trim();
      searchedPhoneNumber.value = phoneNumber;

      _logger.logUserAction('search_user_tickets', details: {
        'phoneNumber': phoneNumber,
      });

      final foundTickets = await _userTicketsService.getUserTicketsByPhone(phoneNumber);
      
      tickets.assignAll(foundTickets);

      if (foundTickets.isEmpty) {
        Get.snackbar(
          'Information',
          'Aucun ticket trouvé pour ce numéro de téléphone',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      } else {
        _logger.logUserAction('user_tickets_found', details: {
          'phoneNumber': phoneNumber,
          'ticketsCount': foundTickets.length,
        });
      }

    } catch (e) {
      _logger.error(
        'Erreur lors de la recherche de tickets',
        error: e,
        category: 'USER_TICKETS_CONTROLLER',
      );

      Get.snackbar(
        'Erreur',
        'Impossible de récupérer les tickets: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Copier les identifiants d'un ticket
  void copyTicketCredentials(UserTicketModel ticket) {
    if (ticket.credentials == null) {
      Get.snackbar(
        'Information',
        'Aucun identifiant disponible pour ce ticket',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final credentialsText = ticket.credentialsText;
    
    Clipboard.setData(ClipboardData(text: credentialsText));
    
    _logger.logUserAction('copy_ticket_credentials', details: {
      'transactionId': ticket.transactionId,
      'planName': ticket.planName,
    });

    Get.snackbar(
      'Copié!',
      'Les identifiants ont été copiés dans le presse-papiers',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 2),
    );
  }

  // Copier un identifiant spécifique
  void copySpecificCredential(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    
    Get.snackbar(
      'Copié!',
      '$label copié dans le presse-papiers',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 1),
    );
  }

  // Rafraîchir la recherche
  Future<void> refreshSearch() async {
    if (searchedPhoneNumber.value.isNotEmpty) {
      await searchTickets();
    }
  }

  // Effacer la recherche
  void clearSearch() {
    phoneController.clear();
    tickets.clear();
    searchedPhoneNumber.value = '';
  }
}