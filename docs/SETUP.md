# Panduan Setup TICKET-Q

## Prasyarat

Gunakan Flutter stable, Java 17, Android Studio beserta Android SDK, dan Git. Untuk iOS diperlukan macOS, Xcode, serta CocoaPods.

```bash
flutter doctor -v
java -version
git --version
```

## Clone dan pilih branch

```bash
git clone https://github.com/Fals-Code/flutter-ticketing-helpdesk.git
cd flutter-ticketing-helpdesk
git switch refactor/phase-1-project-baseline
git status --short
```

## Konfigurasi Supabase

Salin template:

```bash
cp define_config.example.json define_config.json
```

PowerShell:

```powershell
Copy-Item define_config.example.json define_config.json
```

Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` untuk environment lokal. `define_config.json` diabaikan Git dan tidak boleh masuk commit.

## Konfigurasi Firebase Android

File `android/app/google-services.json` pada repository adalah placeholder aman. Untuk menguji Firebase dan FCM, daftarkan package `com.falscode.ticketq`, unduh konfigurasi Android dari project Firebase tim, lalu gunakan file tersebut secara lokal.

## Dependency dan runtime

```bash
flutter clean
flutter pub get
flutter run --dart-define-from-file=define_config.json
```

Pilih device tertentu bila diperlukan:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=define_config.json
```

## Validasi sebelum commit

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

Format harus bersih, analyzer tidak boleh menemukan issue, seluruh test harus lulus, dan working tree hanya berisi perubahan yang memang akan di-commit.

Build release final dan signing dikerjakan pada Phase 9. Phase 1 tidak membuat keystore produksi.
