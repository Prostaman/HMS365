import 'package:cloud_firestore/cloud_firestore.dart';

/// Геозона (например "Офис", "Склад №1").
/// Задаётся центром + радиусом в метрах — этого достаточно
/// для 99% случаев (офис, склад, стройплощадка).
/// Если понадобятся сложные полигоны — можно расширить позже.
///
/// [assignedUserIds] — список uid сотрудников, которым назначена эта зона.
/// Мобильное приложение сотрудника запрашивает только те зоны, где
/// есть его uid (см. FirestoreService.zonesForUserStream) — и с точки
/// зрения Security Rules, и с точки зрения будущего geofencing на
/// устройстве, где важно мониторить только свои зоны, а не все объекты компании.
class Zone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<String> assignedUserIds;

  Zone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.assignedUserIds = const [],
  });

  factory Zone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Zone(
      id: doc.id,
      name: data['name'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      assignedUserIds: List<String>.from(data['assignedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'assignedUserIds': assignedUserIds,
    };
  }
}
