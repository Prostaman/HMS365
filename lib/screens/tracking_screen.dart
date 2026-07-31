import 'package:flutter/material.dart';

import '../models/zone.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

/// Экран, который видит сотрудник на Android.
/// Простой: статус трекинга + кнопка вкл/выкл + выход из аккаунта.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _authService = AuthService();
  final _locationService = LocationService();
  final _firestoreService = FirestoreService();

  bool _isTracking = false;
  bool _permissionDenied = false;

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopTracking();
      setState(() => _isTracking = false);
      return;
    }

    final granted = await _locationService.requestPermissions();
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }

    _locationService.startTracking();
    setState(() {
      _isTracking = true;
      _permissionDenied = false;
    });
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекинг местоположения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _locationService.stopTracking();
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(email, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Icon(
                _isTracking ? Icons.location_on : Icons.location_off,
                size: 72,
                color: _isTracking ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _isTracking ? 'Трекинг включён' : 'Трекинг выключен',
                style: const TextStyle(fontSize: 18),
              ),
              if (_permissionDenied) ...[
                const SizedBox(height: 12),
                const Text(
                  'Нет разрешения на доступ к геолокации. '
                  'Разрешите доступ в настройках приложения.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _toggleTracking,
                child: Text(_isTracking ? 'Выключить' : 'Включить'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Мои зоны',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              _AssignedZonesList(
                uid: _authService.currentUser?.uid,
                firestoreService: _firestoreService,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показывает только те зоны, которые назначены текущему сотруднику
/// (запрос в FirestoreService уже фильтрует по assignedUserIds,
/// плюс это же ограничение продублировано в Security Rules).
class _AssignedZonesList extends StatelessWidget {
  final String? uid;
  final FirestoreService firestoreService;

  const _AssignedZonesList({required this.uid, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<Zone>>(
      stream: firestoreService.zonesForUserStream(uid!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final zones = snap.data!;
        if (zones.isEmpty) {
          return const Text(
            'Вам пока не назначено ни одной зоны',
            style: TextStyle(color: Colors.grey),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: zones
              .map(
                (z) => Chip(
                  avatar: const Icon(Icons.place, size: 16),
                  label: Text(z.name),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
