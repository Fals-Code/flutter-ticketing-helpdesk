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
- Sanitasi konfigurasi Firebase Android untuk repository.
- Penguatan `.gitignore` untuk build, environment, signing, dan file IDE lokal.
- README dan dokumentasi setup/branch/troubleshooting.
- Workflow quality gate untuk format, analyze, dan test.
- Normalisasi format source Dart dan perbaikan lint.

Tidak dikerjakan:

- RLS atau policy backend.
- Fitur auth baru.
- Perubahan workflow tiket.
- Perubahan perilaku bisnis.

## Dependency audit

Tidak ada major upgrade dependency pada Phase 1. Dependency yang masih ada dipertahankan sampai audit runtime dan lockfile dapat divalidasi penuh, sehingga phase ini tidak membuat perubahan dependency berisiko.

## Keputusan identitas package

Identitas aplikasi yang menjadi gate Phase 1 telah ditetapkan melalui nama tampilan TICKET-Q, versi `2.0.0+1`, Android application ID `com.falscode.ticketq`, serta label Android/iOS. Nama package Dart internal `uts` dipertahankan karena perubahan massal import tidak diperlukan untuk memenuhi acceptance criteria Phase 1 dan tidak memberi manfaat runtime. Keputusan ini dicatat agar kondisi repository tetap transparan.

## Validasi wajib

```bash
flutter clean
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

## Bukti penutupan

Status: **PASS lokal dan CI, siap digabungkan ke `main`.**

- Branch lokal dan remote sinkron pada commit `3682a03`.
- `flutter clean`: PASS.
- `flutter pub get`: PASS.
- Format check: PASS, `0 changed`.
- `flutter analyze`: PASS, `No issues found!`.
- `flutter test`: PASS, `All tests passed!`.
- `git diff --check`: PASS.
- Working tree bersih setelah commit.
- GitHub Actions `Flutter Quality Gate #15`: PASS pada commit `3682a03`.

## Gate penutupan resmi

Phase 1 dinyatakan resmi **CLOSED** setelah pull request resmi dari `refactor/phase-1-project-baseline` ke `main` memiliki quality gate hijau dan telah di-merge. Branch Phase 2 wajib dibuat dari `main` setelah merge tersebut.
