# Branch Strategy

Setiap phase memakai branch terpisah yang dibuat dari HEAD phase sebelumnya setelah validasi selesai.

## Pola nama

- `fix/phase-<n>-<fokus>` untuk perbaikan.
- `feat/phase-<n>-<fokus>` untuk fitur.
- `refactor/phase-<n>-<fokus>` untuk refactor.
- `release/<versi>-<fokus>` untuk release.

## Aturan

1. Bandingkan baseline phase dengan `main` terbaru.
2. Audit perubahan berdasarkan tujuan, file, risiko, dan relevansi.
3. Ambil hanya perubahan yang masih dibutuhkan.
4. Buat commit kecil dengan satu fokus.
5. Jalankan quality gate sebelum review.
6. Mulai phase berikutnya setelah acceptance criteria phase aktif terpenuhi.

Dokumentasikan sumber branch, hasil audit, hasil validasi, dan batas pekerjaan pada pull request.
