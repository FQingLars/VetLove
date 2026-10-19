# CI/CD — сборка пакетов Flutter

`.github/workflows/flutter-builds.yml` собирает **Critter Collect** для Android и iOS.

## Джобы

| Джоб | Runner | Что делает |
|------|--------|------------|
| `analyze` | ubuntu | `flutter pub get`, `flutter analyze`, `flutter test` |
| `android` | ubuntu | APK (debug) + AAB (release) |
| `ios` | macos-14 | неподписанный `.app` |

Джобы сборки зависят от `analyze` (`needs: analyze`) — при ошибке анализа
сборка не запускается.

## Что важно знать

### Каталоги `android/` и `ios/` не в репозитории

Они генерируются в каждом CI-ране шагом `flutter create --platforms=...`.
Перед этим `pubspec.yaml` сохраняется в `/tmp` и возвращается на место:
`flutter create` перезаписывает его дефолтным содержимым.

Сгенерированный `test/widget_test.dart` удаляется — он компилируется только
с шаблонным `MyApp`, которого в проекте нет.

### `minSdk = 23` для Android

`firebase_auth` и `geolocator` требуют `minSdkVersion 23`, а шаблон Flutter 3.24
ставит `flutter.minSdkVersion` (21). Джоб поднимает значение через `sed` —
без этого Gradle падает с `uses-sdk:minSdkVersion 21 cannot be smaller than 23`.

### iOS: `.app`, а не `.ipa`

`.ipa` нельзя собрать без сертификата Apple Developer, Team ID и provisioning
profile. В secrets их нет, поэтому iOS-джоб собирает неподписанный бандл:

```
flutter build ios --release --no-codesign
```

Результат: `build/ios/iphoneos/Runner.app`.

Деплой target — 15.0 (поднимается в `project.pbxproj` и `Podfile`): часть
плагинов требует iOS 13+, шаблон Flutter 3.24 выставляет 12.0, и CocoaPods
падает на конфликте версий deployment target.

Для сборки `.ipa` понадобится добавить в secrets сертификат, provisioning
profile и `.p12`, а в джоб — `flutter build ipa` с `CODE_SIGNING_ALLOWED`.

### Firebase-конфиги не нужны для сборки

`google-services.json` и `GoogleService-Info.plist` требуются для **работы**
приложения, но не для компиляции. Без них `main.dart` показывает экран
`_BootstrapFailedApp` с описанием проблемы вместо падения.

### Анализатор

`flutter analyze --no-fatal-infos` — падает на ошибках и предупреждениях,
но не на stylistic-подсказках уровня `info`.

Проверка форматирования (`dart format --set-exit-if-changed`) запускается с
`continue-on-error: true`: код пока не отформатирован под `dart format`,
и это не должно ронять пайплайн. После `dart format .` флаг можно убрать.

### Секреты

| Имя | Назначение |
|-----|------------|
| `INATURALIST_API_KEY` | необязательный ключ iNaturalist Vision API; без него действует пониженный rate-limit |

Передаётся как `--dart-define=INATURALIST_API_KEY=...`.

> Известный пробел: `AnimalRecognitionService` создаёт `InaturalistService()`
> без `apiKey`, поэтому переданный через CI ключ пока нигде не используется.
> Требуется пробросить `String.fromEnvironment('INATURALIST_API_KEY')` в
> конструктор сервиса.

## Локальная проверка

```bash
cd app
flutter pub get
flutter analyze --no-fatal-infos
flutter test

# платформенные каталоги для локальной сборки
flutter create --platforms=android,ios --project-name critter_collect --org com.vetlove .
flutter build apk --debug
```
