# Troubleshooting

## `flutter pub get` mengubah lockfile

Periksa versi Flutter dan perubahan dependency:

```bash
flutter --version
git diff -- pubspec.lock
```

Jangan commit lockfile yang berubah tanpa audit.

## Konfigurasi Supabase tidak terbaca

Pastikan `define_config.json` berada di root project dan jalankan aplikasi dengan:

```bash
flutter run --dart-define-from-file=define_config.json
```

## Firebase Android tidak cocok dengan package

Gunakan konfigurasi Firebase Android yang terdaftar untuk `com.falscode.ticketq`. File repository hanya placeholder aman.

## Gradle gagal karena cache lintas drive

```bash
flutter clean
flutter pub get
```

Bila masih gagal, hapus cache lokal `android/.gradle` dan `android/.kotlin`, lalu ulangi build.

## APK tidak ditemukan

Pertahankan pengaturan output pada `android/build.gradle.kts` agar hasil build berada di folder `build` pada root Flutter.

## Format atau analyzer gagal

```bash
dart format .
flutter analyze
```

Periksa diff setelah format dan perbaiki sumber masalah sebelum mengubah aturan lint.

## Test meminta service eksternal

Test baseline harus memakai fallback atau fake yang tersedia. Validasi Phase 1 tidak bergantung pada koneksi production.
