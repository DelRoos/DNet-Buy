import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class MerchantService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}