import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String ticketTypeId;
  final String zoneId;
  final String phoneNumber;
  final int amount;
  final String status; // 'pending', 'completed', 'failed'
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? paymentReference;

  TransactionModel({
    required this.id,
    required this.ticketTypeId,
    required this.zoneId,
    required this.phoneNumber,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.paymentReference,
  });

  // Conversion depuis Firestore
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      ticketTypeId: data['ticketTypeId'] ?? '',
      zoneId: data['zoneId'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      amount: (data['amount'] ?? 0).toint(),
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'mobile_money',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      failureReason: data['failureReason'],
      paymentReference: data['paymentReference'],
    );
  }

  // Vérifier si la transaction est en cours
  bool get isPending => status == 'pending';

  // Vérifier si la transaction est réussie
  bool get isCompleted => status == 'completed';

  // Vérifier si la transaction a échoué
  bool get isFailed => status == 'failed';
}
