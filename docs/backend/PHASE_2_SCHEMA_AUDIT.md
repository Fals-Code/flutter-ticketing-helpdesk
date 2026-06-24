# Phase 2 Schema Audit

## Scope audit

Audit dilakukan pada HEAD Phase 1 yang telah PASS dan merged ke `main` melalui PR #4. Repository belum memiliki folder `supabase/`, migration SQL, RLS policy, storage policy, atau policy test sebagai artefak versioned. Karena akses ke project Supabase production tidak diberikan, audit ini membatasi kesimpulan pada source repository dan tidak menganggap schema remote yang tidak terlihat sebagai fakta.

## Kontrak yang sudah dipakai source

| Resource | Kontrak source sebelum Phase 2 | Keputusan Phase 2 |
|---|---|---|
| `profiles` | `id`, `email`, `full_name`, `role` integer, `avatar_url` | Dipertahankan. Role 1/2/3 diberi constraint; 2 dipetakan ke Helpdesk/`technician`. Ditambah `is_active` dan timestamps. |
| `tickets` | `title`, `description`, `category`, `status`, `user_id`, `assigned_to`, `images`, rating | Dipertahankan dan ditambah soft-delete/audit fields. Status kanonik: `open`, `pending`, `in_progress`, `resolved`, `closed`, `reopened`. |
| `comments` | `ticket_id`, `user_id`, `message`, profile join | Dibuat append-only untuk client; baca/tulis mengikuti scope tiket. |
| `ticket_history` | `old_status`, `new_status`, `changed_by`, `created_at` | Diperluas dengan `event_type`, role aktor, alasan, dan metadata. Insert hanya oleh trigger/RPC. |
| `notifications` | record per `user_id` | Tetap privat per pemilik. Admin tidak mendapat policy baca lintas-user. |
| Storage `tickets` | source lama memakai `ticket_images/<uuid>` dan public URL | Diganti kontrak backend private: `<ticket_id>/<uploader_id>/<filename>`. Integrasi UI upload/signed URL dituntaskan pada Ticket Core, bukan dengan membuka bucket ke publik. |

## Temuan keamanan source

1. Source mengandalkan filter client untuk beberapa query. Filter UI bukan batas keamanan; RLS kini menjadi batas utama.
2. Assignment lama dilakukan dengan direct update dan sekaligus memaksa `in_progress`. Backend Phase 2 menyediakan `assign_ticket`; metrik Assigned dihitung dari `assigned_to`, bukan enum baru.
3. Update status lama dilakukan dengan direct update. RPC `update_ticket_status` dan `admin_override_ticket_status` menyediakan validasi state machine dan alasan audit.
4. Notifikasi lama dapat dicoba melalui direct insert dari client. Phase 2 menutup insert client dan membuat notifikasi dari trigger backend agar aktor tidak dapat mengirim notifikasi arbitrer kepada user lain.
5. Storage lama memakai public URL. Bucket Phase 2 private dan tidak menyediakan policy overwrite.
6. Pencarian repository tidak menemukan `service_role` key atau penggunaan service-role client pada Flutter.

## Batas audit

- Tidak ada perubahan destruktif terhadap database production.
- Data remote yang sudah ada harus diperiksa sebelum constraint divalidasi.
- Perubahan Flutter untuk signed URL, attachment metadata, dan UX error tetap berada pada phase fitur terkait. Backend contract-nya sudah tersedia pada Phase 2.
