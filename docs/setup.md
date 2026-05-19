# 개발 환경 설정 가이드 (Zero → Run)

처음부터 앱을 실행하기까지 필요한 모든 단계를 설명합니다.

---

## 사전 요구사항

| 도구 | 최소 버전 | 확인 명령어 |
|------|-----------|-------------|
| Flutter SDK | 3.x | `flutter --version` |
| Dart SDK | 3.x (Flutter 내장) | `dart --version` |
| Git | 2.x | `git --version` |
| Android Studio 또는 VS Code | 최신 | — |

---

## 1단계 — Flutter SDK 설치

### Windows

```powershell
# winget으로 설치 (권장)
winget install Google.Flutter

# 또는 공식 사이트에서 zip 다운로드 후 PATH에 추가
# https://docs.flutter.dev/get-started/install/windows
```

환경 변수 `PATH` 에 `C:\flutter\bin` 추가 후 새 터미널 재실행.

### macOS

```bash
# Homebrew 사용
brew install --cask flutter

# 또는 공식 사이트에서 압축 파일 다운로드
# https://docs.flutter.dev/get-started/install/macos
```

### Linux (Ubuntu/Debian)

```bash
# snap으로 설치
sudo snap install flutter --classic

# 또는 tar.xz 다운로드 후 설치
# https://docs.flutter.dev/get-started/install/linux
```

---

## 2단계 — Android 에뮬레이터 또는 실기기 설정

### 에뮬레이터 (Android Studio)
1. Android Studio 실행 → **Virtual Device Manager** → **Create Device**
2. Pixel 7 (API 33 이상) 권장
3. 에뮬레이터 시작

### 실기기 (Android)
1. 기기에서 **설정 → 개발자 옵션** 활성화
2. **USB 디버깅** 켜기
3. USB로 PC에 연결

### 실기기 (iOS, macOS 전용)
```bash
# Xcode 커맨드라인 툴 설치
xcode-select --install
sudo xcodebuild -runFirstLaunch
```

---

## 3단계 — 저장소 클론 & 실행

```bash
# 1. 저장소 클론
git clone https://github.com/dnf98083-cmyk/chatbudget-flutter.git
cd chatbudget-flutter

# 2. 의존성 설치
flutter pub get

# 3. Flutter 환경 점검
flutter doctor

# 4. 앱 실행 (에뮬레이터 또는 기기가 연결된 상태)
flutter run
```

> **한 줄 실행**: `git clone https://github.com/dnf98083-cmyk/chatbudget-flutter.git && cd chatbudget-flutter && flutter pub get && flutter run`

---

## 빌드 명령어

```bash
# Android APK (배포용)
flutter build apk --release

# Android App Bundle (Play Store용)
flutter build appbundle

# iOS (macOS 필요)
flutter build ios --release

# 웹
flutter build web
```

---

## VS Code 설정 (권장)

1. VS Code 설치 후 확장 설치:
   - **Flutter** (by Dart Code)
   - **Dart** (by Dart Code)
2. `F5` 키로 디버그 실행
3. Hot Reload: `r` 키 (터미널) 또는 저장 시 자동 적용

---

## FAQ

### Q1. `flutter doctor` 에서 경고가 뜨는데 실행이 안 됩니다

```
✗ Android toolchain - develop for Android devices
```

Android SDK 설치가 필요합니다.

```bash
# Android Studio를 통해 설치하거나
flutter doctor --android-licenses  # 라이선스 동의
```

또는 Android Studio → **SDK Manager** → **Android SDK** 설치.

---

### Q2. `flutter pub get` 이 실패합니다

네트워크 문제이거나 pub.dev 접속 오류일 수 있습니다.

```bash
# 캐시 초기화 후 재시도
flutter pub cache clean
flutter pub get

# 중국/방화벽 환경이라면
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```

---

### Q3. 에뮬레이터를 찾지 못합니다 (`No devices found`)

```bash
# 연결된 기기 목록 확인
flutter devices

# 에뮬레이터 목록 확인 및 실행
flutter emulators
flutter emulators --launch <emulator-id>
```

VS Code: 우측 하단 기기 선택 드롭다운에서 에뮬레이터 선택.

---

### Q4. 빌드 실패 시 어디부터 확인하나요?

```bash
# 1. Flutter 환경 점검
flutter doctor -v

# 2. 의존성 재설치
flutter clean && flutter pub get

# 3. 상세 에러 로그 확인
flutter run --verbose

# 4. Dart 분석
flutter analyze
```

확인 순서: `flutter doctor` → `flutter clean` → 에러 메시지 정확히 읽기 → pub.dev에서 패키지 호환성 확인.

---

### Q5. iOS 빌드가 안 됩니다 (macOS)

```bash
# CocoaPods 설치 확인
sudo gem install cocoapods
cd ios && pod install && cd ..

# Xcode 버전 확인 (14 이상 필요)
xcodebuild -version

# 시뮬레이터 목록 확인
xcrun simctl list devices
flutter run -d <simulator-id>
```
