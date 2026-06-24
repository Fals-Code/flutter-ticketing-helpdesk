# Phase 2: Supabase Backend dan Security

Branch: `feat/phase-2-supabase-security`

Baseline: merge commit Phase 1 `eb31a70f455f6ba611a37bd004bfb7010ed6b17a`.

## Output

- Migration additive dari kondisi bersih untuk `profiles`, `tickets`, `comments`, `ticket_history`, `notifications`, `device_tokens`, `app_settings`, `ticket_attachments`, dan `admin_audit_log`.
- Constraint role/status/rating/file serta index untuk policy dan query utama.
- Validasi `assigned_to` hanya Helpdesk aktif.
- Trigger audit status, assignment, soft delete/restore, komentar, attachment, role, dan aktivasi user.
- RPC terkontrol untuk assignment, status, override Admin, delete/restore, role, aktivasi, token, attachment metadata, dan statistik.
- Bucket private `tickets` dengan batas MIME/size/path/name dan tanpa overwrite policy.
- RLS minimum User, Helpdesk, Admin; notifikasi tetap privat per user.
- Security-invoker view dan Realtime publication.
- SQL policy test reproducible dan panduan akun uji.
- Dokumentasi backend API, schema audit, error, role, dan policy matrix.

## Acceptance criteria

| Kriteria | Bukti desain/test |
|---|---|
| User A tidak membaca tiket User B | `phase_2_policy_test.sql` scope assertion |
| Helpdesk tidak update tiket non-assigned | RPC negative test |
| Admin dapat assignment | `assign_ticket` positive test |
| Attachment lintas user ditolak | Storage RLS negative test |
| History mencatat aktor dan waktu | Trigger assertion |
| Nonaktif memengaruhi akses | Admin deactivate + User A zero-row assertion |
| Migration dari kondisi bersih | `supabase db reset` procedure |
| Tidak ada service role di Flutter | repository grep dan anon-key-only contract |

## Keputusan desain

- Role Helpdesk tetap direpresentasikan oleh enum source `technician` dan nilai DB 2.
- Assigned adalah derived ownership dari `assigned_to`, bukan status lifecycle.
- Status kanonik: `open`, `pending`, `in_progress`, `resolved`, `closed`, `reopened`.
- Flutter route guard hanya lapisan UX; backend RLS/RPC adalah otorisasi utama.
- Admin tidak memiliki policy baca notifikasi user lain. Audit notifikasi lintas-user memerlukan change request dan alasan yang terdokumentasi.
- Migration production tidak dijalankan otomatis dan tidak memuat operasi destruktif.

## Validation commands

```bash
supabase start
supabase db reset
supabase test db supabase/tests/phase_2_policy_test.sql
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git status --short
```

## Scope boundary

Phase 2 berhenti pada backend contract dan security gate. UI signed URL, attachment upload workflow, auth screen, ticket screens, notification delivery, dan dashboard integration tetap mengikuti Phase 3-7.
