import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zone.dart';
import '../models/employee.dart';
import '../models/location_event.dart';

/// Структура коллекций в Firestore:
///
/// workers/{uid}                            -> { name, email, isManager }
/// workers/{uid}/location_history/{autoId}  -> { userId, latitude, longitude, accuracy, timestamp }
/// zones/{zoneId}                           -> { name, coordinate, radiusMeters, assignedUserIds }
///
/// Мы используем подколлекцию location_history внутри каждого сотрудника (коллекция workers),
/// так как основной сценарий менеджера — проверка конкретного сотрудника.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- Zones ----

  Stream<List<Zone>> zonesForUserStream(String uid) {
    return _db
        .collection('zones')
        .where('assignedUserIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Zone.fromFirestore(d)).toList());
  }

  // ---- Workers (Profiles) ----

  Future<Employee?> getEmployee(String uid) async {
    final doc = await _db.collection('workers').doc(uid).get();
    if (!doc.exists) return null;
    return Employee.fromFirestore(doc);
  }

  // ---- Location events (Subcollection) ----

  /// Записать текущую координату сотрудника в его личную подколлекцию.
  Future<void> pushLocation(LocationEvent event) {
    return _db
        .collection('workers')
        .doc(event.userId)
        .collection('location_history')
        .add(event.toMap());
  }

  // ---- Остальные методы (для десктопа) ----
}
