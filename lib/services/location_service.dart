import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location_event.dart';
import 'firestore_service.dart';

/// Отвечает за запрос разрешений и периодическую отправку координат
/// в Firestore, пока сотрудник залогинен в приложении.
///
/// Важно про Android:
/// - ACCESS_FINE_LOCATION нужен всегда.
/// - ACCESS_BACKGROUND_LOCATION нужен, если хотим слать координаты,
///   когда приложение свёрнуто. Android 10+ показывает отдельный
///   системный диалог для этого разрешения — запрашивать его нужно
///   ПОСЛЕ того как выдано обычное разрешение на геолокацию, не одновременно.
/// - Для реальной надёжной фоновой работы (не убьётся системой) нужен
///   Foreground Service с постоянным уведомлением — см. пакет
///   flutter_background_service и настройку в AndroidManifest.xml
///   (см. комментарии в android/app/src/main/AndroidManifest.xml).
class LocationService {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<Position>? _positionSubscription;

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
      // Не блокируем работу, если пользователь отказал фоновому
      // доступу — просто трекинг будет работать, пока приложение открыто.
    }

    return true;
  }

  /// Начать периодическую отправку координат текущего пользователя.
  /// [intervalMeters] — минимальное перемещение (в метрах) для
  /// нового замера, чтобы не спамить Firestore, когда сотрудник стоит на месте.
  void startTracking({double intervalMeters = 25}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: intervalMeters.toInt(),
    );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((
          Position pos,
        ) {
          final event = LocationEvent(
            userId: uid,
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: Timestamp.now().toDate(),
          );
          _firestoreService.pushLocation(event);
        });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
