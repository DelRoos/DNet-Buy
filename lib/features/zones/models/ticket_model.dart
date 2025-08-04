class TicketModel {
  final String id;
  final String username;
  final String password;
  final String status;

  final DateTime? soldAt;
  final DateTime? firstUsedAt;
  final String? buyerPhoneNumber;
  final String? paymentReference;

  TicketModel({
    required this.id,
    required this.username,
    required this.password,
    required this.status,
    this.soldAt,
    this.firstUsedAt,
    this.buyerPhoneNumber,
    this.paymentReference,
  });
}
