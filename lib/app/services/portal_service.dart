import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

class PortalService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = LoggerService.to;

  // Références aux collections
  CollectionReference get _ticketTypesCollection =>
      _firestore.collection('ticket_types');
  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');
  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');

  @override
  void onInit() {
    super.onInit();
    _logger.info('🌐 PortalService initialisé', category: 'SERVICE');
  }

  // Récupérer un type de ticket spécifique
  Future<TicketTypeModel?> getTicketType(String ticketTypeId) async {
    try {
      _logger.debug('Récupération du type de ticket: $ticketTypeId',
          category: 'PORTAL_SERVICE');
      final docSnapshot = await _ticketTypesCollection.doc(ticketTypeId).get();

      if (!docSnapshot.exists) {
        _logger.warning('Type de ticket non trouvé: $ticketTypeId',
            category: 'PORTAL_SERVICE');
        return null;
      }
      return TicketTypeModel.fromFirestore(docSnapshot);
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la récupération du type de ticket',
          error: e, stackTrace: stackTrace, category: 'PORTAL_SERVICE');
      return null;
    }
  }

  // Récupérer un ticket déjà vendu par son ID
  Future<PurchasedTicketModel?> getPurchasedTicket(String ticketId) async {
    try {
      _logger.debug("Récupération du ticket acheté $ticketId",
          category: 'PORTAL_SERVICE');
      final docSnapshot = await _ticketsCollection.doc(ticketId).get();
      if (!docSnapshot.exists) {
        _logger.warning("Ticket acheté non trouvé: $ticketId",
            category: 'PORTAL_SERVICE');
        return null;
      }
      return PurchasedTicketModel.fromFirestore(docSnapshot);
    } catch (e, stackTrace) {
      _logger.error("Erreur lors de la récupération du ticket acheté",
          error: e, stackTrace: stackTrace, category: 'PORTAL_SERVICE');
      return null;
    }
  }

  // Récupérer un ticket par son ID de transaction
  Future<PurchasedTicketModel?> getTicketByTransactionId(
      String transactionId) async {
    try {
      _logger.debug('Récupération du ticket par transaction: $transactionId',
          category: 'PORTAL_SERVICE');
      final querySnapshot = await _ticketsCollection
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.warning(
            'Aucun ticket trouvé pour la transaction: $transactionId',
            category: 'PORTAL_SERVICE');
        return null;
      }

      _logger.info('Ticket récupéré avec succès par transaction ID',
          category: 'PORTAL_SERVICE', data: {'transactionId': transactionId});
      final ticketDoc = querySnapshot.docs.first;
      return PurchasedTicketModel.fromFirestore(ticketDoc);
    } catch (e, stackTrace) {
      _logger.error(
          'Erreur lors de la récupération du ticket par transaction ID',
          error: e,
          stackTrace: stackTrace,
          category: 'PORTAL_SERVICE');
      return null;
    }
  }

  // Fournit un Stream pour écouter les changements sur un document de transaction
  Stream<DocumentSnapshot> listenToTransaction(String transactionId) {
    _logger.debug(
        "Mise en place de l'écouteur pour la transaction $transactionId",
        category: 'PORTAL_SERVICE');
    return _transactionsCollection.doc(transactionId).snapshots();
  }
}
