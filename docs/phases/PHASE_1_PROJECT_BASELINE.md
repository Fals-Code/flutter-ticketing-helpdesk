# Phase 1 — Project Baseline dan Repository Hygiene

Branch: `refactor/phase-1-project-baseline`

Baseline dibuat dari HEAD Phase 0 tervalidasi pada commit `7b62fe8d0eeecb7bd8eb2425c23c8d93624cce5e`.

Audit terhadap `main` menemukan satu commit squash Phase 0 pada `9b2e738f84942431a4ab13121fc58ac225c88d8b`. Perubahan tersebut sudah tersedia pada histori Phase 0, sehingga tidak ada merge tambahan.

## Hasil

- Identitas aplikasi menjadi TICKET-Q.
- Package Dart menjadi `ticket_q`.
- Versi menjadi `2.0.0+1`.
- Android application ID menjadi `com.falscode.ticketq`.
- Label Android dan iOS menjadi TICKET-Q.
- Import package dinormalisasi.
- Dependency yang terbukti tidak digunakan dihapus tanpa upgrade major.
- Konfigurasi repository, dokumentasi, dan quality gate dilengkapi.

Phase ini tidak mengubah RLS, policy backend, autentikasi, atau perilaku bisnis tiket.
