import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zone.dart';
import '../models/employee.dart';
import '../models/location_event.dart';

/// Структура коллекций в Firestore:
///
/// users/{uid}            -> { name, email, isManager }
/// zones/{zoneId}          -> { name, latitude, longitude, radiusMeters }
/// location_events/{autoId}-> { userId, latitude, longitude, timestamp }
///
/// location_events хранит "сырые" точки. Для 12 человек и разумного
/// интервала записи (например раз в 1-2 минуты в рабочее время)
/// объём данных совсем небольшой.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- Zones ----

  /// Все зоны — используется на десктопе менеджером (у него есть право
  /// читать любые зоны, см. firestore.rules).
  Stream<List<Zone>> zonesStream() {
    return _db.collection('zones').snapshots().map(
          (snap) => snap.docs.map((d) => Zone.fromFirestore(d)).toList(),
        );
  }

  /// Только зоны, назначенные конкретному сотруднику — используется
  /// в мобильном приложении. Обычный сотрудник по Security Rules и не
  /// может прочитать чужие/неназначенные зоны, так что запрос обязан
  /// быть именно с этим фильтром (иначе Firestore вернёт permission-denied).
  Stream<List<Zone>> zonesForUserStream(String uid) {
    return _db
        .collection('zones')
        .where('assignedUserIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Zone.fromFirestore(d)).toList());
  }

  Future<void> addZone(Zone zone) {
    return _db.collection('zones').add(zone.toMap());
  }

  Future<void> updateZone(String zoneId, Zone zone) {
    return _db.collection('zones').doc(zoneId).update(zone.toMap());
  }

  // ---- Employees ----

  Stream<List<Employee>> employeesStream() {
    return _db.collection('users').snapshots().map(
          (snap) => snap.docs.map((d) => Employee.fromFirestore(d)).toList(),
        );
  }

  Future<Employee?> getEmployee(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return Employee.fromFirestore(doc);
  }

  // ---- Location events ----

  /// Записать текущую координату сотрудника.
  Future<void> pushLocation(LocationEvent event) {
    return _db.collection('location_events').add(event.toMap());
  }

  /// Последняя известная точка сотрудника (для десктоп-дашборда).
  Stream<LocationEvent?> lastLocationForUser(String userId) {
    return _db
        .collection('location_events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return LocationEvent.fromFirestore(snap.docs.first);
    });
  }

  /// История точек сотрудника за период (например, за сегодня) —
  /// нужно, если считаем "был ли в зоне за день", а не только "сейчас".
  Future<List<LocationEvent>> locationHistory(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('location_events')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => LocationEvent.fromFirestore(d)).toList();
  }
}
