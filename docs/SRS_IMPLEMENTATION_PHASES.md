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
| 0 | Pulihkan entrypoint Helpdesk, pisahkan demo Modul 8, perbaiki startup fallback dan smoke test | Selesai diimplementasikan, menunggu validasi lokal/CI |
| 1 | Audit baseline arsitektur, environment, dependency injection, lifecycle BLoC, dan dokumentasi teknis | Belum dimulai |
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

## Validasi lokal yang wajib dijalankan setelah pull

```bash
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
```

Jalankan aplikasi menggunakan konfigurasi lokal yang tidak masuk Git:

```bash
flutter run --dart-define-from-file=define_config.json
```
