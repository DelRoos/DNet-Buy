import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManualSaleService {
  final LoggerService _logger = LoggerService.to;
  static const String baseUrl =
      'https://us-central1-dnet-29b02.cloudfunctions.net';

  Future<ManualSaleResult> sellTicketManually({
    required String ticketId,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      _logger.info('Début de vente manuelle', data: {
        'ticketId': ticketId,
        'phoneNumber': phoneNumber,
        'adminUserId': currentUser.uid,
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/manualTicketSale'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'ticketId': ticketId,
              'phoneNumber': phoneNumber,
              'description': description,
              'adminUserId': currentUser.uid,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          _logger.info('✅ Vente manuelle réussie', data: {
            'transactionId': jsonData['transactionId'],
            'ticketId': ticketId,
          });

          return ManualSaleResult.success(
            transactionId: jsonData['transactionId'],
            credentials: TicketCredentials(
              username: jsonData['ticket']['username'],
              password: jsonData['ticket']['password'],
            ),
            ticketInfo: SoldTicketInfo(
              planName: jsonData['ticket']['planName'],
              amount: jsonData['ticket']['amount'],
              formattedAmount: jsonData['ticket']['formattedAmount'],
              phoneNumber: jsonData['ticket']['phoneNumber'],
              saleDate: DateTime.parse(jsonData['ticket']['saleDate']),
            ),
          );
        } else {
          throw Exception(jsonData['error'] ?? 'Erreur inconnue');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur serveur');
      }
    } catch (e) {
      _logger.error(
        'Erreur lors de la vente manuelle',
        error: e,
        category: 'MANUAL_SALE_SERVICE',
      );
      return ManualSaleResult.error(e.toString());
    }
  }
}

// Modèles pour les résultats
class ManualSaleResult {
  final bool isSuccess;
  final String? error;
  final String? transactionId;
  final TicketCredentials? credentials;
  final SoldTicketInfo? ticketInfo;

  ManualSaleResult.success({
    required this.transactionId,
    required this.credentials,
    required this.ticketInfo,
  })  : isSuccess = true,
        error = null;

  ManualSaleResult.error(this.error)
      : isSuccess = false,
        transactionId = null,
        credentials = null,
        ticketInfo = null;
}

class TicketCredentials {
  final String username;
  final String password;

  TicketCredentials({required this.username, required this.password});

  String get formattedCredentials =>
      'Nom d\'utilisateur: $username\nMot de passe: $password';
}

class SoldTicketInfo {
  final String planName;
  final int amount;
  final String formattedAmount;
  final String phoneNumber;
  final DateTime saleDate;

  SoldTicketInfo({
    required this.planName,
    required this.amount,
    required this.formattedAmount,
    required this.phoneNumber,
    required this.saleDate,
  });
}
