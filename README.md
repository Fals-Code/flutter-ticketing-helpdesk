# TICKET-Q

TICKET-Q adalah aplikasi mobile E-Ticketing Helpdesk berbasis Flutter untuk membuat, memantau, dan menangani tiket layanan. Aplikasi melayani tiga role utama: User, Helpdesk, dan Admin.

Target produk mengikuti SRS Mobile Apps versi 2.0.0. Backend utama menggunakan Supabase, sedangkan push notification menggunakan Firebase Cloud Messaging.

## Status baseline

- Branch aktif: `feat/phase-2-supabase-security`
- Baseline Phase 1 PASS: `eb31a70f455f6ba611a37bd004bfb7010ed6b17a`
- Versi aplikasi: `2.0.0+1`
- Android application ID: `com.falscode.ticketq`
- Android label: `TICKET-Q`
- iOS label: `TICKET-Q`
- State management: BLoC
- Routing: GoRouter
- Dependency injection: GetIt
- Backend authorization: Supabase RLS/RPC

Phase 2 menambahkan schema versioned, migration, private Storage bucket, RLS, RPC, trigger audit, policy test, dan dokumentasi backend. Flutter tetap menggunakan anon key; `service_role` tidak digunakan di aplikasi.

## Menjalankan dari fresh clone

Prasyarat:

- Flutter stable dengan Dart yang memenuhi `sdk: ^3.5.0`
- Android Studio dan Android SDK untuk target Android
- Java 17
- Xcode dan CocoaPods bila menguji target iOS
- Docker dan Supabase CLI bila menjalankan backend lokal
- Project Firebase bila menguji FCM pada perangkat nyata

Langkah awal:

```bash
git clone https://github.com/Fals-Code/flutter-ticketing-helpdesk.git
cd flutter-ticketing-helpdesk
git switch feat/phase-2-supabase-security
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

Jalankan aplikasi:

```bash
flutter run --dart-define-from-file=define_config.json
```

`android/app/google-services.json` di repository adalah placeholder aman untuk baseline. Ganti dengan file dari Firebase Console saat menguji Firebase/FCM pada project nyata, lalu pastikan tidak ada credential privat yang ikut masuk commit.

## Supabase lokal dan policy test

```bash
supabase start
supabase db reset
supabase test db supabase/tests/phase_2_policy_test.sql
```

Migration tidak memuat operasi destruktif. Deployment ke production tetap membutuhkan backup, dry run staging, pemeriksaan data existing, dan konfirmasi eksplisit.

## Quality gate lokal

Sebelum commit atau pull request, jalankan:

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

Workflow `.github/workflows/quality-gate.yml` menjalankan `flutter pub get`, validasi format, `flutter analyze`, dan `flutter test`.

## Struktur utama

```text
lib/
├── app/                 # Bootstrap dan composition root
├── core/                # Router, DI, service, constants, storage
├── features/            # Modul auth, ticket, notification, dashboard, admin
├── shared/              # Widget dan theme lintas feature
└── labs/                # Hasil praktikum yang tidak menjadi entrypoint produksi

supabase/
├── migrations/          # Schema, trigger, RPC, RLS, dan storage policy
├── tests/               # Reproducible SQL policy tests
├── config.toml          # Local Supabase configuration
└── README.md            # Backend setup and safety gate
```

Setiap feature mengikuti pemisahan `data`, `domain`, dan `presentation` sejauh dibutuhkan.

## Dokumentasi

- [Panduan setup](docs/setup.md)
- [Strategi branch](docs/branch-strategy.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Catatan Phase 1](docs/phases/PHASE_1_PROJECT_BASELINE.md)
- [Catatan Phase 2](docs/phases/PHASE_2_SUPABASE_SECURITY.md)
- [Audit schema Phase 2](docs/backend/PHASE_2_SCHEMA_AUDIT.md)
- [Supabase Backend API](docs/backend/SUPABASE_BACKEND_API.md)
- [Security policy testing](docs/backend/SECURITY_POLICY_TESTING.md)
- [Roadmap implementasi SRS](docs/SRS_IMPLEMENTATION_PHASES.md)

## Keamanan repository

File berikut tidak boleh masuk Git:

- `define_config.json` dan variasi environment lokal
- `.env` dan turunannya
- `key.properties`
- keystore Android
- file signing/provisioning lokal
- output `build`, `.dart_tool`, cache IDE, dan artefak hasil pengujian
- `supabase/.temp`, branch cache, dan credential local development

Jangan menaruh service role key, password, private key, atau credential signing dalam README, workflow, issue, maupun source code.
