import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/location_event.dart';
import 'firestore_service.dart';

/// Отвечает за запрос разрешений и периодическую отправку координат
/// в Firestore, пока сотрудник залогинен в приложении.
class LocationService {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _timer;

  /// Запрашивает нужные разрешения по порядку.
  /// Возвращает true, если можно начинать трекинг.
  Future<bool> requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    // Фоновое разрешение запрашиваем отдельно, только на Android.
    final bgStatus = await Permission.locationAlways.status;
    if (!bgStatus.isGranted) {
      await Permission.locationAlways.request();
    }

    return true;
  }

  /// Начать периодическую отправку координат текущего пользователя каждые 15 минут.
  void startTracking() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Сразу отправляем первую точку
    _sendCurrentLocation(uid);

    // Запускаем таймер на каждые 15 минут
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _sendCurrentLocation(uid);
    });
  }

  /// Получает текущую позицию и отправляет её в Firestore
  Future<void> _sendCurrentLocation(String uid) async {
    try {
      // Запрашиваем именно свежую позицию.
      // Если в течение 30 сек не поймаем сигнал - будет исключение.
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(minutes: 5),
        ),
      );

      final event = LocationEvent(
        userId: uid,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: pos.timestamp, // Используем время самого GPS-замера
      );

      await _firestoreService.pushLocation(event);
    } catch (e) {
      print('Не удалось получить свежую позицию: $e');
    }
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
