# Supabase Backend API dan Data Dictionary

## Prinsip akses

Flutter mengakses Supabase Auth, PostgREST, RPC, Realtime, dan Storage menggunakan anon key serta JWT user. Otorisasi ditentukan oleh RLS/RPC. Tidak ada operasi mobile yang memerlukan `service_role`.

## Role

| DB | Produk | Hak utama |
|---:|---|---|
| 3 | User | Tiket sendiri, komentar/history tiket sendiri, notifikasi dan token perangkat sendiri. |
| 2 | Helpdesk (`technician`) | Tiket yang `assigned_to = auth.uid()`, komentar/history dan update workflow tiket tersebut. |
| 1 | Admin | Seluruh tiket, assignment, override, user management, app settings, dan audit log. Notifikasi pribadi user lain tetap tidak terbaca. |

## Tabel

### `profiles`

Field penting: `id`, `email`, `full_name`, `role`, `avatar_url`, `is_active`, `created_at`, `updated_at`.

- `id` mereferensikan `auth.users.id`.
- Register publik selalu menghasilkan role 3.
- Role dan aktivasi hanya berubah melalui RPC Admin.
- User yang `is_active = false` gagal pada seluruh helper RLS utama.

### `tickets`

Field penting: `id`, `title`, `description`, `category`, `status`, `user_id`, `assigned_to`, `images`, `rating`, `rating_feedback`, timestamps, dan soft-delete fields.

- Status: `open`, `pending`, `in_progress`, `resolved`, `closed`, `reopened`.
- Assigned: `assigned_to IS NOT NULL`; tidak ada status `assigned`.
- `assigned_to` harus profile role 2 yang aktif.
- Hard delete tidak diberikan kepada `authenticated`.

### `comments`

Field: `id`, `ticket_id`, `user_id`, `message`, timestamps, `deleted_at`.

Client hanya `SELECT` dan `INSERT`. Update/delete tidak diberikan pada Phase 2.

### `ticket_history`

Field: `ticket_id`, `event_type`, `old_status`, `new_status`, `changed_by`, `actor_role`, `reason`, `metadata`, `created_at`.

Event: ticket created, status changed, Admin override, assignment, unassignment, soft delete/restore, comment, attachment upload/delete. Client tidak dapat insert langsung.

### `notifications`

Field: `user_id`, `title`, `message`, `ticket_id`, `notification_type`, `payload`, `is_read`, `read_at`, `created_at`.

Pemilik dapat membaca, mengubah read state, dan menghapus record sendiri. Admin tidak otomatis dapat membaca notifikasi orang lain.

### `device_tokens`

Token unik per device/user, platform `android|ios|web`, active state, timestamps. Gunakan RPC register/unregister.

### `app_settings`

Key/value JSON global. Record public dapat dibaca user aktif; record non-public dan write hanya Admin.

### `ticket_attachments`

Metadata lampiran untuk object private: `ticket_id`, `storage_path`, `file_name`, `mime_type`, `size_bytes`, `uploaded_by`, delete metadata.

### `admin_audit_log`

Audit perubahan role dan aktivasi user. Hanya Admin dapat membaca; insert dilakukan trigger.

## View

### `v_ticket_scope`

Security-invoker view atas tiket aktif. Menambahkan field derived `is_assigned`:

```sql
assigned_to is not null and status <> 'closed'
```

View tetap mengikuti RLS tabel `tickets`.

## RPC

### `assign_ticket`

Admin-only. Assignment tidak otomatis membuat status baru.

```dart
final row = await supabase.rpc('assign_ticket', params: {
  'p_ticket_id': ticketId,
  'p_technician_id': technicianId,
  'p_reason': 'Assigned by triage',
});
```

Response: satu composite row `tickets`.

Errors: `42501` bukan Admin; `P0002` tiket tidak ada; `23514` target bukan Helpdesk aktif atau tiket closed.

### `update_ticket_status`

Admin atau Helpdesk yang assigned. Transisi mengikuti state machine.

```dart
await supabase.rpc('update_ticket_status', params: {
  'p_ticket_id': ticketId,
  'p_new_status': 'in_progress',
  'p_reason': 'Mulai investigasi',
});
```

Errors: `42501` scope salah; `22023` status tidak dikenal; `23514` transisi ilegal.

### `admin_override_ticket_status`

Admin-only, alasan minimal lima karakter. Dipakai untuk transisi di luar state machine dan dicatat sebagai `admin_override`.

### `soft_delete_ticket` / `restore_ticket`

- User hanya dapat soft-delete tiket sendiri yang masih `open` dan belum assigned.
- Admin dapat soft-delete dan restore dengan alasan.
- Tidak ada hard delete client.

### `admin_update_user_role`

Admin-only. Role 1/2/3, alasan wajib, tidak boleh mengubah role sendiri, dan tidak boleh menghilangkan satu-satunya Admin aktif.

### `admin_set_user_active`

Admin-only. Menonaktifkan akun langsung membuat helper RLS gagal. Admin tidak dapat menonaktifkan dirinya sendiri atau satu-satunya Admin aktif.

### `register_device_token` / `unregister_device_token`

Mengikat token ke user yang sedang login dan device ID.

### `register_ticket_attachment`

Dipanggil setelah object berhasil di-upload ke bucket `tickets`. Path, ticket, uploader, MIME, ukuran, dan filename diverifikasi lagi sebelum metadata disimpan.

### `get_ticket_stats`

Menghasilkan JSON:

```json
{
  "total": 10,
  "open": 3,
  "assigned": 4,
  "pending": 1,
  "in_progress": 2,
  "resolved": 2,
  "closed": 2,
  "reopened": 0
}
```

Agregasi mengikuti RLS caller.

## Storage API

Bucket: `tickets`, private, maksimum 10 MiB.

Path:

```text
<ticket_uuid>/<auth.uid()>/<filename>
```

Upload hanya untuk pihak yang boleh mengakses tiket. Download memakai authenticated download atau signed URL berumur pendek. Cross-user/cross-ticket path ditolak. `UPDATE` object tidak diizinkan, jadi nama object harus unik.

## Error contract

| SQLSTATE | Kategori | Contoh respons aplikasi |
|---|---|---|
| `42501` | Authorization | Tampilkan “Anda tidak berwenang” dan refresh scope. |
| `23514` | Business rule/constraint | Tampilkan pesan transisi, role target, atau file yang tidak valid. |
| `22023` | Invalid parameter | Tampilkan error validasi input. |
| `P0002` | Not found | Refresh daftar/detail; jangan menganggap data masih ada. |
| PostgREST `PGRST*` | Contract/query | Log tanpa data sensitif dan tampilkan pesan generik. |

## Policy matrix ringkas

| Resource | User | Helpdesk | Admin |
|---|---|---|---|
| Tickets | Own | Assigned | All |
| Comments | Own-ticket | Assigned-ticket | All-ticket |
| History | Own-ticket | Assigned-ticket | All-ticket |
| Attachments | Own-ticket | Assigned-ticket | All-ticket |
| Notifications | Own only | Own only | Own only by default |
| Profiles | Own + participants | Own + participants | All |
| User management | No | No | RPC only |
