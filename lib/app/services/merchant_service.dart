import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/services/logger_service.dart';

class MerchantService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LoggerService _logger = LoggerService.to;

  // Obtenir les données du marchand
  Future<Map<String, dynamic>?> getMerchantData(String uid) async {
    try {
      final doc = await _firestore.collection('merchants').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw 'Erreur lors du chargement des données: $e';
    }
  }

  // Stream des données marchand
  Stream<DocumentSnapshot> getMerchantStream(String uid) {
    return _firestore.collection('merchants').doc(uid).snapshots();
  }

  // Mise à jour des informations personnelles
  Future<void> updatePersonalInfo(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('merchants').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour: $e';
    }
  }

  // Mise à jour des clés API
  Future<void> updateApiKeys(String uid, Map<String, String> keys) async {
    try {
      await _firestore.collection('merchants').doc(uid).update({
        'freemopayKeys': keys,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour des clés: $e';
    }
  }

  // Obtenir les statistiques du marchand
  Future<Map<String, dynamic>> getMerchantStats(String uid) async {
    try {
      // Compter les zones
      final zonesQuery = await _firestore
          .collection('zones')
          .where('merchantId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .get();

      // Compter les transactions du jour
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('merchantId', isEqualTo: uid)
          .where('transactionDate', isGreaterThanOrEqualTo: startOfDay)
          .where('status', isEqualTo: 'success')
          .get();

      // Calculer le revenu total
      double totalRevenue = 0;
      int ticketsSoldToday = 0;

      for (var doc in transactionsQuery.docs) {
        final data = doc.data();
        totalRevenue += (data['amount'] ?? 0).toDouble();
        ticketsSoldToday++;
      }

      return {
        'activeZones': zonesQuery.docs.length,
        'totalRevenue': totalRevenue.toInt(),
        'ticketsSoldToday': ticketsSoldToday,
        'availableTickets': 0, // À calculer selon vos besoins
      };
    } catch (e) {
      throw 'Erreur lors du calcul des statistiques: $e';
    }
  }

  // ================================
  // GESTION DES TOKENS FCM
  // ================================

  /// Sauvegarder le token FCM de l'utilisateur
  Future<void> saveFCMToken(String uid, String token) async {
    try {
      _logger.info('💾 Sauvegarde du token FCM pour l\'utilisateur: $uid');
      
      await _firestore.collection('merchants').doc(uid).set({
        'fcmTokens': {
          'current': token,
          'lastUpdated': FieldValue.serverTimestamp(),
          'deviceInfo': {
            'platform': GetPlatform.isAndroid ? 'android' : 'ios',
            'timestamp': FieldValue.serverTimestamp(),
          }
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logger.info('✅ Token FCM sauvegardé avec succès');
    } catch (e) {
      _logger.error('Erreur lors de la sauvegarde du token FCM', error: e);
      throw 'Erreur lors de la sauvegarde du token: $e';
    }
  }

  /// Écouter les changements de token FCM en temps réel
  Stream<String?> listenToFCMToken(String uid) {
    return _firestore
        .collection('merchants')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['fcmTokens']?['current'] as String?;
      }
      return null;
    });
  }

  /// Supprimer le token FCM (déconnexion)
  Future<void> removeFCMToken(String uid) async {
    try {
      _logger.info('🗑️ Suppression du token FCM pour l\'utilisateur: $uid');
      
      await _firestore.collection('merchants').doc(uid).update({
        'fcmTokens': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('✅ Token FCM supprimé avec succès');
    } catch (e) {
      _logger.error('Erreur lors de la suppression du token FCM', error: e);
      throw 'Erreur lors de la suppression du token: $e';
    }
  }

  /// Obtenir le token FCM d'un utilisateur
  Future<String?> getFCMToken(String uid) async {
    try {
      final doc = await _firestore.collection('merchants').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['fcmTokens']?['current'] as String?;
      }
      return null;
    } catch (e) {
      _logger.error('Erreur lors de la récupération du token FCM', error: e);
      return null;
    }
  }

  /// Mettre à jour le token quand il change
  Future<void> updateFCMToken(String uid, String newToken) async {
    try {
      _logger.info('🔄 Mise à jour du token FCM pour l\'utilisateur: $uid');
      
      await _firestore.collection('merchants').doc(uid).update({
        'fcmTokens.current': newToken,
        'fcmTokens.lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('✅ Token FCM mis à jour avec succès');
    } catch (e) {
      _logger.error('Erreur lors de la mise à jour du token FCM', error: e);
      throw 'Erreur lors de la mise à jour du token: $e';
    }
  }
}
