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
    );
  }
}
