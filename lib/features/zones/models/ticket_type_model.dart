class TicketTypeModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final String validity;
  final int expirationAfterCreation;
  final int nbMaxUtilisations;
  final bool isActive;

  TicketTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.validity,
    required this.expirationAfterCreation,
    required this.nbMaxUtilisations,
    required this.isActive,
  });
}
