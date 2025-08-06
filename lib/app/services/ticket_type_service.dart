// lib/app/services/ticket_type_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketTypeService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggerService _logger = LoggerService.to;

  // Collections
  CollectionReference get _ticketTypesCollection =>
      _firestore.collection('ticket_types');
  CollectionReference get _zonesCollection => _firestore.collection('zones');
  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _logger.info('🎫 TicketTypeService initialisé', category: 'SERVICE');
  }

  // Récupérer tous les types de tickets d'une zone
  Future<List<TicketTypeModel>> getTicketTypes(String zoneId) async {
    try {
      _logger.debug('Récupération des types de tickets pour zone: $zoneId');

      // Vérifier que la zone appartient au marchand
      await _verifyZoneOwnership(zoneId);

      final querySnapshot = await _ticketTypesCollection
          .where('zoneId', isEqualTo: zoneId)
          .orderBy('createdAt', descending: false)
          .get();

      final ticketTypes = querySnapshot.docs
          .map((doc) => TicketTypeModel.fromFirestore(doc))
          .toList();

      _logger.info('✅ ${ticketTypes.length} types de tickets récupérés',
          category: 'TICKET_TYPE_SERVICE',
          data: {'zoneId': zoneId, 'count': ticketTypes.length});

      return ticketTypes;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la récupération des types de tickets',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Récupérer un type de ticket spécifique
  Future<TicketTypeModel?> getTicketType(String ticketTypeId) async {
    try {
      _logger.debug('Récupération du type de ticket: $ticketTypeId');

      final docSnapshot = await _ticketTypesCollection.doc(ticketTypeId).get();

      if (!docSnapshot.exists) {
        _logger.warning('Type de ticket non trouvé: $ticketTypeId',
            category: 'TICKET_TYPE_SERVICE');
        return null;
      }

      final ticketType = TicketTypeModel.fromFirestore(docSnapshot);

      // Vérifier que la zone appartient au marchand
      await _verifyZoneOwnership(ticketType.zoneId);

      _logger.info('✅ Type de ticket récupéré: ${ticketType.name}',
          category: 'TICKET_TYPE_SERVICE',
          data: {'ticketTypeId': ticketTypeId, 'name': ticketType.name});

      return ticketType;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la récupération du type de ticket',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Créer un nouveau type de ticket
  Future<String> createTicketType(Map<String, dynamic> ticketTypeData) async {
    try {
      _logger.debug('Création d\'un nouveau type de ticket');

      final zoneId = ticketTypeData['zoneId'] as String;
      await _verifyZoneOwnership(zoneId);

      // Ajouter les métadonnées
      final completeData = {
        ...ticketTypeData,
        'isActive': true,
        'totalTicketsGenerated': 0,
        'ticketsSold': 0,
        'ticketsAvailable': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _ticketTypesCollection.add(completeData);

      _logger.logUserAction('ticket_type_created', details: {
        'ticketTypeId': docRef.id,
        'name': ticketTypeData['name'],
        'zoneId': zoneId,
        'price': ticketTypeData['price'],
      });

      _logger.info('✅ Type de ticket créé: ${docRef.id}',
          category: 'TICKET_TYPE_SERVICE',
          data: {
            'ticketTypeId': docRef.id,
            'name': ticketTypeData['name'],
            'zoneId': zoneId
          });

      return docRef.id;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la création du type de ticket',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Mettre à jour un type de ticket
  Future<void> updateTicketType(
      String ticketTypeId, Map<String, dynamic> updateData) async {
    try {
      _logger.debug('Mise à jour du type de ticket: $ticketTypeId');

      // Vérifier que le ticket type existe et appartient au marchand
      final ticketType = await getTicketType(ticketTypeId);
      if (ticketType == null) {
        throw Exception('Type de ticket non trouvé');
      }

      // Préparer les données de mise à jour
      final completeUpdateData = {
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour le document
      await _ticketTypesCollection.doc(ticketTypeId).update(completeUpdateData);

      _logger.logUserAction('ticket_type_updated', details: {
        'ticketTypeId': ticketTypeId,
        'updatedFields': updateData.keys.toList(),
        'zoneId': updateData['zoneId'] ?? ticketType.zoneId,
      });

      _logger.info('✅ Type de ticket mis à jour: $ticketTypeId',
          category: 'TICKET_TYPE_SERVICE',
          data: {
            'ticketTypeId': ticketTypeId,
            'updatedFields': updateData.keys.toList()
          });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la mise à jour du type de ticket',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Activer/Désactiver un type de ticket
  Future<void> toggleTicketTypeStatus(
      String ticketTypeId, bool isActive) async {
    try {
      _logger.debug(
          'Changement du statut du type de ticket: $ticketTypeId -> $isActive');

      await updateTicketType(ticketTypeId, {'isActive': isActive});

      _logger.logUserAction('ticket_type_status_changed', details: {
        'ticketTypeId': ticketTypeId,
        'newStatus': isActive ? 'active' : 'inactive',
      });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du changement de statut du type de ticket',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Supprimer un type de ticket
  Future<void> deleteTicketType(String ticketTypeId) async {
    try {
      _logger.debug('Suppression du type de ticket: $ticketTypeId');

      // Vérifier s'il y a des tickets vendus
      final soldTicketsQuery = await _ticketsCollection
          .where('ticketTypeId', isEqualTo: ticketTypeId)
          .where('status', isEqualTo: 'sold')
          .limit(1)
          .get();

      if (soldTicketsQuery.docs.isNotEmpty) {
        throw Exception(
            'Impossible de supprimer un type de ticket avec des ventes');
      }

      // Suppression logique
      await updateTicketType(ticketTypeId, {
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      _logger.logUserAction('ticket_type_deleted', details: {
        'ticketTypeId': ticketTypeId,
        'deletionType': 'soft_delete',
      });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la suppression du type de ticket',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Générer des statistiques pour un type de ticket
  Future<Map<String, dynamic>> getTicketTypeStats(String ticketTypeId) async {
    try {
      _logger.debug(
          'Génération des statistiques pour le type de ticket: $ticketTypeId');

      final ticketType = await getTicketType(ticketTypeId);
      if (ticketType == null) {
        throw Exception('Type de ticket non trouvé');
      }

      // Compter les tickets par statut
      final ticketsQuery = await _ticketsCollection
          .where('ticketTypeId', isEqualTo: ticketTypeId)
          .get();

      final tickets = ticketsQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final availableCount =
          tickets.where((t) => t['status'] == 'available').length;
      final soldCount = tickets.where((t) => t['status'] == 'sold').length;
      final usedCount = tickets.where((t) => t['firstUsedAt'] != null).length;

      // Calculer les revenus
      final totalRevenue = soldCount * ticketType.price;

      // Statistiques de ventes par période
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final todaySales = tickets.where((t) {
        final soldAt = (t['soldAt'] as Timestamp?)?.toDate();
        return soldAt != null && soldAt.isAfter(todayStart);
      }).length;

      final weekSales = tickets.where((t) {
        final soldAt = (t['soldAt'] as Timestamp?)?.toDate();
        return soldAt != null && soldAt.isAfter(weekStart);
      }).length;

      final monthSales = tickets.where((t) {
        final soldAt = (t['soldAt'] as Timestamp?)?.toDate();
        return soldAt != null && soldAt.isAfter(monthStart);
      }).length;

      final stats = {
        'ticketTypeId': ticketTypeId,
        'ticketTypeName': ticketType.name,
        'totalTickets': tickets.length,
        'availableTickets': availableCount,
        'soldTickets': soldCount,
        'usedTickets': usedCount,
        'totalRevenue': totalRevenue,
        'todaySales': todaySales,
        'weekSales': weekSales,
        'monthSales': monthSales,
        'conversionRate': tickets.isNotEmpty
            ? (usedCount / soldCount * 100).toStringAsFixed(1)
            : '0.0',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      _logger.info('✅ Statistiques générées pour le type de ticket',
          category: 'TICKET_TYPE_SERVICE', data: stats);

      return stats;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la génération des statistiques',
          error: e, stackTrace: stackTrace, category: 'TICKET_TYPE_SERVICE');
      rethrow;
    }
  }

  // Générer le lien de paiement
  String generatePaymentLink(
      String zoneId, String ticketTypeId, String merchantId) {
    const baseUrl = 'https://app.dnet.com';
    final paymentUrl =
        '$baseUrl/buy?merchantId=$merchantId&zoneId=$zoneId&typeId=$ticketTypeId';

    _logger.logUserAction('payment_link_generated', details: {
      'zoneId': zoneId,
      'ticketTypeId': ticketTypeId,
      'merchantId': merchantId,
    });

    return paymentUrl;
  }

  // Stream pour écouter les changements
  Stream<List<TicketTypeModel>> watchTicketTypes(String zoneId) {
    _logger
        .debug('Ouverture du stream des types de tickets pour zone: $zoneId');

    return _ticketTypesCollection
        .where('zoneId', isEqualTo: zoneId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((querySnapshot) {
      final ticketTypes = querySnapshot.docs
          .map((doc) => TicketTypeModel.fromFirestore(doc))
          .toList();

      _logger.debug('Stream types de tickets mis à jour: ${ticketTypes.length}',
          category: 'TICKET_TYPE_SERVICE');

      return ticketTypes;
    });
  }

  // Vérifier que la zone appartient au marchand actuel
  Future<void> _verifyZoneOwnership(String zoneId) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final zoneDoc = await _zonesCollection.doc(zoneId).get();
    if (!zoneDoc.exists) {
      throw Exception('Zone non trouvée');
    }

    final zoneData = zoneDoc.data() as Map<String, dynamic>;
    if (zoneData['merchantId'] != currentUserId) {
      throw Exception('Accès non autorisé à cette zone');
    }
  }
}
