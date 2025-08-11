import 'dart:convert';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/features/user_ticket/models/user_ticket_model.dart';
import 'package:http/http.dart' as http;

class UserTicketsService {
  final LoggerService _logger = LoggerService.to;
  static const String baseUrl =
      'https://us-central1-dnet-29b02.cloudfunctions.net';

  Future<List<UserTicketModel>> getUserTicketsByPhone(
      String phoneNumber) async {
    try {
      _logger.debug('Récupération des tickets pour le numéro: $phoneNumber');

      final uri =
          Uri.parse('$baseUrl/getUserTicketsByPhone').replace(queryParameters: {
        'phoneNumber': phoneNumber,
        'limit': '50' // Limiter à 50 tickets max
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      _logger.debug('Réponse API getUserTicketsByPhone', data: {
        'statusCode': response.statusCode,
        'phoneNumber': phoneNumber,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final List ticketsJson = jsonData['tickets'] ?? [];
          final tickets = ticketsJson
              .map((json) => UserTicketModel.fromJson(json))
              .toList();

          _logger.info('✅ Tickets récupérés avec succès', data: {
            'phoneNumber': phoneNumber,
            'ticketsCount': tickets.length,
          });

          return tickets;
        } else {
          throw Exception(jsonData['error'] ?? 'Erreur inconnue');
        }
      } else if (response.statusCode == 404) {
        _logger.info('Aucun ticket trouvé pour le numéro: $phoneNumber');
        return [];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur serveur');
      }
    } catch (e) {
      _logger.error(
        'Erreur lors de la récupération des tickets',
        error: e,
        category: 'USER_TICKETS_SERVICE',
      );
      rethrow;
    }
  }
}
