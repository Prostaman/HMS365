# План внедрения Firebase Crashlytics

Интеграция Firebase Crashlytics для автоматического сбора отчетов об ошибках.

## Предложенные изменения

### 1. Flutter зависимости

#### [MODIFY] [pubspec.yaml](file:///Users/trio/development/Unternehmen_HMS365/hms365/pubspec.yaml)
- Добавить `firebase_crashlytics: ^4.0.1`.

### 2. Android конфигурация

#### [MODIFY] [settings.gradle.kts](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/settings.gradle.kts)
- Добавить плагин Crashlytics: `id("com.google.firebase.crashlytics") version "3.0.2" apply false`.

#### [MODIFY] [build.gradle.kts (app)](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/app/build.gradle.kts)
- Применить плагин в блоке `plugins`: `id("com.google.firebase.crashlytics")`.

### 3. Инициализация в коде

#### [MODIFY] [main.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/main.dart)
- Настроить перехват ошибок Flutter и платформы через `FirebaseCrashlytics`.

## План верификации

### Ручная проверка
- Вызов тестового краша через `FirebaseCrashlytics.instance.crash()` (временно) для проверки появления логов в консоли Firebase.
- Проверка успешной сборки проекта через `flutter build apk --debug`.
