// lib/app/services/zone_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';

class ZoneService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggerService _logger = LoggerService.to;

  // Collection references
  CollectionReference get _zonesCollection => _firestore.collection('zones');
  CollectionReference get _ticketTypesCollection =>
      _firestore.collection('ticket_types');

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _logger.info('🏗️ ZoneService initialisé', category: 'SERVICE');
  }

  // Récupérer toutes les zones d'un marchand
  Future<List<ZoneModel>> getZones() async {
    try {
      _logger.debug('Récupération des zones pour marchand: $currentUserId');

      if (currentUserId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final querySnapshot = await _zonesCollection
          .where('merchantId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final zones = querySnapshot.docs
          .map((doc) => ZoneModel.fromFirestore(doc))
          .toList();

      _logger.info('✅ ${zones.length} zones récupérées',
          category: 'ZONE_SERVICE',
          data: {'count': zones.length, 'merchantId': currentUserId});

      return zones;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la récupération des zones',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Récupérer une zone spécifique
  Future<ZoneModel?> getZone(String zoneId) async {
    try {
      _logger.debug('Récupération de la zone: $zoneId');

      final docSnapshot = await _zonesCollection.doc(zoneId).get();

      if (!docSnapshot.exists) {
        _logger.warning('Zone non trouvée: $zoneId', category: 'ZONE_SERVICE');
        return null;
      }

      final zone = ZoneModel.fromFirestore(docSnapshot);

      // Vérifier que la zone appartient au marchand actuel
      if (zone.merchantId != currentUserId) {
        _logger.warning('Accès refusé à la zone: $zoneId',
            category: 'ZONE_SERVICE',
            data: {'zoneOwner': zone.merchantId, 'currentUser': currentUserId});
        throw Exception('Accès non autorisé à cette zone');
      }

      _logger.info('✅ Zone récupérée: ${zone.name}',
          category: 'ZONE_SERVICE',
          data: {'zoneId': zoneId, 'zoneName': zone.name});

      return zone;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la récupération de la zone',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Créer une nouvelle zone
  Future<String> createZone(Map<String, dynamic> zoneData) async {
    try {
      _logger.debug('Création d\'une nouvelle zone');

      if (currentUserId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Ajouter les métadonnées
      final completeZoneData = {
        ...zoneData,
        'merchantId': currentUserId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _zonesCollection.add(completeZoneData);

      _logger.logUserAction('zone_created', details: {
        'zoneId': docRef.id,
        'zoneName': zoneData['name'],
        'routerType': zoneData['routerType'],
      });

      _logger.info('✅ Zone créée avec succès: ${docRef.id}',
          category: 'ZONE_SERVICE',
          data: {
            'zoneId': docRef.id,
            'zoneName': zoneData['name'],
            'merchantId': currentUserId
          });

      return docRef.id;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la création de la zone',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Mettre à jour une zone
  Future<void> updateZone(
      String zoneId, Map<String, dynamic> updateData) async {
    try {
      _logger.debug('Mise à jour de la zone: $zoneId');

      // Vérifier d'abord que la zone appartient au marchand
      final zone = await getZone(zoneId);
      if (zone == null) {
        throw Exception('Zone non trouvée');
      }

      final completeUpdateData = {
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _zonesCollection.doc(zoneId).update(completeUpdateData);

      _logger.logUserAction('zone_updated', details: {
        'zoneId': zoneId,
        'updatedFields': updateData.keys.toList(),
      });

      _logger.info('✅ Zone mise à jour: $zoneId',
          category: 'ZONE_SERVICE',
          data: {'zoneId': zoneId, 'updatedFields': updateData.keys.toList()});
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la mise à jour de la zone',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Activer/Désactiver une zone
  Future<void> toggleZoneStatus(String zoneId, bool isActive) async {
    try {
      _logger.debug('Changement du statut de la zone: $zoneId -> $isActive');

      await updateZone(zoneId, {'isActive': isActive});

      _logger.logUserAction('zone_status_changed', details: {
        'zoneId': zoneId,
        'newStatus': isActive ? 'active' : 'inactive',
      });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du changement de statut de la zone',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Supprimer une zone (suppression logique)
  Future<void> deleteZone(String zoneId) async {
    try {
      _logger.debug('Suppression de la zone: $zoneId');

      // Vérifier d'abord si la zone a des types de tickets actifs
      final ticketTypesQuery = await _ticketTypesCollection
          .where('zoneId', isEqualTo: zoneId)
          .where('isActive', isEqualTo: true)
          .get();

      if (ticketTypesQuery.docs.isNotEmpty) {
        throw Exception(
            'Impossible de supprimer une zone avec des forfaits actifs');
      }

      // Suppression logique
      await updateZone(zoneId, {
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      _logger.logUserAction('zone_deleted', details: {
        'zoneId': zoneId,
        'deletionType': 'soft_delete',
      });

      _logger.info('✅ Zone supprimée: $zoneId',
          category: 'ZONE_SERVICE',
          data: {'zoneId': zoneId, 'deletionType': 'soft_delete'});
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la suppression de la zone',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Stream pour écouter les changements en temps réel
  Stream<List<ZoneModel>> watchZones() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    _logger.debug('Ouverture du stream des zones pour: $currentUserId');

    return _zonesCollection
        .where('merchantId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((querySnapshot) {
      final zones = querySnapshot.docs
          .map((doc) => ZoneModel.fromFirestore(doc))
          .toList();

      _logger.debug('Stream zones mis à jour: ${zones.length} zones',
          category: 'ZONE_SERVICE');

      return zones;
    });
  }

  // Générer des statistiques sur les zones
  Future<Map<String, dynamic>> getZoneStats() async {
    try {
      _logger.debug('Génération des statistiques des zones');

      if (currentUserId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final querySnapshot = await _zonesCollection
          .where('merchantId', isEqualTo: currentUserId)
          .get();

      final zones = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final stats = {
        'totalZones': zones.length,
        'activeZones': zones.where((z) => z['isActive'] == true).length,
        'inactiveZones': zones.where((z) => z['isActive'] == false).length,
        'routerTypes': _getRouterTypesDistribution(zones),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      _logger.info('✅ Statistiques des zones générées',
          category: 'ZONE_SERVICE', data: stats);

      return stats;
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de la génération des statistiques',
          error: e, stackTrace: stackTrace, category: 'ZONE_SERVICE');
      rethrow;
    }
  }

  // Helper pour analyser la distribution des types de routeurs
  Map<String, int> _getRouterTypesDistribution(
      List<Map<String, dynamic>> zones) {
    final distribution = <String, int>{};

    for (final zone in zones) {
      final routerType = zone['routerType'] as String? ?? 'Non spécifié';
      distribution[routerType] = (distribution[routerType] ?? 0) + 1;
    }

    return distribution;
  }
}
