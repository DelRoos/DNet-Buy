class PurchasedTicketModel {
  final String transactionId;
  final String ticketTypeName;
  final int price;
  final String username;
  final String password;
  final DateTime purchaseDate;

  PurchasedTicketModel({
    required this.transactionId,
    required this.ticketTypeName,
    required this.price,
    required this.username,
    required this.password,
    required this.purchaseDate,
  });

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'ticketTypeName': ticketTypeName,
        'price': price,
        'username': username,
        'password': password,
        'purchaseDate': purchaseDate.toIso8601String(),
      };

  factory PurchasedTicketModel.fromJson(Map<String, dynamic> json) =>
      PurchasedTicketModel(
        transactionId: json['transactionId'],
        ticketTypeName: json['ticketTypeName'],
        price: json['price'],
        username: json['username'],
        password: json['password'],
        purchaseDate: DateTime.parse(json['purchaseDate']),
      );
}
