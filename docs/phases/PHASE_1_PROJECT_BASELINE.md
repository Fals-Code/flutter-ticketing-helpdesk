# Phase 1 - Project Baseline dan Repository Hygiene

## Branch

`refactor/phase-1-project-baseline`

## Baseline

Branch ini disusun ulang dari Phase 0 tervalidasi:

`9b2e738f84942431a4ab13121fc58ac225c88d8b`

Sebelum reset, branch target lama yang diverged diamankan ke:

`backup/phase-1-diverged-before-baseline-reset`

## Scope

Phase 1 menetapkan baseline repository yang bersih, terdokumentasi, aman, dan mudah dijalankan dari fresh clone.

Dikerjakan:

- Audit perbedaan Phase 0 dengan `main` terbaru.
- Penetapan nama aplikasi TICKET-Q.
- Penetapan versi `2.0.0+1`.
- Penetapan Android application ID `com.falscode.ticketq`.
- Penetapan label Android dan iOS.
- Sanitasi placeholder Firebase Android.
- Penguatan `.gitignore` untuk build, environment, signing, dan file IDE lokal.
- README dan dokumentasi setup/branch/troubleshooting.
- Workflow quality gate untuk format, analyze, dan test.

Tidak dikerjakan:

- RLS atau policy backend.
- Fitur auth baru.
- Perubahan workflow tiket.
- Perubahan perilaku bisnis.

## Dependency audit

Tidak ada major upgrade dependency pada Phase 1. Dependency yang masih ada dipertahankan sampai audit runtime dan lockfile dapat divalidasi penuh, sehingga phase ini tidak membuat perubahan dependency berisiko.

## Validasi wajib

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```
