# План перехода на Riverpod

Рефакторинг проекта hms365 для использования Riverpod в качестве системы управления состоянием.

## Требуется подтверждение пользователя

> [!IMPORTANT]
> Переход на Riverpod изменит структуру инициализации приложения и способ взаимодействия с экранами. Все `StatefulWidget`, отвечающие за логику, станут `ConsumerWidget` или `ConsumerStatefulWidget`.

## Предложенные изменения

### 1. Конфигурация проекта

#### [MODIFY] [pubspec.yaml](file:///Users/trio/development/Unternehmen_HMS365/hms365/pubspec.yaml)
- Добавить `flutter_riverpod: ^2.5.1`.

### 2. Сервисы и Провайдеры (Новые файлы)

#### [NEW] [providers.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/providers.dart)
- `authServiceProvider`: предоставляет экземпляр `AuthService`.
- `firestoreServiceProvider`: предоставляет экземпляр `FirestoreService`.
- `locationServiceProvider`: предоставляет экземпляр `LocationService`.
- `authStateProvider`: StreamProvider, следящий за статусом авторизации (заменяет `StreamBuilder` в `main.dart`).

### 3. Инициализация

#### [MODIFY] [main.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/main.dart)
- Обернуть `MobileApp` в `ProviderScope`.
- Переписать `_RootRouter` на `ConsumerWidget`, используя `authStateProvider.watch()`.

### 4. Экраны

#### [MODIFY] [login_screen.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/screens/login_screen.dart)
- Превратить в `ConsumerStatefulWidget` (контроллеры текста оставим внутри для простоты, либо вынесем в провайдер).
- Использовать `ref.read(authServiceProvider)` для вызова метода входа.

#### [MODIFY] [tracking_screen.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/screens/tracking_screen.dart)
- Превратить в `ConsumerWidget`.
- Использовать провайдеры для получения данных из Firestore.

## План верификации

### Автоматизированные тесты
- Запуск `flutter test` (если есть тесты).

### Ручная проверка
- Проверка процесса логина.
- Проверка начала трекинга после входа.
- Проверка разлогина.
