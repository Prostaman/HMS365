import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../models/zone.dart';

/// Экран, который видит сотрудник на Android.
/// Простой: статус трекинга + кнопка вкл/выкл + выход из аккаунта.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  bool _isTracking = false;
  bool _permissionDenied = false;

  Future<void> _toggleTracking() async {
    final locationService = ref.read(locationServiceProvider);

    if (_isTracking) {
      locationService.stopTracking();
      setState(() => _isTracking = false);
      return;
    }

    final granted = await locationService.requestPermissions();
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }

    locationService.startTracking();
    setState(() {
      _isTracking = true;
      _permissionDenied = false;
    });
  }

  @override
  void dispose() {
    ref.read(locationServiceProvider).stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final employeeAsync = ref.watch(currentEmployeeProvider);

    return Scaffold(
      appBar: AppBar(
        title: employeeAsync.when(
          data: (emp) => Text(emp?.fullName ?? user?.email ?? ''),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => Text(user?.email ?? ''),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              ref.read(locationServiceProvider).stopTracking();
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity, // Растягиваем на всю ширину экрана
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                if (_isTracking) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Мои зоны (ближайшие)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (user != null) _AssignedZonesList(uid: user.uid),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignedZonesList extends ConsumerWidget {
  final String uid;

  const _AssignedZonesList({required this.uid});

  Future<void> _openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(userZonesProvider(uid));
    final positionAsync = ref.watch(currentPositionProvider);

    return zonesAsync.when(
      data: (zones) {
        if (zones.isEmpty) {
          return const Text(
            'Вам пока не назначено ни одной зоны',
            style: TextStyle(color: Colors.grey),
          );
        }

        final userPos = positionAsync.value;

        final List<MapEntry<Zone, double?>> zonesWithDistance = zones.map((z) {
          double? dist;
          if (userPos != null) {
            dist = Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              z.latitude,
              z.longitude,
            );
          }
          return MapEntry(z, dist);
        }).toList();

        if (userPos != null) {
          zonesWithDistance.sort((a, b) {
            if (a.value == null || b.value == null) return 0;
            return a.value!.compareTo(b.value!);
          });
        }

        return Column(
          children: zonesWithDistance.map((entry) {
            final zone = entry.key;
            final distance = entry.value;

            String distanceText = 'Определяем...';
            if (distance != null) {
              distanceText = distance > 1000
                  ? '${(distance / 1000).toStringAsFixed(1)} км'
                  : '${distance.round()} м';
            }

            final isInZone = distance != null && distance <= zone.radiusMeters;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isInZone ? 4 : 1,
              // Меняем фон карточки на светло-зеленый, если пользователь в зоне
              color: isInZone ? Colors.green.shade50 : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isInZone
                    ? const BorderSide(color: Colors.green, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: InkWell(
                  onTap: () => _openInGoogleMaps(zone.latitude, zone.longitude),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    backgroundColor: isInZone
                        ? Colors.green
                        : Colors.orange.shade100,
                    child: Icon(
                      isInZone ? Icons.check : Icons.place,
                      color: isInZone ? Colors.white : Colors.orange,
                    ),
                  ),
                ),
                title: Text(
                  zone.name,
                  style: TextStyle(
                    fontWeight: isInZone ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: isInZone
                    ? const Text(
                        'Вы на объекте',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text('До объекта: $distanceText'),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Text('Ошибка загрузки: $err'),
    );
  }
}
