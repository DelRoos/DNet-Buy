enum TransactionStatus { success, failed }

class TransactionModel {
  final String id;
  final TransactionStatus status;
  final int amount;
  final String buyerPhoneNumber;
  final DateTime transactionDate;
  final String ticketUsername;
  final String ticketTypeName;

  TransactionModel({
    required this.id,
    required this.status,
    required this.amount,
    required this.buyerPhoneNumber,
    required this.transactionDate,
    required this.ticketUsername,
    required this.ticketTypeName,
  });
}
