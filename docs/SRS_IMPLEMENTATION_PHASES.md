# SRS 2.0.0 Implementation Phases

Dokumen ini membagi perbaikan dan pengembangan E-Ticketing Helpdesk berdasarkan Software Requirement Specification Mobile Apps versi 2.0.0.

## Aturan penggabungan

- Setiap fase harus memiliki commit terpisah.
- Fase berikutnya dimulai setelah acceptance criteria fase aktif lulus.
- Authorization sensitif harus diamankan pada Supabase RLS/RPC, bukan hanya UI Flutter.
- Tidak ada credential produksi yang disimpan dalam repository.
- Migration production yang destruktif memerlukan change request dan konfirmasi eksplisit.

## Fase pengerjaan

| Fase | Fokus | Status |
|---|---|---|
| 0 | Pulihkan entrypoint Helpdesk, pisahkan demo Modul 8, perbaiki startup fallback dan smoke test | Selesai dan tervalidasi lokal/CI |
| 1 | Project baseline, repository hygiene, identitas aplikasi, dokumentasi, dan quality gate | PASS dan merged ke `main` pada `eb31a70` |
| 2 | Schema Supabase, migration, Storage policy, RLS, RPC, audit trail, dan security matrix | Implementasi selesai pada `feat/phase-2-supabase-security`; menunggu validasi Supabase lokal/CI |
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

- Format check: PASS, `0 changed`.
- `flutter analyze`: PASS, `No issues found!`.
- `flutter test`: PASS, `All tests passed!`.
- GitHub Actions `Flutter Quality Gate #15`: PASS.
- PR #4 merged ke `main` pada commit `eb31a70f455f6ba611a37bd004bfb7010ed6b17a`.

## Acceptance criteria Fase 2

- Migration dapat membentuk schema dari database lokal bersih.
- User A tidak membaca tiket User B.
- Helpdesk tidak mengubah tiket yang tidak ditugaskan.
- Admin dapat assignment ke Helpdesk aktif.
- Attachment lintas user/tiket ditolak.
- History mencatat actor dan timestamp.
- User nonaktif langsung kehilangan akses RLS.
- Admin tidak otomatis membaca notifikasi privat user lain.
- Flutter tidak mengandung service role key.

## Bukti Phase 2

- Migration: `supabase/migrations/20260625020000_phase_2_schema.sql plus ordered Phase 2 migrations`.
- Test: `supabase/tests/phase_2_policy_test.sql`.
- API/data dictionary: `docs/backend/SUPABASE_BACKEND_API.md`.
- Audit source/schema contract: `docs/backend/PHASE_2_SCHEMA_AUDIT.md`.
- Test account dan policy guide: `docs/backend/SECURITY_POLICY_TESTING.md`.

## Validasi lokal yang wajib dijalankan setelah pull

```bash
supabase start
supabase db reset
supabase test db supabase/tests/phase_2_policy_test.sql
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
