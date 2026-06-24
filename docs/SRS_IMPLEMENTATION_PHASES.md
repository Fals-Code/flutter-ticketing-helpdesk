# SRS 2.0.0 Implementation Phases

Dokumen ini membagi perbaikan dan pengembangan E-Ticketing Helpdesk berdasarkan Software Requirement Specification Mobile Apps versi 2.0.0.

## Aturan penggabungan

- Setiap fase harus memiliki commit terpisah.
- Fase berikutnya dimulai setelah analyzer dan test fase aktif lulus.
- Authorization sensitif harus diamankan pada Supabase RLS/RPC, bukan hanya UI Flutter.
- Tidak ada credential produksi yang disimpan dalam repository.

## Fase pengerjaan

| Fase | Fokus | Status |
|---|---|---|
| 0 | Pulihkan entrypoint Helpdesk, pisahkan demo Modul 8, perbaiki startup fallback dan smoke test | Selesai dan tervalidasi lokal/CI |
| 1 | Project baseline, repository hygiene, identitas aplikasi, dokumentasi, dan quality gate | PASS lokal dan CI; menunggu merge resmi ke `main` |
| 2 | Schema Supabase, migration, Storage policy, RLS, RPC, audit trail, dan security matrix | Belum dimulai |
| 3 | Authentication, session, akun nonaktif, dan route-based access control | Belum dimulai |
| 4 | Pembuatan, daftar, detail, attachment umum, pagination, dan soft-delete tiket | Belum dimulai |
| 5 | Assignment, status transition, komentar, history, dan tracking khusus | Belum dimulai |
| 6 | Notifikasi in-app, Realtime, FCM, local notification, token lifecycle, dan deep link | Belum dimulai |
| 7 | Statistik lima kategori SRS serta manajemen aktivasi dan role pengguna | Belum dimulai |
| 8 | Penyelarasan UI/UX, responsivitas, Android/iOS, dark/light mode, dan aksesibilitas | Belum dimulai |
| 9 | Integration test, traceability matrix, dokumentasi rilis, build gate, dan audit final | Belum dimulai |

## Acceptance criteria Fase 0

- `lib/main.dart` tidak lagi menjalankan demo Assets dan Media.
- Demo Modul 8 tetap tersedia di `lib/labs/module_8/`.
- Bootstrap menginisialisasi Firebase, Supabase, dependency injection, local notification, FCM, dan locale Indonesia.
- Aplikasi menggunakan `MaterialApp.router`, GoRouter, BLoC global, light/dark theme, error boundary, dan connectivity banner.
- Konfigurasi backend yang hilang menghasilkan halaman diagnostik, bukan crash.
- Kegagalan startup menghasilkan fallback yang dapat dibaca.
- Smoke test lama yang mengharapkan `Assets dan Media` telah diganti.

## Acceptance criteria Fase 1

- Fresh clone dapat menjalankan `flutter pub get`.
- Nama aplikasi, versi, Android application ID, dan label tidak memakai placeholder.
- README dan dokumentasi setup dapat diikuti pengguna baru.
- Secret, keystore, environment lokal, dan artefak build tidak masuk Git.
- Quality gate tersedia untuk format, analyze, dan test.

## Bukti Phase 1

- Validasi lokal pada commit `3682a03`: PASS.
- Format check: PASS, `0 changed`.
- `flutter analyze`: PASS, `No issues found!`.
- `flutter test`: PASS, `All tests passed!`.
- GitHub Actions `Flutter Quality Gate #15`: PASS.
- Branch Phase 1 siap ditinjau dan digabungkan ke `main`.

## Validasi lokal yang wajib dijalankan setelah pull

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

Jalankan aplikasi menggunakan konfigurasi lokal yang tidak masuk Git:

```bash
flutter run --dart-define-from-file=define_config.json
```
