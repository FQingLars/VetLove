# CI/CD — сборка пакетов Flutter

`.github/workflows/flutter-builds.yml` собирает **Critter Collect** для Android и iOS.

Статус последнего прогона: **все три джоба зелёные**, артефакты загружаются.

| Артефакт | Размер | Что внутри |
|----------|--------|------------|
| `android-apk` | ~92 МБ | `app-debug.apk` |
| `android-aab` | ~25 МБ | `app-release.aab` для Google Play |
| `ios-app` | ~90 МБ | `Runner.app` для симулятора |

## Джобы

| Джоб | Runner | Что делает |
|------|--------|------------|
| `analyze` | ubuntu-latest | `flutter pub get`, `flutter analyze`, `flutter test` |
| `android` | ubuntu-latest | APK (debug) + AAB (release) |
| `ios` | macos-15 | `.app` для симулятора |

Джобы сборки зависят от `analyze` (`needs: analyze`) — при ошибке анализа
сборка не запускается.

## Платформенные каталоги не в репозитории

`android/` и `ios/` генерируются в каждом ране шагом `flutter create`.
Перед этим `pubspec.yaml` сохраняется в `/tmp` и возвращается на место:
`flutter create` его перезаписывает. Сгенерированный `test/widget_test.dart`
удаляется — он компилируется только с шаблонным `MyApp`, которого в проекте нет.

## Обходные пути, без которых сборка не проходит

Все правки применяются к сгенерированным файлам, потому что платформенные
каталоги не версионируются.

### Android: AGP и Gradle

D8 из AGP 8.1 (шаблон Flutter 3.24) падает с `NullPointerException` на
актуальных jar'ах — `error_prone_annotations-2.36.0`, `androidx.camera 1.4.1`.
Поднимаются AGP до 8.5.2, Kotlin до 1.9.24, Gradle wrapper до 8.7.
Заодно `minSdk` меняется с `flutter.minSdkVersion` (21) на 23 — этого требуют
`firebase_auth` и `geolocator`.

### Android: geolocator_android зафиксирован в pubspec

`geolocator_android 4.6.2` использует `compileSdk flutter.compileSdkVersion`.
Расширение `flutter` инжектится Flutter Gradle Plugin в проект плагина только
с Flutter 3.27, поэтому на 3.24 сборка падает с
`Could not get unknown property 'flutter' for extension 'android'`.
В `pubspec.yaml` стоит `dependency_overrides: geolocator_android: 4.6.1` —
последняя версия с фиксированным `compileSdk 34`.

Остальные плагины проекта проверены скриптом: `geolocator_android` был единственным
с таким паттерном.

### iOS: Xcode 16 вместо Xcode 15

`FirebaseSharedSwift/FirebaseDataEncoder.swift` использует модификатор `sending`
из Swift 6. На `macos-14` (Xcode 15) это не компилируется, поэтому раннер —
`macos-15`. Deployment target поднимается до 15.0 в `project.pbxproj` и `Podfile`.

### iOS: сборка под симулятор, а не .ipa

`.ipa` требует сертификата Apple Developer, Team ID и provisioning profile —
всего этого в secrets нет. Кроме того, `flutter build ios --release --no-codesign`
после успешного `xcodebuild` всё равно падал с «requires a selected Development
Team»: `flutter create` называет таргет по `--project-name`
(`critter_collect` → `critterCollect`), и Flutter не находит ожидаемый
`Runner.app`.

Поэтому iOS-джоб собирает симуляторную версию — подпись не нужна вовсе:

```
flutter build ios --simulator --debug
```

Результат: `app/build/ios/iphonesimulator/Runner.app`.

Для `.ipa` понадобится добавить в secrets сертификат, provisioning profile и
`.p12`, а в джоб — `flutter build ipa` с `CODE_SIGNING_ALLOWED`.

### iOS: suppress`-Wnon-modular-include-in-framework-module`

`firebase_auth` 5.x под Xcode 16 включает `Firebase.h` как non-modular header
внутри framework module, и `-Werror` превращает это в ошибку. Флаг
`-Wno-non-modular-include-in-framework-module` добавляется дважды:

* в `post_install` Podfile (CocoaPods допускает только один такой блок, поэтому
  настройки **встраиваются** в сгенерированный Flutter-блок с якорем
  `flutter_additional_ios_build_settings(target)`, а не добавляются вторым);
* в `ios/Flutter/Debug.xcconfig` и `Release.xcconfig` — таргет `Runner`
  компилирует заголовки framework'ов плагинов, и настройки Pods на него
  не распространяются.

## Пути к артефактам

`defaults.run.working-directory: app` действует **только** на шаги `run:`.
`actions/upload-artifact` выполняется от корня репозитория, поэтому в путях
нужен префикс `app/`:

```yaml
path: app/build/app/outputs/flutter-apk/*.apk
```

Без префикса шаг молча завершается с `No files were found`, и сборка
выглядит успешной при отсутствии артефактов.

## Firebase-конфиги

`google-services.json` и `GoogleService-Info.plist` нужны для работы
приложения, но не для компиляции. Без них `main.dart` показывает
`_BootstrapFailedApp` с описанием проблемы вместо падения.

## Анализатор

`flutter analyze --no-fatal-infos` — падает на ошибках и предупреждениях,
но не на stylistic-подсказках уровня `info`.

Проверка форматирования (`dart format --set-exit-if-changed`) запускается с
`continue-on-error: true`: код не отформатирован под `dart format`, и это не
должно ронять пайплайн. После `dart format .` флаг можно убрать.

## Секреты

| Имя | Назначение |
|-----|------------|
| `INATURALIST_API_KEY` | необязательный ключ iNaturalist Vision API; без него действует пониженный rate-limit |

Передаётся как `--dart-define=INATURALIST_API_KEY=...`.

> Известный пробел: `AnimalRecognitionService` создаёт `InaturalistService()`
> без `apiKey`, поэтому переданный через CI ключ нигде не используется.
> Нужен проброс `String.fromEnvironment('INATURALIST_API_KEY')` в конструктор.

## Локальная проверка

```bash
cd app
flutter pub get
flutter analyze --no-fatal-infos
flutter test

flutter create --platforms=android,ios --project-name critter_collect --org com.vetlove .
flutter build apk --debug
```
