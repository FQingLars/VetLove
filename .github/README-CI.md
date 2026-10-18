# GitHub Actions CI/CD Setup

This repository includes comprehensive CI/CD workflows for building and testing the Flutter application "critter_collect" across multiple platforms.

## Overview

The CI setup includes:
- **Static Analysis**: Code quality checks, formatting validation, and unit tests
- **Android Builds**: APK (debug) and AAB (release) generation on Linux
- **iOS Builds**: IPA (release) generation on macOS
- **Package Delivery**: Distribution of final artifacts for production deployment

## Workflow Files

### `flutter-builds.yml`

| Job | Platform | Runner | Trigger | Purpose |
|-----|----------|--------|---------|---------|
| `analyze` | Cross-platform | Ubuntu | Push/PR | Static analysis, formatting, and testing |
| `android-build` | Android | Ubuntu | Push/PR | APK/AAB build and artifact upload |
| `ios-build` | iOS | macOS-14 | Push/PR | IPA build and artifact upload |
| `android-delivery` | Android | Ubuntu | Main branch only | Final Android package delivery |
| `ios-delivery` | iOS | macOS-14 | Main branch only | Final iOS package delivery |

## Requirements

### Android Build Requirements
- Ubuntu runner with Flutter and Java 17
- Android SDK with platform tools and build tools 34.0.0
- Kotlin compiler for Gradle builds

### iOS Build Requirements
- macOS-14 runner with Flutter
- Xcode and CocoaPods installed
- Apple Developer account for code signing
- GoogleService-Info.plist file for Firebase integration
- Info.plist with camera, location, and photo library permissions
- Runner.entitlements for Apple Sign In

## Configuration Notes

### API Key Management
The iNaturalist API key is passed as a Dart define (`--dart-define=INATURALIST_API_KEY`). Store this in GitHub repository secrets:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add a secret named `INATURALIST_API_KEY`
3. The key will be used during release builds

### File Permissions
Make sure your `.github/workflows/flutter-builds.yml` is executable:

```bash
chmod +x .github/workflows/flutter-builds.yml
```

## Workflow Triggers

- **Push to main**: All jobs run on every push to the main branch
- **Pull requests**: All jobs run on pull requests targeting main
- **Delivery jobs**: Only run when merging to main branch

## Artifact Retention

- Build artifacts: 7 days
- Test results: 3 days
- Final delivery packages: 30 days

## Local Testing

You can run the same checks locally:

```bash
cd app
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter build apk --debug
flutter build appbundle --release
```

## Troubleshooting

### Android Build Failures
- Ensure Java 17 is installed: `sudo apt install -y openjdk-17-jdk`
- Check Android SDK installation: `flutter doctor`
- Verify Gradle wrapper is up to date: `./gradlew wrapper`

### iOS Build Failures
- iOS builds require a macOS runner - they cannot be run on Linux
- Ensure Xcode command line tools are installed
- Check that Info.plist and entitlements files are correctly configured

## Dependencies

This CI setup relies on the following GitHub Actions:

- `actions/checkout@v4`: Repository checkout
- `subosito/flutter-action@v2`: Flutter SDK management
- `actions/setup-java@v4`: Java installation
- `android-actions/setup-android@v3`: Android SDK setup
- `actions/upload-artifact@v4`: Artifact management
- `actions/download-artifact@v4`: Artifact retrieval