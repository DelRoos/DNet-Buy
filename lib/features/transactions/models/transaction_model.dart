import 'package:intl/intl.dart';

enum TransactionStatus { created, pending, completed, failed, expired }

class TransactionCredentials {
  final String username;
  final String password;

  TransactionCredentials({required this.username, required this.password});

  factory TransactionCredentials.fromMap(Map<String, dynamic> map) {
    return TransactionCredentials(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class TransactionModel {
  final String id;
  final TransactionStatus status;
  final int amount;
  final String currency;
  final String buyerPhoneNumber;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String planId;
  final String planName;
  final String ticketTypeName;
  final String? freemopayReference;
  final TransactionCredentials? credentials;
  final bool isManualSale;
  final String? saleDescription;
  final String? adminUserId;
  final String? externalId;
  final String provider;
  final String? providerMessage;
  final String? reservedTicketId;

  TransactionModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    required this.buyerPhoneNumber,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
    required this.planId,
    required this.planName,
    required this.ticketTypeName,
    this.freemopayReference,
    this.credentials,
    this.isManualSale = false,
    this.saleDescription,
    this.adminUserId,
    this.externalId,
    this.provider = 'freemopay',
    this.providerMessage,
    this.reservedTicketId,
  });

  // Factory pour créer depuis une Map (API response)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      status: _parseStatus(map['status']),
      amount: (map['amount'] ?? 0).toInt(),
      currency: map['currency'] ?? 'XAF',
      buyerPhoneNumber: map['phone'] ?? map['buyerPhoneNumber'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      planId: map['planId'] ?? '',
      planName: map['planName'] ?? '',
      ticketTypeName: map['ticketTypeName'] ?? '',
      freemopayReference: map['freemopayReference'],
      credentials: map['credentials'] != null
          ? TransactionCredentials.fromMap(map['credentials'])
          : null,
      isManualSale: map['isManualSale'] ?? false,
      saleDescription: map['saleDescription'],
      adminUserId: map['adminUserId'],
      externalId: map['externalId'],
      provider: map['provider'] ?? 'freemopay',
      providerMessage: map['providerMessage'],
      reservedTicketId: map['reservedTicketId'],
    );
  }

  // Factory pour la compatibilité avec l'ancien modèle
  factory TransactionModel.fromLegacy({
    required String id,
    required TransactionStatus status,
    required int amount,
    required String buyerPhoneNumber,
    required DateTime transactionDate,
    required String ticketUsername,
    required String ticketTypeName,
  }) {
    return TransactionModel(
      id: id,
      status: status,
      amount: amount,
      currency: 'XAF',
      buyerPhoneNumber: buyerPhoneNumber,
      createdAt: transactionDate,
      completedAt:
          status == TransactionStatus.completed ? transactionDate : null,
      planId: '',
      planName: ticketTypeName,
      ticketTypeName: ticketTypeName,
      credentials: status == TransactionStatus.completed
          ? TransactionCredentials(username: ticketUsername, password: 'N/A')
          : null,
    );
  }

  // Getters utiles
  String get formattedAmount {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return '${formatter.format(amount)} $currency';
  }

  bool get hasCredentials => credentials != null;

  String get statusText {
    switch (status) {
      case TransactionStatus.created:
        return 'Créée';
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Terminée';
      case TransactionStatus.failed:
        return 'Échouée';
      case TransactionStatus.expired:
        return 'Expirée';
    }
  }

  String get ticketUsername => credentials?.username ?? 'N/A';
  DateTime get transactionDate => createdAt;

  // Méthodes statiques utilitaires
  static TransactionStatus _parseStatus(dynamic status) {
    if (status == null) return TransactionStatus.created;

    switch (status.toString().toLowerCase()) {
      case 'created':
        return TransactionStatus.created;
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'expired':
        return TransactionStatus.expired;
      case 'success': // Compatibilité ancien format
        return TransactionStatus.completed;
      default:
        return TransactionStatus.created;
    }
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    if (dateTime is DateTime) return dateTime;

    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, status: $status, amount: $amount, planName: $planName)';
  }
}
