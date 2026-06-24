# Troubleshooting

## `SUPABASE_URL` atau `SUPABASE_ANON_KEY` kosong

Pastikan `define_config.json` sudah dibuat dari `define_config.example.json`, lalu jalankan aplikasi dengan `--dart-define-from-file=define_config.json`.

## `flutter pub get` gagal

1. Jalankan `flutter doctor`.
2. Pastikan versi Flutter memakai channel stable.
3. Hapus `.dart_tool/` lalu ulangi `flutter pub get`.

## Android build gagal karena Firebase

`android/app/google-services.json` pada baseline adalah placeholder. Untuk menguji Firebase/FCM, unduh file baru dari Firebase Console dengan package `com.falscode.ticketq`.

## Kotlin cache error di Windows

Phase 0 sudah menonaktifkan incremental Kotlin build untuk menghindari masalah cache lintas drive. Jika masih terjadi, jalankan `flutter clean` lalu ulangi build.

## Format check gagal

Jalankan:

```bash
dart format .
```

Kemudian ulangi:

```bash
dart format --output=none --set-exit-if-changed .
```

## Analyze atau test gagal

Pastikan tidak ada perubahan fitur di luar scope Phase 1. Jalankan `flutter clean`, `flutter pub get`, `flutter analyze`, dan `flutter test` secara berurutan.
