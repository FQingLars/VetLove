# Critter Collect 🦊

AR-приложение для Android/iOS: поиск животных через камеру, коллекция карточек
с энциклопедической информацией и редкостью (⭐ 1–5), аккаунты и трейды
между пользователями поблизости.

Распознавание видов выполняется **сторонним API iNaturalist**
(vision-модель работает на сервере — в APK/IPA нет тяжёлой TFLite-модели),
при отсутствии сети включается офлайн-фолбэк по локальному каталогу видов
(`lib/services/inaturalist_service.dart`, `lib/services/animal_recognition_service.dart`).

```
app/           Flutter-клиент (Android + iOS)
backend/       Бэкенд аккаунтов/трейдов (заглушка; основной стек — Firebase)
```

---

## 1. Сборка под Android/iOS с Linux (кросс-компиляция)

### Важное ограничение: iOS

**Собрать `.ipa` для App Store с Linux невозможно официально.** Flutter требует
Xcode и macOS для компиляции и подписи iOS-кода (Swift/Objective-C тулчейн,
`codesign`, Apple Developer Team ID). Варианты для команды на Linux:

| Вариант | Как |
|---|---|
| CI на macOS | GitHub Actions `runs-on: macos-latest` + Fastlane (`flutter build ipa`) |
| Сетевой macOS-хост | `flutter config --enable-ios --target-platform ios` + `sshfs` маунт Mac'а / `codemagic` |
| Облачный сборщик | Codemagic, Bitrise, MacStadium — загрузили репозиторий, получили `.ipa` |

С Linux можно полностью подготовить проект к iOS-сборке: dart-код, плагины,
`Podfile`, entitlements, ассеты — а саму сборку выполнить на macOS в CI.

### 1.1. Установка тулчейна на Linux (Debian/Ubuntu)

```bash
# Зависимости Flutter SDK
sudo apt update
sudo apt install -y git curl unzip xz-utils zip libglu1-mesa clang cmake \
    ninja-build pkg-config libgtk-3-dev   # libgtk — только для linux desktop, не обязателен

# Flutter SDK (stable канал) — ставим в /opt и добавляем в PATH
git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Проверяем окружение
flutter doctor -v
```

Android SDK (для сборки APK/AAB с Linux):

```bash
sudo mkdir -p /opt/android-sdk && sudo chown $USER /opt/android-sdk
cd /opt/android-sdk

# commandline-tools (последняя версия со https://developer.android.com/studio)
curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip && mkdir -p cmdline-tools/latest \
    && mv cmdline-tools/{bin,lib,NOTICE.txt,source.properties} cmdline-tools/latest/ 2>/dev/null || true

export ANDROID_HOME=/opt/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

sdkmanager --licenses >/dev/null
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

flutter config --android-sdk /opt/android-sdk
flutter doctor   # Android toolchain должен стать ✓
```

Java 17 (требование AGP 8.x):

```bash
sudo apt install -y openjdk-17-jdk
```

### 1.2. Генерация платформенных проектов (делается один раз)

В репозитории пока только `app/lib` и `app/pubspec.yaml` — каталоги `android/`
и `ios/` генерируются Flutterом:

```bash
cd app
flutter create --platforms=android,ios --project-name critter_collect .
flutter pub get
```

После этого появятся `app/android/` и `app/ios/`. Закоммитьте их —
CI и другие разработчики будут работать с ними напрямую.

### 1.3. Настройка Android (`app/android/`)

`app/android/app/build.gradle.kts` (или `build.gradle`):

```kotlin
android {
    namespace = "com.example.critter_collect"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.example.critter_collect"
        minSdk = 24            // camera + geolocator + firebase
        targetSdk = 34
    }
}
```

