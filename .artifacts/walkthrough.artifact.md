# Результаты внедрения Firebase Crashlytics

Я успешно интегрировал **Firebase Crashlytics** в проект. Теперь все критические ошибки приложения будут автоматически отправляться в консоль Firebase для анализа.

## Что было сделано:

1.  **Конфигурация проекта:**
    - В [pubspec.yaml](file:///Users/trio/development/Unternehmen_HMS365/hms365/pubspec.yaml) добавлена библиотека `firebase_crashlytics`.
2.  **Настройка Android (Gradle):**
    - В [settings.gradle.kts](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/settings.gradle.kts) добавлен плагин Crashlytics.
    - В [build.gradle.kts](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/app/build.gradle.kts) плагин применен к приложению. Это необходимо для корректной обработки нативных сбоев.
3.  **Инициализация в коде:**
    - В [main.dart](file:///Users/trio/development/Unternehmen_HMS365/hms365/lib/main.dart) настроен глобальный перехват ошибок Flutter и системных ошибок через `FirebaseCrashlytics.instance`.

## Как это работает:
- Приложение теперь перехватывает все исключения (exceptions), которые происходят во Flutter-виджетах.
- Также перехватываются асинхронные ошибки через `PlatformDispatcher`.
- Отчеты будут появляться в разделе **Crashlytics** консоли Firebase.

> [!NOTE]
> При локальной сборке через `flutter build apk` может возникнуть системная ошибка Gradle, связанная с переменными окружения (`ANDROID_PREFS_ROOT`). Для её обхода используйте команду:
> `unset ANDROID_PREFS_ROOT && flutter run`

## Следующие шаги:
1. Запустите приложение.
2. После первого запуска перейдите в [Firebase Console](https://console.firebase.google.com/) -> **Release & Monitor** -> **Crashlytics**, чтобы убедиться, что панель активировалась.
