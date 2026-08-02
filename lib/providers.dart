import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/employee.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'models/zone.dart';

// Сервисы
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// Состояние аутентификации
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Профиль текущего сотрудника
final currentEmployeeProvider = FutureProvider<Employee?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(firestoreServiceProvider).getEmployee(user.uid);
});

// Зоны пользователя
final userZonesProvider = StreamProvider.family<List<Zone>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).zonesForUserStream(uid);
});

// Провайдер текущей позиции (для UI)
final currentPositionProvider = StreamProvider<Position>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Обновлять каждые 10 метров
    ),
  );
});

// --- ЛОГИКА ЭКРАНА ЛОГИНА ---

// Модель состояния экрана логина
class LoginState {
  final bool isLoading;
  final String? errorText;

  LoginState({this.isLoading = false, this.errorText});

  LoginState copyWith({bool? isLoading, String? errorText}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorText: errorText ?? this.errorText,
    );
  }
}

// Контроллер экрана логина
class LoginController extends StateNotifier<LoginState> {
  final AuthService _authService;

  LoginController(this._authService) : super(LoginState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorText: null);
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorText: _authService.mapErrorToMessage(e),
      );
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(ref.watch(authServiceProvider));
    });
