# Branch Strategy

Pengembangan TICKET-Q dilakukan per phase agar scope tetap jelas dan mudah diaudit.

## Branch utama

- `main`: baseline stabil terakhir.
- `fix/phase-0-restore-helpdesk-entrypoint`: restore baseline produksi.
- `refactor/phase-1-project-baseline`: repository hygiene dan dokumentasi.
- `feat/phase-2-supabase-security`: backend dan aturan akses data.
- `feat/phase-3-auth-rbac`: autentikasi dan role.
- `feat/phase-4-ticket-core`: fungsi inti tiket.
- `feat/phase-5-ticket-workflow`: assignment dan workflow tiket.
- `feat/phase-6-notifications`: notifikasi.
- `feat/phase-7-dashboard-admin`: dashboard dan admin.
- `refactor/phase-8-ui-nfr`: UI/UX dan NFR.
- `release/srs-2.0.0-compliance`: release dan compliance.

## Aturan kerja

1. Branch phase baru dibuat dari phase sebelumnya yang sudah PASS.
2. Jangan merge atau cherry-pick tanpa audit perubahan.
3. Perubahan fitur bisnis hanya masuk phase yang sesuai.
4. Jalankan quality gate lokal sebelum pull request.
5. Secret, keystore, dan file environment lokal tidak boleh masuk commit.

## Phase 1

Branch `refactor/phase-1-project-baseline` dibuat dari Phase 0 tervalidasi `9b2e738f84942431a4ab13121fc58ac225c88d8b`.