Firebase (аккаунты/трейды): скачайте `google-services.json` из
[console.firebase.google.com](https://console.firebase.google.com) →
положите в `app/android/app/`. Для Sign in with Apple на Android ничего не нужно.

Приватный ключ iNaturalist API (опционально, повышает rate-limit):
задайте через `--dart-define` (см. п. 1.5), не храните его в коде.

### 1.4. Сборка Android

```bash
cd app

# Debug APK (подпись debug-ключом)
flutter build apk --debug

# Release AAB для Google Play
keytool -genkey -v -keystore ~/critter.jks -keyalg RSA -keysize 2048 \
    -validity 10000 -alias critter
flutter build appbundle --release \
    --dart-define=INATURALIST_API_KEY=xxxx

# Артефакты:
#   build/app/outputs/flutter-apk/app-release.apk
#   build/app/outputs/bundle/release/app-release.aab
```

Кросс-компиляция «из коробки»: Flutter для Android использует Gradle + NDK,
которые работают на любом Linux x86_64/aarch64. Для устройств **без Google Play**
соберите все ABI сразу — это дефолт; для экономии места:
`--split-per-abi`.

### 1.5. Подготовка iOS-части на Linux + сборка в macOS CI

На Linux отредактируйте `app/ios/Runner/Info.plist` (генерируется `flutter create`):

```xml
<key>NSCameraUsageDescription</key>              <string>Камера для AR-поиска животных</string>
<key>NSLocationWhenInUseUsageDescription</key>  <string>Поиск трейдов поблизости и гео-приор распознавания</string>
<key>NSPhotoLibraryUsageDescription</key>       <string>Загрузка фото для распознавания</string>
```

`app/ios/Runner/Runner.entitlements` — включите `sign-in-with-apple`
(для `sign_in_with_apple`), а в Firebase-консоли добавьте iOS-приложение
и положите `GoogleService-Info.plist` в `app/ios/Runner/`.

Затем сборка на macOS-runner (GitHub Actions, пример job'ы):

```yaml
ios-build:
  runs-on: macos-14
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with: { channel: stable }
    - run: cd app && flutter pub get && pod install --repo-update
    - run: cd app && flutter build ipa --release \
        --dart-define=INATURALIST_API_KEY=${{ secrets.INATURALIST_KEY }}
    - uses: actions/upload-artifact@v4
      with: { name: ipa, path: app/build/ios/ipa/*.ipa }
```

---

## 2. Как проверить работоспособность на Linux

### 2.1. Статическая проверка кода (не требует устройств)

```bash
cd app
flutter analyze          # линтер — должен быть "No issues found!"
dart format --set-exit-if-changed .
flutter test             # unit/widget-тесты (flutter_test уже в dev_dependencies)
```

Рекомендуемые тесты для текущей архитектуры:
* `models/collection_card_test.dart` — редкость, бонус-ролл, «блестящие»;
* `services/inaturalist_service_test.dart` — парсинг ответа vision-API
  (мокайте `Dio` через `MockAdapter` из `http_mock_adapter`);
* `providers/collection_provider_test.dart` — добавление карточки, дубликаты видов.

### 2.2. Эмулятор Android на Linux

Требуется KVM (значительно быстрее software-rendering):

```bash
# Проверка виртуализации
egrep -c '(vmx|svm)' /proc/cpuinfo     # >0 — OK
sudo apt install -y qemu-kvm
groups | grep -q kvm || (sudo adduser $USER kvm && newgrp kvm)

sdkmanager "emulator" "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n pixel7 -k "system-images;android-34;google_apis;x86_64" -d pixel_7

$ANDROID_HOME/emulator/emulator -avd pixel7 -gpu swiftshader_indirect &
flutter devices          # должен показать android-x64 устройство
cd app && flutter run -d emulator-5554
```

⚠️ Ограничения эмулятора: камера — симулированная (тестовое видео/паттерн),
реального GPS-«проximity» для трейдов нет — используйте фейковые локации:

```bash
telnet localhost 5554
> geo fix 37.6155 -122.0797
```

Для AR-скана без камеры: в `ar_scan_screen.dart` предусмотрите режим
«загрузить кадр из галереи» / unit-тест `AnimalRecognitionService` на
статичных изображениях — так вы проверите весь pipeline распознавания
(API + офлайн-фолбэк) прямо на Linux.

### 2.3. Физическое Android-устройство по Wi-Fi/USB

```bash
adb devices                       # USB — включите отладку по USB на телефоне
adb pair IP:PORT && adb connect IP:PORT   # беспроводная отладка (Android 11+)
cd app && flutter run --release -d <serial>
```

Это единственная полноценная проверка камеры/GPS/Firebase на Linux —
полноценного iOS-симулятора на Linux нет.

### 2.4. Проверка сетевых интеграций без телефона

API iNaturalist доступно напрямую с Linux — проверьте контракт до запуска приложения:

```bash
# Vision-классификация по фото
curl -F "image_file=@test_cat.jpg" \
     "https://api.inaturalist.org/v1/computervision/score_image" | jq '.results[0].scored_taxon_pred.name'

# Таксономия/энциклопедия
curl "https://api.inaturalist.org/v1/taxa?q=Puma%20concolor&fields=name,rank,ancestry,id" | jq
```

Бэкенд трейдов (если поднимете `backend/` локально) и Firestore проверяются
через Firebase Emulator Suite:

```bash
npm i -g firebase-tools
firebase init emulators && firebase emulators:start --only firestore,auth
```

### 2.5. Быстрый smoke-чек лист

- [ ] `flutter analyze` и `flutter test` зелёные
- [ ] `flutter build apk --debug` собирается на Linux
- [ ] на эмуляторе: вход (email/Google), скан кадра → карточка появляется в коллекции
- [ ] офлайн-фолбэк: вырубаете сеть → распознавание даёт результат из локального каталога
- [ ] трейд: второй эмулятор/телефон рядом → обменник показывает соседа

---

## Полезные команды

```bash
flutter clean && flutter pub get     # пересборка после правок pubspec
flutter build apk --analyze-size     # анализ размера APK
flutter run -d chrome                # быстрый UI-прогрев (без камеры/гео!)
```

Лицензия — см. [LICENSE](LICENSE).
