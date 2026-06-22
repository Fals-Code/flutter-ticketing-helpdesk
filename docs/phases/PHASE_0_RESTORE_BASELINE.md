# Phase 0 — Restore Helpdesk Baseline

## Branch

`fix/phase-0-restore-helpdesk-entrypoint`

## Tujuan

Memulihkan aplikasi E-Ticketing Helpdesk sebagai entrypoint produksi setelah
`lib/main.dart` tertimpa demo praktikum Modul 8 Assets & Media.

## Perubahan

- Memulihkan bootstrap Firebase, Supabase, GetIt, FCM, local notification, dan
  locale Indonesia.
- Memulihkan `MaterialApp.router`, GoRouter, light/dark theme, dan global BLoC.
- Memulai subscription tiket, statistik, dan notifikasi setelah autentikasi.
- Mereset state yang membawa data pengguna ketika logout atau sesi kedaluwarsa.
- Menambahkan halaman error aman untuk konfigurasi build yang tidak tersedia.
- Menghapus DNS/network debug probe dari startup produksi.
- Memindahkan demo Modul 8 ke `lib/labs/module_8/`.
- Mengganti widget test yang sebelumnya menguji halaman demo.
- Menambahkan contoh konfigurasi `define_config.example.json` tanpa credential.

## Menjalankan di lokal

Salin contoh konfigurasi:

```powershell
Copy-Item define_config.example.json define_config.json
```

Isi `define_config.json` dengan konfigurasi Supabase lokal Anda. File aktual
`define_config.json` sudah diabaikan oleh Git.

Jalankan pemeriksaan:

```powershell
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
```

Jalankan aplikasi:

```powershell
flutter run --dart-define-from-file=define_config.json
```

## Status Validasi

Status: PASS

- Flutter analyze: No issues found
- Flutter test: 4 tests passed
- Runtime Android emulator: PASS
- Firebase initialization: PASS
- Supabase initialization: PASS
- FCM token synchronization: PASS
- Session restore: PASS
- Login dan logout: PASS
- Ticket list dan ticket detail: PASS
- Tidak ditemukan RenderFlex overflow
- Tidak ditemukan BehaviorSubject dynamic error
- Tidak ditemukan emit after event handler completed
- Release APK: PASS
- APK: build/app/outputs/flutter-apk/app-release.apk
- GitHub Actions Phase 0 Validation: PASS

## Batas Phase 0

Phase ini belum memperbaiki seluruh authorization dan kebutuhan fitur SRS.
Pekerjaan tersebut dilanjutkan secara terpisah agar perubahan dapat diaudit:

1. Phase 1 — project baseline dan arsitektur.
2. Phase 2 — Supabase schema, migration, storage, dan RLS.
3. Phase 3 — authentication dan RBAC.
4. Phase 4 — ticket core dan attachment.
5. Phase 5 — workflow, assignment, history, dan tracking.
6. Phase 6 — notification service.
7. Phase 7 — dashboard dan user management.
8. Phase 8 — UI/UX dan non-functional requirements.
9. Phase 9 — integration test dan release compliance.
