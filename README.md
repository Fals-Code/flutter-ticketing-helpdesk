# TICKET-Q

TICKET-Q adalah aplikasi mobile E-Ticketing Helpdesk berbasis Flutter untuk membuat, memantau, dan menangani tiket layanan. Aplikasi melayani tiga role: User, Helpdesk, dan Admin.

Target produk mengikuti SRS Mobile Apps versi 2.0.0. Backend utama menggunakan Supabase, sedangkan push notification menggunakan Firebase Cloud Messaging.

## Status baseline

- Branch aktif Phase 1: `refactor/phase-1-project-baseline`
- Versi aplikasi: `2.0.0+1`
- Android application ID: `com.falscode.ticketq`
- Flutter/Dart package: `ticket_q`
- State management: BLoC
- Routing: GoRouter
- Dependency injection: GetIt

Phase 1 hanya membentuk baseline repository. Perubahan RLS, policy backend, dan penyelesaian fitur autentikasi tidak termasuk dalam phase ini.

## Menjalankan dari fresh clone

Prasyarat:

- Flutter stable dengan Dart yang memenuhi `sdk: ^3.5.0`
- Android Studio dan Android SDK untuk target Android
- Xcode dan CocoaPods untuk target iOS
- Java 17
- Project Supabase dan Firebase yang sesuai environment

Langkah awal:

```bash
git clone https://github.com/Fals-Code/flutter-ticketing-helpdesk.git
cd flutter-ticketing-helpdesk
git switch refactor/phase-1-project-baseline
flutter doctor
flutter clean
flutter pub get
```

Salin konfigurasi Supabase contoh:

```bash
cp define_config.example.json define_config.json
```

PowerShell:

```powershell
Copy-Item define_config.example.json define_config.json
```

Isi `define_config.json` dengan nilai environment lokal. Jangan commit file tersebut.

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key"
}
```

Jalankan aplikasi:

```bash
flutter run --dart-define-from-file=define_config.json
```

`android/app/google-services.json` di repository hanya konfigurasi placeholder aman agar fresh clone tetap dapat diproses oleh tooling Android. Ganti dengan file dari Firebase Console untuk menguji FCM pada project nyata, lalu pastikan tidak ada credential privat yang ikut masuk commit.

## Quality gate

Sebelum commit atau pull request, jalankan:

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

Workflow `.github/workflows/quality-gate.yml` menjalankan pemeriksaan format, analyze, test, dan memastikan `flutter pub get` tidak mengubah lockfile.

## Struktur utama

```text
lib/
├── app/                 # Bootstrap dan composition root
├── core/                # Router, DI, service, constants, storage
├── features/            # Modul auth, ticket, notification, dashboard, admin
├── shared/              # Widget dan theme lintas feature
└── labs/                # Hasil praktikum yang tidak menjadi entrypoint produksi
```

Setiap feature mengikuti pemisahan `data`, `domain`, dan `presentation` sejauh dibutuhkan. Perpindahan file yang tidak memberi manfaat nyata dihindari, karena manusia sudah cukup sering merapikan folder sampai aplikasinya sendiri lupa cara hidup.

## Dokumentasi

- [Panduan setup](docs/SETUP.md)
- [Strategi branch](docs/BRANCH_STRATEGY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Catatan Phase 1](docs/phases/PHASE_1_PROJECT_BASELINE.md)
- [Roadmap implementasi SRS](docs/SRS_IMPLEMENTATION_PHASES.md)

## Keamanan repository

File berikut tidak boleh masuk Git:

- `define_config.json` dan variasi environment lokal
- `.env` dan turunannya
- `key.properties`
- keystore Android
- provisioning/signing file lokal
- output `build`, `.dart_tool`, cache IDE, dan artefak hasil pengujian

Jangan menaruh service role key, password, private key, atau credential signing dalam README, workflow, issue, maupun source code.
