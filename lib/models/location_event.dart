import 'package:cloud_firestore/cloud_firestore.dart';

/// Одна запись координаты сотрудника в конкретный момент времени.
class LocationEvent {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationEvent({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationEvent(
      userId: data['userId'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
