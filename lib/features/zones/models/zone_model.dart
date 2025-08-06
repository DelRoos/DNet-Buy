// lib/features/zones/models/zone_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final String routerType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? routerConfig;
  final List<String>? tags;

  ZoneModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.routerType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.routerConfig,
    this.tags,
  });

  // Créer depuis Firestore
  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ZoneModel(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      routerType: data['routerType'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      routerConfig: data['routerConfig'] as Map<String, dynamic>?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  // Créer depuis Map
  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] ?? '',
      merchantId: map['merchantId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      routerType: map['routerType'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      deletedAt: map['deletedAt'] != null 
          ? (map['deletedAt'] is Timestamp 
              ? (map['deletedAt'] as Timestamp).toDate()
              : DateTime.parse(map['deletedAt']))
          : null,
      routerConfig: map['routerConfig'] as Map<String, dynamic>?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  // Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'routerType': routerType,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      if (routerConfig != null) 'routerConfig': routerConfig,
      if (tags != null) 'tags': tags,
    };
  }

  // Copier avec modifications
  ZoneModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    String? routerType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    Map<String, dynamic>? routerConfig,
    List<String>? tags,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      routerType: routerType ?? this.routerType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      routerConfig: routerConfig ?? this.routerConfig,
      tags: tags ?? this.tags,
    );
  }

  // Getters utiles
  bool get isDeleted => deletedAt != null;
  String get statusText => isActive ? 'Actif' : 'Inactif';
  String get formattedCreationDate => '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  @override
  String toString() {
    return 'ZoneModel(id: $id, name: $name, isActive: $isActive, routerType: $routerType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZoneModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}