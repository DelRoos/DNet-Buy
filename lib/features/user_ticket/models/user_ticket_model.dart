class UserTicketModel {
  final String transactionId;
  final String planName;
  final String ticketTypeName;
  final int amount;
  final String formattedAmount;
  final UserTicketCredentials? credentials;
  final DateTime? completedAt;
  final String? freemopayReference;
  final String? planId;

  UserTicketModel({
    required this.transactionId,
    required this.planName,
    required this.ticketTypeName,
    required this.amount,
    required this.formattedAmount,
    this.credentials,
    this.completedAt,
    this.freemopayReference,
    this.planId,
  });

  factory UserTicketModel.fromJson(Map<String, dynamic> json) {
    return UserTicketModel(
      transactionId: json['transactionId'] ?? '',
      planName: json['planName'] ?? '',
      ticketTypeName: json['ticketTypeName'] ?? '',
      amount: json['amount'] ?? 0,
      formattedAmount: json['formattedAmount'] ?? '',
      credentials: json['credentials'] != null 
          ? UserTicketCredentials.fromJson(json['credentials'])
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      freemopayReference: json['freemopayReference'],
      planId: json['planId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'planName': planName,
      'ticketTypeName': ticketTypeName,
      'amount': amount,
      'formattedAmount': formattedAmount,
      'credentials': credentials?.toJson(),
      'completedAt': completedAt?.toIso8601String(),
      'freemopayReference': freemopayReference,
      'planId': planId,
    };
  }

  // Pour l'affichage formaté de la date
  String get formattedDate {
    if (completedAt == null) return 'Date inconnue';
    return '${completedAt!.day.toString().padLeft(2, '0')}/${completedAt!.month.toString().padLeft(2, '0')}/${completedAt!.year} à ${completedAt!.hour.toString().padLeft(2, '0')}:${completedAt!.minute.toString().padLeft(2, '0')}';
  }

  // Pour copier les credentials
  String get credentialsText {
    if (credentials == null) return 'Aucun identifiant disponible';
    return 'Nom d\'utilisateur: ${credentials!.username}\nMot de passe: ${credentials!.password}';
  }
}

class UserTicketCredentials {
  final String username;
  final String password;

  UserTicketCredentials({
    required this.username,
    required this.password,
  });

  factory UserTicketCredentials.fromJson(Map<String, dynamic> json) {
    return UserTicketCredentials(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}