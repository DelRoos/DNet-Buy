import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/manual_sale_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_model.dart';

class ManualSaleController extends GetxController {
  final ManualSaleService _manualSaleService = ManualSaleService();
  final LoggerService _logger = LoggerService.to;

  // Formulaire
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();

  // États
  var isLoading = false.obs;
  var selectedTicket = Rx<TicketModel?>(null);
  var lastSaleResult = Rx<ManualSaleResult?>(null);

  @override
  void onClose() {
    phoneController.dispose();
    descriptionController.dispose();
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

  // Sélectionner un ticket
  void selectTicket(TicketModel ticket) {
    if (ticket.status != 'available') {
      Get.snackbar(
        'Erreur',
        'Ce ticket n\'est pas disponible pour la vente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    selectedTicket.value = ticket;
    _logger.logUserAction('ticket_selected_for_manual_sale', details: {
      'ticketId': ticket.id,
      'username': ticket.username,
    });
  }

  // Désélectionner le ticket
  void deselectTicket() {
    selectedTicket.value = null;
    lastSaleResult.value = null;
  }

  // Effectuer la vente
  Future<void> sellTicket() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedTicket.value == null) {
      Get.snackbar('Erreur', 'Aucun ticket sélectionné');
      return;
    }

    try {
      isLoading.value = true;

      final result = await _manualSaleService.sellTicketManually(
        ticketId: selectedTicket.value!.id,
        phoneNumber: phoneController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      if (result.isSuccess) {
        lastSaleResult.value = result;

        // Copier automatiquement les identifiants
        _copyCredentialsToClipboard(result.credentials!);

        Get.snackbar(
          'Vente réussie!',
          'Le ticket a été vendu et les identifiants ont été copiés dans le presse-papiers',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        );

        _logger.logUserAction('manual_sale_completed', details: {
          'transactionId': result.transactionId,
          'ticketId': selectedTicket.value!.id,
          'phoneNumber': phoneController.text.trim(),
        });

        // Réinitialiser le formulaire
        _resetForm();
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
      isLoading.value = false;
    }
  }

  // Copier les identifiants dans le presse-papiers
  void _copyCredentialsToClipboard(TicketCredentials credentials) {
    Clipboard.setData(ClipboardData(text: credentials.formattedCredentials));
  }

  // Copier manuellement les identifiants
  void copyCredentials() {
    if (lastSaleResult.value?.credentials != null) {
      _copyCredentialsToClipboard(lastSaleResult.value!.credentials!);
      Get.snackbar(
        'Copié!',
        'Identifiants copiés dans le presse-papiers',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Réinitialiser le formulaire
  void _resetForm() {
    phoneController.clear();
    descriptionController.clear();
    selectedTicket.value = null;
  }

  // Effacer les résultats
  void clearResults() {
    lastSaleResult.value = null;
    _resetForm();
  }
}
