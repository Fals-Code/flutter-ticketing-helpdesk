# Supabase Backend TICKET-Q

Folder ini adalah sumber kebenaran backend untuk Phase 2. Aplikasi Flutter tetap menggunakan `SUPABASE_ANON_KEY`; `service_role` tidak boleh dimasukkan ke aplikasi, `dart-define`, repository, ataupun artefak build.

## Isi

- `migrations/20260625020000_phase_2_schema.sql`: tabel, constraint, dan index.
- `migrations/20260625020100_phase_2_functions_and_triggers.sql`: helper, trigger, audit, dan RPC.
- `migrations/20260625020200_phase_2_rls_and_storage.sql`: view, private bucket, RLS, grants, dan Realtime publication.
- `tests/phase_2_policy_test.sql`: uji akses User A, User B, Helpdesk, Admin, attachment, histori, dan akun nonaktif.
- `config.toml`: konfigurasi lokal minimum untuk Supabase CLI.

## Menjalankan dari kondisi bersih

Prasyarat: Docker dan Supabase CLI.

```bash
supabase start
supabase db reset
supabase test db supabase/tests/phase_2_policy_test.sql
```

Alternatif dengan `psql`:

```bash
psql "$LOCAL_DB_URL" -v ON_ERROR_STOP=1 \
  -f supabase/tests/phase_2_policy_test.sql
```

Migration dibuat additive dan repeatable sejauh aman: `CREATE ... IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, serta policy/trigger yang di-drop lalu dibuat ulang. Ia tidak menghapus tabel, kolom, atau data.

## Production safety gate

Jangan menjalankan migration ini langsung pada production tanpa:

1. backup database dan inventaris schema saat ini;
2. dry run pada clone/staging;
3. pemeriksaan data yang melanggar role/status/attachment constraint;
4. review diff migration oleh minimal satu anggota lain;
5. rencana rollback yang disetujui.

Jika instalasi lama memiliki tipe kolom atau constraint berbeda, hentikan deployment. Jangan “menyelesaikan” konflik dengan `DROP`, `TRUNCATE`, atau rewrite data massal tanpa change request terpisah.

## Storage contract

Bucket `tickets` bersifat private. Path wajib:

```text
<ticket_uuid>/<uploader_uuid>/<safe_file_name>
```

Contoh:

```text
9ac.../2f1.../evidence-01.pdf
```

Batas file 10 MiB. MIME yang diizinkan: JPEG, PNG, WebP, PDF, TXT, DOC, dan DOCX. Nama file hanya boleh berisi huruf, angka, titik, garis bawah, dan tanda hubung; traversal seperti `..` ditolak. Tidak ada policy `UPDATE` pada `storage.objects`, sehingga overwrite/upsert sengaja ditolak.

## Role mapping

| Nilai DB | Istilah produk | Enum source |
|---:|---|---|
| 1 | Admin | `admin` |
| 2 | Helpdesk | `technician` |
| 3 | User | `user` |

Assignment bukan status. Tiket dianggap assigned ketika `assigned_to IS NOT NULL`.
