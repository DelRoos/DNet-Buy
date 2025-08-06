import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';
import 'package:dnet_buy/shared/utils/validators.dart';

enum PaymentStatus { idle, pending, success, failed }

class PortalController extends GetxController {
  final box = GetStorage();

  var isLoading = true.obs;
  var ticketTypes = <TicketTypeModel>[].obs;
  var purchasedTickets = <PurchasedTicketModel>[].obs;

  var paymentStatus = PaymentStatus.idle.obs;
  var paymentMessage = ''.obs;
  var finalTicket = Rx<PurchasedTicketModel?>(null);

  final phoneController = TextEditingController();
  var isPhoneNumberValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_validatePhoneNumber);
    loadPurchasedTickets();
    fetchTicketTypes();
  }

  void _validatePhoneNumber() {
    final isValid =
        Validators.validateCameroonianPhoneNumber(phoneController.text) == null;

    if (isValid != isPhoneNumberValid.value) {
      isPhoneNumberValid.value = isValid;
    }
  }
Future<void> fetchTicketTypes() async {
  isLoading.value = true;
  await Future.delayed(const Duration(seconds: 1));

  final now = DateTime.now();

  ticketTypes.assignAll([
    TicketTypeModel(
      id: 'daypass',
      zoneId: 'zone_a',
      name: 'Pass Journée',
      description: 'Accès internet illimité pendant 24 heures.',
      price: 1000,
      validity: '24h',
      validityHours: 24,
      expirationAfterCreation: 30,
      nbMaxUtilisations: 1,
      isActive: true,
      totalTicketsGenerated: 50,
      ticketsSold: 30,
      ticketsAvailable: 20,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
      metadata: {
        'color': 'blue',
        'speedLimit': '2Mbps',
        'recommendedUse': 'travail',
      },
    ),
    TicketTypeModel(
      id: 'eveningplan',
      zoneId: 'zone_a',
      name: 'Forfait Soirée',
      description: 'Accès de 18h à minuit, idéal pour le streaming.',
      price: 500,
      validity: '6h',
      validityHours: 6,
      expirationAfterCreation: 7,
      nbMaxUtilisations: 1,
      isActive: true,
      totalTicketsGenerated: 100,
      ticketsSold: 95,
      ticketsAvailable: 5,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now,
      metadata: {
        'color': 'purple',
        'speedLimit': '1Mbps',
        'recommendedUse': 'divertissement',
      },
    ),
    TicketTypeModel(
      id: 'boost1h',
      zoneId: 'zone_b',
      name: 'Boost 1 Heure',
      description: 'Accès rapide pendant 1 heure.',
      price: 200,
      validity: '1h',
      validityHours: 1,
      expirationAfterCreation: 1,
      nbMaxUtilisations: 1,
      isActive: true,
      totalTicketsGenerated: 25,
      ticketsSold: 25,
      ticketsAvailable: 0,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
      metadata: {
        'color': 'orange',
        'speedLimit': '3Mbps',
        'recommendedUse': 'consultation rapide',
      },
    ),
  ]);

  isLoading.value = false;
}

  // --- LOGIQUE DE PAIEMENT SIMULÉE ---
  Future<void> initiatePayment(TicketTypeModel selectedTicket) async {
    if (!isPhoneNumberValid.value) {
      paymentMessage.value = "Veuillez entrer un numéro valide.";
      return;
    }

    paymentStatus.value = PaymentStatus.pending;
    paymentMessage.value =
        "Paiement en cours... Veuillez valider sur votre téléphone.";

    await Future.delayed(
      const Duration(seconds: 5),
    );

    bool isSuccess = (DateTime.now().second % 2 == 0);

    if (isSuccess) {
      paymentStatus.value = PaymentStatus.success;
      paymentMessage.value = "Paiement réussi ! Voici votre ticket.";

      final purchased = PurchasedTicketModel(
        transactionId: 'trans_${DateTime.now().millisecondsSinceEpoch}',
        ticketTypeName: selectedTicket.name,
        price: selectedTicket.price,
        username: 'user-${DateTime.now().second}',
        password: 'pwd-${DateTime.now().minute}',
        purchaseDate: DateTime.now(),
      );
      finalTicket.value = purchased;
      saveTicket(purchased);
    } else {
      paymentStatus.value = PaymentStatus.failed;
      paymentMessage.value = "Le paiement a échoué. Veuillez réessayer.";
    }
  }

  void resetPayment() {
    paymentStatus.value = PaymentStatus.idle;
    phoneController.clear();
    paymentMessage.value = '';
    finalTicket.value = null;
    phoneController.clear();
    Get.back();
  }

  @override
  void onClose() {
    phoneController.removeListener(_validatePhoneNumber);
    phoneController.dispose();
    super.onClose();
  }

  void saveTicket(PurchasedTicketModel ticket) {
    List<dynamic> storedTickets = box.read<List>('purchasedTickets') ?? [];
    storedTickets.add(ticket.toJson());
    box.write('purchasedTickets', storedTickets);
    loadPurchasedTickets();
  }

  void loadPurchasedTickets() {
    List<dynamic>? storedTickets = box.read<List>('purchasedTickets');
    if (storedTickets != null) {
      purchasedTickets.value = storedTickets
          .map(
            (e) => PurchasedTicketModel.fromJson(e as Map<String, dynamic>),
          )
          .toList()
          .reversed
          .toList();
    }
  }
}
