# План по изменению названия пакета (Package Name)

Изменение названия пакета с `de.hms365.hms365` на `de.hms365`.

## Требуется подтверждение пользователя

> [!IMPORTANT]
> **Внимание:** Если вы используете Firebase (в проекте есть `firebase.json` и `google-services.json`), после смены названия пакета вам потребуется:
> 1. Обновить настройки приложения в консоли Firebase или создать новое.
> 2. Скачать и заменить файл `google-services.json` (для Android) и `GoogleService-Info.plist` (для iOS).

## Предложенные изменения

### 1. Android

#### [MODIFY] [build.gradle.kts](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/app/build.gradle.kts)
- Изменить `namespace = "de.hms365.hms365"` -> `namespace = "de.hms365"`
- Изменить `applicationId = "de.hms365.hms365"` -> `applicationId = "de.hms365"`

#### [MODIFY] [MainActivity.kt](file:///Users/trio/development/Unternehmen_HMS365/hms365/android/app/src/main/kotlin/de/hms365/hms365/MainActivity.kt)
- Обновить `package de.hms365.hms365` -> `package de.hms365`

#### [MOVE] Перемещение папок
- Переместить `MainActivity.kt` из `android/app/src/main/kotlin/de/hms365/hms365/` в `android/app/src/main/kotlin/de/hms365/`.
- Удалить пустую папку `de/hms365/hms365`.

### 2. iOS

#### [MODIFY] [project.pbxproj](file:///Users/trio/development/Unternehmen_HMS365/hms365/ios/Runner.xcodeproj/project.pbxproj)
- Заменить все вхождения `de.hms365.hms365` на `de.hms365`.

### 3. Общее
- Выполнить `flutter clean`.

## План верификации

### Ручная проверка
- Проверка успешности сборки: `flutter build apk`.
- Проверка iOS (если возможно): `flutter build ios --no-codesign`.
