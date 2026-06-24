# Security Policy Testing dan Akun Uji

## Akun uji

Buat empat akun pada project staging/local melalui Supabase Auth. Jangan membuat akun ini pada production.

| Akun | Email contoh | Role DB |
|---|---|---:|
| User A | `usera@example.test` | 3 |
| User B | `userb@example.test` | 3 |
| Helpdesk | `helpdesk@example.test` | 2 |
| Admin | `admin@example.test` | 1 |

Register publik hanya menghasilkan role 3. Promosi Helpdesk/Admin pertama dilakukan melalui SQL Dashboard oleh project owner pada staging, lalu perubahan berikutnya memakai RPC Admin. Password test harus unik dan disimpan di password manager tim, bukan source.

## Test otomatis SQL

```bash
supabase start
supabase db reset
supabase test db supabase/tests/phase_2_policy_test.sql
```

Script memakai UUID deterministik, membuat data di dalam transaction, mensimulasikan JWT melalui role `authenticated`, lalu `ROLLBACK`.

Coverage:

1. User A hanya membaca tiketnya sendiri dan tidak membaca tiket User B.
2. User A gagal membuat object pada path tiket User B.
3. Admin berhasil assignment ke Helpdesk aktif.
4. History assignment menyimpan aktor Admin dan waktu.
5. Helpdesk gagal update tiket yang tidak assigned.
6. Helpdesk berhasil update tiket assigned melalui RPC.
7. User nonaktif langsung kehilangan akses RLS.
8. Admin tidak membaca isi notifikasi pribadi User A.

## Test manual melalui client

Gunakan hanya `SUPABASE_URL` dan anon key, lalu login sebagai setiap akun.

### User A vs User B

- Buat tiket sebagai User A.
- Login User B dan query ID tiket User A secara langsung.
- Expected: kosong/404 dari PostgREST; komentar, history, dan attachment juga gagal.

### Helpdesk scope

- Admin assign Ticket A ke Helpdesk.
- Helpdesk update Ticket A: berhasil.
- Helpdesk mencoba RPC pada Ticket B yang belum assigned: `42501`.

### Storage

- Upload valid ke `<ticketA>/<userA>/<uuid>.pdf`: berhasil.
- Ganti folder uploader menjadi User B: ditolak.
- Upload `.exe`, MIME yang tidak diizinkan, file >10 MiB, nama dengan `..`, atau upsert: ditolak.

### User inactive

- Admin menjalankan `admin_set_user_active(..., false, alasan)`.
- Session JWT lama mungkin masih ada di device, tetapi query database tetap tidak mengembalikan data karena policy memeriksa `profiles.is_active` pada setiap request.

## Secret audit

Jalankan:

```bash
git grep -n -I -E 'service_role|SUPABASE_SERVICE|sb_secret_|postgres(ql)?://[^ ]+:[^ ]+@' -- . \
  ':!docs/backend/SECURITY_POLICY_TESTING.md' \
  ':!supabase/README.md'
```

Expected: tidak ada credential atau penggunaan service role dalam source Flutter. Penyebutan istilah pada dokumentasi larangan bukan secret.
