# Setup TICKET-Q

Dokumen ini menjelaskan cara menjalankan TICKET-Q dari fresh clone.

## Prasyarat

- Flutter stable dengan Dart yang sesuai `sdk: ^3.5.0`.
- Java 17 untuk build Android.
- Android Studio dan Android SDK.
- Xcode dan CocoaPods jika menguji iOS.

## Fresh clone

1. Clone repository.
2. Switch ke branch `refactor/phase-1-project-baseline`.
3. Jalankan `flutter doctor`.
4. Jalankan `flutter clean`.
5. Jalankan `flutter pub get`.

## Konfigurasi runtime

Copy `define_config.example.json` menjadi `define_config.json`, lalu isi nilai environment lokal. File lokal ini sudah diabaikan Git.

Jalankan aplikasi dengan `flutter run --dart-define-from-file=define_config.json`.

## Quality gate lokal

1. `flutter clean`
2. `flutter pub get`
3. `dart format --output=none --set-exit-if-changed .`
4. `flutter analyze`
5. `flutter test`
6. `git status --short`

Phase 1 tidak mengerjakan fitur baru.
