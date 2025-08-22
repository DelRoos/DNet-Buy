import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class ZoneTransactionStats {
  final int totalCount;
  final double totalAmount;
  final Map<String, int> statusCounts;
  final Map<String, double> statusAmounts;

  ZoneTransactionStats({
    required this.totalCount,
    required this.totalAmount,
    required this.statusCounts,
    required this.statusAmounts,
  });

  factory ZoneTransactionStats.fromMap(Map<String, dynamic> map) {
    return ZoneTransactionStats(
      totalCount: map['totalCount'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      statusCounts: Map<String, int>.from(map['statusCounts'] ?? {}),
      statusAmounts: Map<String, double>.from((map['statusAmounts'] ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble()))),
    );
  }

  // Operateurs pour accès aux données comme une Map
  dynamic operator [](String key) {
    switch (key) {
      case 'totalCount':
        return totalCount;
      case 'totalAmount':
        return totalAmount;
      case 'statusCounts':
        return statusCounts;
      case 'statusAmounts':
        return statusAmounts;
      default:
        return null;
    }
  }
}

class ZoneTransactionService extends GetxService {
  static const String baseUrl =
      'https://us-central1-dnet-29b02.cloudfunctions.net';

  final http.Client _httpClient = http.Client();

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  /// Récupérer les transactions d'une zone avec filtres serveur
  Future<List<TransactionModel>> getZoneTransactions({
    required String zoneId,
    Map<String, dynamic>? queryParams,
    TransactionStatus? statusFilter,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{
        'zoneId': zoneId,
        'limit': limit.toString(),
      };

      // Ajouter les paramètres de requête passés
      if (queryParams != null) {
        queryParams.forEach((key, value) {
          params[key] = value.toString();
        });
      }

      if (statusFilter != null) {
        params['statusFilter'] = statusFilter.name;
      }

      final uri = Uri.parse('$baseUrl/getZoneTransactions')
          .replace(queryParameters: params);

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout lors de la récupération des transactions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> transactionsJson = data['transactions'] ?? [];
          return transactionsJson
              .map((json) => TransactionModel.fromMap(json))
              .toList();
        } else {
          throw Exception(data['error'] ??
              'Erreur lors de la récupération des transactions');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Zone non trouvée');
      } else if (response.statusCode == 403) {
        throw Exception('Accès non autorisé à cette zone');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Pas de connexion internet');
      }
      rethrow;
    }
  }

  /// Récupérer les détails complets d'une transaction
  Future<TransactionModel?> getTransactionDetails(String transactionId) async {
    try {
      final uri = Uri.parse('$baseUrl/getTransactionDetails')
          .replace(queryParameters: {'transactionId': transactionId});

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout lors de la récupération des détails'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return TransactionModel.fromMap(data['transaction']);
        } else {
          throw Exception(
              data['error'] ?? 'Erreur lors de la récupération des détails');
        }
      } else if (response.statusCode == 404) {
        return null; // Transaction non trouvée
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Pas de connexion internet');
      }
      rethrow;
    }
  }

  /// Récupérer les statistiques des transactions d'une zone
  Future<ZoneTransactionStats> getZoneTransactionStats(
      {required String zoneId}) async {
    try {
      final uri = Uri.parse('$baseUrl/getZoneTransactionStats')
          .replace(queryParameters: {'zoneId': zoneId});

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout lors de la récupération des statistiques'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ZoneTransactionStats.fromMap(data['stats']);
        } else {
          throw Exception(data['error'] ??
              'Erreur lors de la récupération des statistiques');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Zone non trouvée');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Pas de connexion internet');
      }
      rethrow;
    }
  }

  /// Vérifier le statut d'une transaction spécifique (utilise l'API existante)
  Future<TransactionModel?> checkTransactionStatus(String transactionId) async {
    try {
      final uri = Uri.parse('$baseUrl/checkTransactionStatus')
          .replace(queryParameters: {'transactionId': transactionId});

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout lors de la vérification du statut'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return TransactionModel.fromMap(data['transaction']);
        } else {
          throw Exception(
              data['error'] ?? 'Erreur lors de la vérification du statut');
        }
      } else if (response.statusCode == 404) {
        return null; // Transaction non trouvée
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Pas de connexion internet');
      }
      rethrow;
    }
  }

  /// Méthode utilitaire pour rafraîchir une transaction
  Future<TransactionModel?> refreshTransaction(
      TransactionModel transaction) async {
    return await checkTransactionStatus(transaction.id);
  }

  /// Méthode utilitaire pour filtrer les transactions localement
  List<TransactionModel> filterTransactions(
      List<TransactionModel> transactions, TransactionStatus? statusFilter) {
    if (statusFilter == null) {
      return transactions;
    }
    return transactions.where((t) => t.status == statusFilter).toList();
  }

  /// Annuler la réservation d'une transaction
  Future<void> cancelReservation(String transactionId) async {
    try {
      final uri = Uri.parse('$baseUrl/cancelTransactionReservation');

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'transactionId': transactionId,
            }),
          )
          .timeout(
            const Duration(
                seconds: 15), // Plus long timeout pour cette opération
            onTimeout: () => throw Exception(
                'Timeout lors de l\'annulation de la réservation'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erreur lors de l\'annulation');
        }

        // Succès - l'API nous confirme que l'annulation a eu lieu
        return;
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(
            data['error'] ?? 'Transaction ne peut pas être annulée');
      } else if (response.statusCode == 404) {
        throw Exception('Transaction introuvable');
      } else if (response.statusCode == 409) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Conflit lors de l\'annulation');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Pas de connexion internet');
      }
      rethrow;
    }
  }

  /// Méthode utilitaire pour trier les transactions
  List<TransactionModel> sortTransactions(
    List<TransactionModel> transactions, {
    bool byDateDesc = true,
  }) {
    final sorted = List<TransactionModel>.from(transactions);
    sorted.sort((a, b) {
      if (byDateDesc) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });
    return sorted;
  }
}
