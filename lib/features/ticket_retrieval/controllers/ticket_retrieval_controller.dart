import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

// Énumération pour gérer l'état de la recherche
enum SearchStatus { idle, loading, found, notFound, error }

class TicketRetrievalController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final transactionIdController = TextEditingController();

  // États réactifs
  var searchStatus = SearchStatus.idle.obs;
  var errorMessage = ''.obs;
  var foundTicket = Rx<PurchasedTicketModel?>(null);

  // Méthode pour lancer la recherche
  Future<void> findTicket() async {
    if (formKey.currentState!.validate()) {
      searchStatus.value = SearchStatus.loading;
      errorMessage.value = '';
      foundTicket.value = null;

      final transactionId = transactionIdController.text.trim();
      print('Searching for transaction ID: $transactionId');

      await Future.delayed(const Duration(seconds: 2)); // Simule un appel API

      // --- Logique de simulation ---
      // Dans une vraie application, vous feriez une requête à votre backend
      // avec le transactionId pour retrouver le ticket dans Firestore.
      if (transactionId == 'a67691ed-3185-4153-9ede-7dc62601a177') {
        foundTicket.value = PurchasedTicketModel(
          transactionId: transactionId,
          ticketTypeName: 'Pass Journée',
          price: 1000,
          username: 'user-abc1',
          password: 'pwd-xyz2',
          purchaseDate: DateTime.now().subtract(
            const Duration(days: 2, hours: 3),
          ),
        );
        searchStatus.value = SearchStatus.found;
      } else if (transactionId == 'erreur-test') {
        errorMessage.value =
            'Une erreur inattendue est survenue. Veuillez réessayer.';
        searchStatus.value = SearchStatus.error;
      } else {
        searchStatus.value = SearchStatus.notFound;
      }
    }
  }

  // Méthode pour réinitialiser la recherche
  void resetSearch() {
    transactionIdController.clear();
    searchStatus.value = SearchStatus.idle;
    foundTicket.value = null;
    errorMessage.value = '';
  }

  @override
  void onClose() {
    transactionIdController.dispose();
    super.onClose();
  }
}
