// lib/features/zones/models/ticket_type_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketTypeModel {
  final String id;
  final String zoneId;
  final String name;
  final String description;
  final int price;
  final String validity;
  final int validityHours;
  final int expirationAfterCreation;
  final int nbMaxUtilisations;
  final bool isActive;
  final int totalTicketsGenerated;
  final int ticketsSold;
  final int ticketsAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;
  final String? rateLimit;

  TicketTypeModel({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.description,
    required this.price,
    required this.validity,
    required this.validityHours,
    required this.expirationAfterCreation,
    required this.nbMaxUtilisations,
    required this.isActive,
    required this.totalTicketsGenerated,
    required this.ticketsSold,
    required this.ticketsAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.metadata,
    this.rateLimit,
  });

  // Créer depuis Firestore
  factory TicketTypeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TicketTypeModel(
      id: doc.id,
      zoneId: data['zoneId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      validity: data['validity'] ?? '',
      validityHours: data['validityHours'] ?? 24,
      expirationAfterCreation: data['expirationAfterCreation'] ?? 30,
      nbMaxUtilisations: data['nbMaxUtilisations'] ?? 1,
      isActive: data['isActive'] ?? true,
      totalTicketsGenerated: data['totalTicketsGenerated'] ?? 0,
      ticketsSold: data['ticketsSold'] ?? 0,
      ticketsAvailable: data['ticketsAvailable'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      rateLimit: data['rateLimit'] as String?,
    );
  }

  // Créer depuis Map
  factory TicketTypeModel.fromMap(Map<String, dynamic> map) {
    return TicketTypeModel(
      id: map['id'] ?? '',
      zoneId: map['zoneId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? 0,
      validity: map['validity'] ?? '',
      validityHours: map['validityHours'] ?? 24,
      expirationAfterCreation: map['expirationAfterCreation'] ?? 30,
      nbMaxUtilisations: map['nbMaxUtilisations'] ?? 1,
      isActive: map['isActive'] ?? true,
      totalTicketsGenerated: map['totalTicketsGenerated'] ?? 0,
      ticketsSold: map['ticketsSold'] ?? 0,
      ticketsAvailable: map['ticketsAvailable'] ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['updatedAt'] ?? DateTime.now().toIso8601String()),
      deletedAt: map['deletedAt'] != null
          ? (map['deletedAt'] is Timestamp
              ? (map['deletedAt'] as Timestamp).toDate()
              : DateTime.parse(map['deletedAt']))
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      rateLimit: map['rateLimit'] as String?,
    );
  }

  // Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'name': name,
      'description': description,
      'price': price,
      'validity': validity,
      'validityHours': validityHours,
      'expirationAfterCreation': expirationAfterCreation,
      'nbMaxUtilisations': nbMaxUtilisations,
      'isActive': isActive,
      'totalTicketsGenerated': totalTicketsGenerated,
      'ticketsSold': ticketsSold,
      'ticketsAvailable': ticketsAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      if (metadata != null) 'metadata': metadata,
      if (rateLimit != null) 'rateLimit': rateLimit,
    };
  }

  // Copier avec modifications
  TicketTypeModel copyWith({
    String? id,
    String? zoneId,
    String? name,
    String? description,
    int? price,
    String? validity,
    int? validityHours,
    int? expirationAfterCreation,
    int? nbMaxUtilisations,
    bool? isActive,
    int? totalTicketsGenerated,
    int? ticketsSold,
    int? ticketsAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    Map<String, dynamic>? metadata,
    String? rateLimit,
  }) {
    return TicketTypeModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      validity: validity ?? this.validity,
      validityHours: validityHours ?? this.validityHours,
      expirationAfterCreation:
          expirationAfterCreation ?? this.expirationAfterCreation,
      nbMaxUtilisations: nbMaxUtilisations ?? this.nbMaxUtilisations,
      isActive: isActive ?? this.isActive,
      totalTicketsGenerated:
          totalTicketsGenerated ?? this.totalTicketsGenerated,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      ticketsAvailable: ticketsAvailable ?? this.ticketsAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: metadata ?? this.metadata,
      rateLimit: rateLimit ?? this.rateLimit,
    );
  }

  // Getters utiles
  bool get isDeleted => deletedAt != null;
  String get statusText => isActive ? 'Actif' : 'Inactif';
  String get formattedPrice => '${price.toString()} F';
  String get formattedCreationDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  double get conversionRate =>
      ticketsSold > 0 ? (ticketsSold / totalTicketsGenerated * 100) : 0.0;
  bool get hasStock => ticketsAvailable > 0;
  String get stockStatus {
    if (ticketsAvailable == 0) return 'Stock épuisé';
    if (ticketsAvailable < 10) return 'Stock faible';
    return 'En stock';
  }

  @override
  String toString() {
    return 'TicketTypeModel(id: $id, name: $name, price: $price, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketTypeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
