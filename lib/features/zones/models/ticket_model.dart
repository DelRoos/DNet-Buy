import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String username;
  final String password;
  final String status;
  final String zoneId;
  final String ticketTypeId;
  final DateTime createdAt;
  final DateTime? soldAt;
  final DateTime? firstUsedAt;
  final String? buyerPhoneNumber;
  final String? paymentReference;

  // Nouvelles propriétés pour la vente manuelle
  final String? saleType; // 'manual' ou 'online'
  final String? saleDescription;
  final String? adminUserId;
  final String? transactionId;

  TicketModel({
    required this.id,
    required this.username,
    required this.password,
    required this.status,
    required this.zoneId,
    required this.ticketTypeId,
    required this.createdAt,
    this.soldAt,
    this.firstUsedAt,
    this.buyerPhoneNumber,
    this.paymentReference,
    this.saleType,
    this.saleDescription,
    this.adminUserId,
    this.transactionId,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      status: data['status'] ?? 'unknown',
      zoneId: data['zoneId'] ?? '',
      ticketTypeId: data['ticketTypeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
      firstUsedAt: (data['firstUsedAt'] as Timestamp?)?.toDate(),
      buyerPhoneNumber: data['buyerPhoneNumber'] as String?,
      paymentReference: data['paymentReference'] as String?,
      saleType: data['saleType'] as String?,
      saleDescription: data['saleDescription'] as String?,
      adminUserId: data['adminUserId'] as String?,
      transactionId: data['transactionId'] as String?,
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'status': status,
      'zoneId': zoneId,
      'ticketTypeId': ticketTypeId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (soldAt != null) 'soldAt': Timestamp.fromDate(soldAt!),
      if (firstUsedAt != null) 'firstUsedAt': Timestamp.fromDate(firstUsedAt!),
      if (buyerPhoneNumber != null) 'buyerPhoneNumber': buyerPhoneNumber,
      if (paymentReference != null) 'paymentReference': paymentReference,
      if (saleType != null) 'saleType': saleType,
      if (saleDescription != null) 'saleDescription': saleDescription,
      if (adminUserId != null) 'adminUserId': adminUserId,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }

  // Méthode copyWith
  TicketModel copyWith({
    String? id,
    String? username,
    String? password,
    String? status,
    String? zoneId,
    String? ticketTypeId,
    DateTime? createdAt,
    DateTime? soldAt,
    DateTime? firstUsedAt,
    String? buyerPhoneNumber,
    String? paymentReference,
    String? saleType,
    String? saleDescription,
    String? adminUserId,
    String? transactionId,
  }) {
    return TicketModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      zoneId: zoneId ?? this.zoneId,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      firstUsedAt: firstUsedAt ?? this.firstUsedAt,
      buyerPhoneNumber: buyerPhoneNumber ?? this.buyerPhoneNumber,
      paymentReference: paymentReference ?? this.paymentReference,
      saleType: saleType ?? this.saleType,
      saleDescription: saleDescription ?? this.saleDescription,
      adminUserId: adminUserId ?? this.adminUserId,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  // Getters utiles
  bool get isAvailable => status == 'available';
  bool get isSold => status == 'sold' || status == 'used';
  bool get isManualSale => saleType == 'manual';
  bool get isOnlineSale => saleType == 'online';

  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'sold':
      case 'used':
        return 'Vendu';
      case 'reserved':
        return 'Réservé';
      case 'expired':
        return 'Expiré';
      default:
        return 'Inconnu';
    }
  }

  String get saleTypeDisplay {
    switch (saleType) {
      case 'manual':
        return 'Vente manuelle';
      case 'online':
        return 'Vente en ligne';
      default:
        return 'Non spécifié';
    }
  }

  @override
  String toString() {
    return 'TicketModel(id: $id, username: $username, status: $status, saleType: $saleType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
