import 'package:cloud_firestore/cloud_firestore.dart';

class PurchasedTicketModel {
  final String id;
  final String transactionId;
  final String ticketTypeId;
  final String ticketTypeName;
  final int price;
  final String username;
  final String password;
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final String status; // 'active', 'expired', 'used'
  final String zoneId;
  final String zoneName;

  PurchasedTicketModel({
    required this.id,
    required this.transactionId,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.price,
    required this.username,
    required this.password,
    required this.purchaseDate,
    required this.expirationDate,
    required this.status,
    required this.zoneId,
    required this.zoneName,
  });

  // Conversion depuis Firestore
  factory PurchasedTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PurchasedTicketModel(
      id: doc.id,
      transactionId: data['transactionId'] ?? '',
      ticketTypeId: data['ticketTypeId'] ?? '',
      ticketTypeName: data['ticketTypeName'] ?? 'Forfait',
      price: (data['price'] ?? 0).toDouble(),
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      purchaseDate: (data['soldAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expirationDate: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      status: data['status'] ?? 'unknown',
      zoneId: data['zoneId'] ?? '',
      zoneName: data['zoneName'] ?? 'Zone',
    );
  }

  // Conversion depuis JSON (stockage local)
  factory PurchasedTicketModel.fromJson(Map<String, dynamic> json) {
    return PurchasedTicketModel(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      ticketTypeId: json['ticketTypeId'] ?? '',
      ticketTypeName: json['ticketTypeName'] ?? 'Forfait',
      price: (json['price'] ?? 0).toDouble(),
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate']),
      expirationDate: DateTime.parse(json['expirationDate']),
      status: json['status'] ?? 'unknown',
      zoneId: json['zoneId'] ?? '',
      zoneName: json['zoneName'] ?? 'Zone',
    );
  }

  // Conversion vers JSON (stockage local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'ticketTypeId': ticketTypeId,
      'ticketTypeName': ticketTypeName,
      'price': price,
      'username': username,
      'password': password,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status,
      'zoneId': zoneId,
      'zoneName': zoneName,
    };
  }

  // Vérifier si le ticket est expiré
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  // Vérifier si le ticket est utilisable
  bool get isUsable => status == 'active' && !isExpired;

  // Créer une copie avec des modifications
  PurchasedTicketModel copyWith({
    String? id,
    String? transactionId,
    String? ticketTypeId,
    String? ticketTypeName,
    int? price,
    String? username,
    String? password,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? status,
    String? zoneId,
    String? zoneName,
  }) {
    return PurchasedTicketModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      ticketTypeName: ticketTypeName ?? this.ticketTypeName,
      price: price ?? this.price,
      username: username ?? this.username,
      password: password ?? this.password,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
    );
  }
}
