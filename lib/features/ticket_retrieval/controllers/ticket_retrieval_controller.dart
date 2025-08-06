import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/app/services/portal_service.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

enum RetrievalStatus { idle, loading, success, error }

class TicketRetrievalController extends GetxController {
  final PortalService _portalService = Get.find<PortalService>();
  final LoggerService _logger = LoggerService.to;

  // Formulaire
  final formKey = GlobalKey<FormState>();
  final transactionIdController = TextEditingController();

  // États
  var status = RetrievalStatus.idle.obs;
  var errorMessage = ''.obs;
  var retrievedTicket = Rx<PurchasedTicketModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _logger.info('🚀 TicketRetrievalController initialisé',
        category: 'CONTROLLER');
  }

  // Valider l'ID de transaction
  String? validateTransactionId(String? value) {
    _logger.debug('Validation de l\'ID de transaction',
        category: 'TICKET_RETRIEVAL_CONTROLLER',
        data: {'value': value?.length});

    if (value == null || value.isEmpty) {
      _logger.debug('ID de transaction vide',
          category: 'TICKET_RETRIEVAL_CONTROLLER');
      return 'Veuillez entrer l\'ID de transaction';
    }

    // Validation de base (peut être adaptée selon le format réel)
    if (value.length < 6) {
      _logger.debug('ID de transaction trop court',
          category: 'TICKET_RETRIEVAL_CONTROLLER',
          data: {'length': value.length});
      return 'ID de transaction invalide (trop court)';
    }

    return null;
  }

  // Récupérer un ticket
  Future<void> retrieveTicket() async {
    if (!formKey.currentState!.validate()) {
      _logger.debug('Validation du formulaire échouée',
          category: 'TICKET_RETRIEVAL_CONTROLLER');
      return;
    }

    try {
      status.value = RetrievalStatus.loading;
      errorMessage.value = '';
      retrievedTicket.value = null;

      final transactionId = transactionIdController.text.trim();
      _logger.info('Début de récupération de ticket',
          category: 'TICKET_RETRIEVAL_CONTROLLER',
          data: {'transactionId': transactionId});

      _logger.debug('Appel au service portal pour récupération',
          category: 'TICKET_RETRIEVAL_CONTROLLER');

      final ticket =
          await _portalService.getTicketByTransactionId(transactionId);

      if (ticket == null) {
        _logger.warning('Aucun ticket trouvé',
            category: 'TICKET_RETRIEVAL_CONTROLLER',
            data: {'transactionId': transactionId});

        status.value = RetrievalStatus.error;
        errorMessage.value = 'Aucun ticket trouvé avec cet ID de transaction.';

        _logger.logUserAction('ticket_retrieval_failed', details: {
          'transactionId': transactionId,
          'reason': 'Ticket non trouvé',
        });
        return;
      }

      _logger.info('Ticket récupéré avec succès',
          category: 'TICKET_RETRIEVAL_CONTROLLER',
          data: {
            'transactionId': transactionId,
            'ticketId': ticket.id,
            'ticketStatus': ticket.status,
            'ticketTypeName': ticket.ticketTypeName
          });

      retrievedTicket.value = ticket;
      status.value = RetrievalStatus.success;

      _logger.logUserAction('ticket_retrieval_success', details: {
        'transactionId': transactionId,
        'ticketId': ticket.id,
      });
    } catch (e) {
      _logger.error('Erreur lors de la récupération du ticket',
          error: e,
          category: 'TICKET_RETRIEVAL_CONTROLLER',
          data: {'transactionId': transactionIdController.text.trim()});

      status.value = RetrievalStatus.error;
      errorMessage.value =
          'Une erreur est survenue lors de la récupération du ticket.';

      _logger.logUserAction('ticket_retrieval_error', details: {
        'transactionId': transactionIdController.text.trim(),
        'error': e.toString(),
      });
    }
  }

  // Réinitialiser le formulaire
  void resetForm() {
    _logger.debug('Réinitialisation du formulaire de récupération',
        category: 'TICKET_RETRIEVAL_CONTROLLER');

    transactionIdController.clear();
    status.value = RetrievalStatus.idle;
    errorMessage.value = '';
    retrievedTicket.value = null;
  }

  @override
  void onClose() {
    _logger.debug('Fermeture du TicketRetrievalController',
        category: 'TICKET_RETRIEVAL_CONTROLLER');
    transactionIdController.dispose();
    super.onClose();
  }
}
