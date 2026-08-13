import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../models/zone.dart';
import '../models/task.dart' as model_task;
import '../ui_helper.dart';

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
            return _ZoneCard(zone: entry.key, distance: entry.value);
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

class _ZoneCard extends ConsumerWidget {
  final Zone zone;
  final double? distance;

  const _ZoneCard({required this.zone, required this.distance});

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
    // Проверяем наличие заданий для этой зоны
    final tasksAsync = ref.watch(zoneTasksProvider(zone.id));
    final hasTasks = tasksAsync.value?.isNotEmpty ?? false;

    final isInZone = distance != null && distance! <= zone.radiusMeters;

    String distanceText = 'Определяем...';
    if (distance != null) {
      distanceText = distance! > 1000
          ? '${(distance! / 1000).toStringAsFixed(1)} км'
          : '${distance!.round()} м';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isInZone ? 4 : 1,
      color: isInZone ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInZone
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Если заданий нет, скрываем стрелочку и отключаем раскрытие
          trailing: hasTasks ? null : const SizedBox.shrink(),
          enabled: hasTasks,
          leading: InkWell(
            onTap: () => _openInGoogleMaps(zone.latitude, zone.longitude),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              backgroundColor: isInZone ? Colors.green : Colors.orange.shade100,
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
          children: hasTasks ? [_TasksList(zoneId: zone.id)] : [],
        ),
      ),
    );
  }
}

class _TasksList extends ConsumerWidget {
  final String zoneId;

  const _TasksList({required this.zoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(zoneTasksProvider(zoneId));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: applyOpacity(Colors.black, 0.03),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              const Divider(height: 1),
              ...tasks.map((task) {
                return CheckboxListTile(
                  value: task.isCompleted,
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(firestoreServiceProvider)
                          .updateTaskStatus(zoneId, task.id, val);
                    }
                  },
                  title: Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Ошибка задач: $err', style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
