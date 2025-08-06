// lib/app/services/ticket_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';

class TicketService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = LoggerService.to;

  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');

  @override
  void onInit() {
    super.onInit();
    _logger.info('🎟️ TicketService initialisé', category: 'SERVICE');
  }

  /// Vérifie si un ticket avec le même nom d'utilisateur existe déjà dans une zone spécifique.
  Future<bool> doesTicketExist(String username, String zoneId) async {
    try {
      _logger.debug(
        'Vérification de l\'existence du ticket: $username dans la zone: $zoneId',
        category: 'TICKET_SERVICE',
      );

      final querySnapshot = await _ticketsCollection
          .where('username', isEqualTo: username)
          .where('zoneId', isEqualTo: zoneId)
          .limit(1)
          .get();

      final bool exists = querySnapshot.docs.isNotEmpty;
      if (exists) {
        _logger.warning(
          'Un ticket avec le nom d\'utilisateur "$username" existe déjà dans cette zone.',
          category: 'TICKET_SERVICE',
        );
      }
      return exists;
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la vérification de l\'existence du ticket',
        error: e,
        stackTrace: stackTrace,
        category: 'TICKET_SERVICE',
      );
      // En cas d'erreur, on considère que le ticket n'existe pas pour ne pas bloquer.
      // Une meilleure gestion des erreurs pourrait être nécessaire.
      return false;
    }
  }

  /// Crée un nouveau ticket dans Firestore.
  Future<void> createTicket(Map<String, dynamic> ticketData) async {
    try {
      _logger.debug(
        'Création d\'un nouveau ticket: ${ticketData['username']}',
        category: 'TICKET_SERVICE',
        data: ticketData,
      );

      // On s'attend à ce que ticketData contienne username, password, zoneId, ticketTypeId
      final completeData = {
        ...ticketData,
        'status': 'available', // Statut par défaut
        'createdAt': FieldValue.serverTimestamp(),
        'soldAt': null,
        'firstUsedAt': null,
        'buyerPhoneNumber': null,
        'paymentReference': null,
      };

      await _ticketsCollection.add(completeData);

      _logger.info(
        '✅ Ticket créé avec succès: ${ticketData['username']}',
        category: 'TICKET_SERVICE',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de la création du ticket',
        error: e,
        stackTrace: stackTrace,
        category: 'TICKET_SERVICE',
      );
      // Rethrow pour que le contrôleur puisse gérer l'erreur
      rethrow;
    }
  }
}
