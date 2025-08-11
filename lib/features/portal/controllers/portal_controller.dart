import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/app/services/portal_service.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

enum PaymentStatus { idle, pending, verifying, success, failed }

enum ConnectionStatus { online, offline }

enum PaymentPageStatus {
  loading, // Chargement initial des détails du forfait
  idle, // Affichage du formulaire de paiement
  checking, // Appel à la fonction pour initier le paiement
  outOfStock, // Forfait épuisé
  fetchingCredentials, // ✅ NOUVEAU STATUT
  pending, // En attente de la validation de l'utilisateur
  success, // Paiement réussi
  failed, // Paiement échoué
}

class PortalController extends GetxController {
  final PortalService _portalService = Get.find<PortalService>();
  final LoggerService _logger = LoggerService.to;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  late TextEditingController phoneController;
  var ticketTypeDetails = Rx<TicketTypeModel?>(null);
  var finalTicket = Rx<PurchasedTicketModel?>(null);
  var isPhoneNumberValid = false.obs;
  var pageStatus = PaymentPageStatus.loading.obs;
  var errorMessage = ''.obs;

  StreamSubscription<DocumentSnapshot>? _transactionSubscription;
  Timer? _timeoutTimer;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
    phoneController.addListener(_validatePhone);

    final ticketTypeId = Get.parameters['ticketTypeId'];
    if (ticketTypeId == null) {
      _handleError("Le lien est invalide ou incomplet.");
      return;
    }

    loadTicketTypeDetails(ticketTypeId);
  }

  void _validatePhone() {
    final text = phoneController.text.trim();
    isPhoneNumberValid.value = RegExp(r'^6\d{8}$').hasMatch(text);
  }

  Future<void> loadTicketTypeDetails(String ticketTypeId) async {
    try {
      pageStatus.value = PaymentPageStatus.loading;
      final details = await _portalService.getTicketType(ticketTypeId);
      if (details == null || !details.isActive) {
        throw Exception("Forfait inactif ou introuvable.");
      }
      ticketTypeDetails.value = details;
      pageStatus.value = PaymentPageStatus.idle;
    } catch (e) {
      _handleError("Ce forfait n'est pas accessible.", e);
    }
  }

  Future<void> initiatePaymentProcess() async {
    if (!isPhoneNumberValid.value || ticketTypeDetails.value == null) return;

    pageStatus.value = PaymentPageStatus.checking;
    try {
      final callable = _functions.httpsCallable('initiatePublicPayment');
      final response = await callable.call<Map<String, dynamic>>({
        'ticketTypeId': ticketTypeDetails.value!.id,
        'phoneNumber': phoneController.text,
      });

      final transactionId = response.data['transactionId'];
      if (transactionId == null) throw Exception("transactionId manquant");

      pageStatus.value = PaymentPageStatus.pending;

      // ✅ AJOUTER UN DÉLAI AVANT L'ÉCOUTE
      await Future.delayed(const Duration(milliseconds: 500));
      _listenForTransactionUpdates(transactionId);

      // Timeout sécurité
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(minutes: 3), () {
        if (pageStatus.value == PaymentPageStatus.pending) {
          _handleError("Délai d'attente dépassé. Veuillez réessayer.");
        }
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'out-of-range') {
        pageStatus.value = PaymentPageStatus.outOfStock;
      } else {
        _handleError(e.message ?? "Erreur de paiement", e);
      }
    } catch (e) {
      _handleError("Erreur réseau ou serveur.", e);
    }
  }

  void _listenForTransactionUpdates(String transactionId) {
    _transactionSubscription?.cancel();

    _transactionSubscription =
        _portalService.listenToTransaction(transactionId).listen(
      (snapshot) async {
        if (!snapshot.exists) {
          // ✅ ATTENDRE QUE LA TRANSACTION SOIT CRÉÉE
          _logger.debug("Transaction pas encore créée, attente...");
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return;

        final status = data['status'];
        final ticketId = data['ticketId'];
        final failureReason = data['failureReason'];

        _logger.info("État transaction: $status");

        if (status == 'completed') {
          pageStatus.value = PaymentPageStatus.success;
          if (ticketId != null) {
            try {
              final ticket = await _portalService.getPurchasedTicket(ticketId);
              finalTicket.value = ticket;
            } catch (e) {
              _logger.error("Erreur récupération ticket", error: e);
            }
          }
          _clearListeners();
        } else if (status == 'failed') {
          _handleError(failureReason ?? "Le paiement a échoué.");
        }
        // ✅ GARDER LE STATUT PENDING POUR LES AUTRES CAS
      },
      onError: (error) {
        _logger.error("Erreur écoute transaction", error: error);
        // ✅ NE PAS ÉCHOUER IMMÉDIATEMENT, RETRY
        _handleError("Erreur de connexion. Vérification en cours...");
      },
    );
  }

  void retryPayment() {
    pageStatus.value = PaymentPageStatus.idle;
    errorMessage.value = '';
    finalTicket.value = null;
  }

  void copyCredentials() {
    if (finalTicket.value == null) return;
    final ticket = finalTicket.value!;
    final creds =
        'Utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}';
    Clipboard.setData(ClipboardData(text: creds));
    Get.snackbar('Copié', 'Identifiants copiés dans le presse-papiers.',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _handleError(String message, [dynamic error]) {
    _logger.error("Erreur : $message", error: error);
    pageStatus.value = PaymentPageStatus.failed;
    errorMessage.value = message;
    _clearListeners();
  }

  void _clearListeners() {
    _transactionSubscription?.cancel();
    _timeoutTimer?.cancel();
  }

  @override
  void onClose() {
    _clearListeners();
    phoneController.dispose();
    super.onClose();
  }
}
