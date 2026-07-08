# send-ticket-notification

Supabase Edge Function ini mengirim push notification FCM saat ada row baru pada tabel `public.notifications`.

Kenapa perlu function ini? Supabase Realtime hanya bekerja saat aplikasi sedang aktif atau masih punya proses yang hidup. Saat aplikasi background/terminated, perangkat hanya bisa menerima push kalau backend benar-benar mengirim pesan ke Firebase Cloud Messaging. Ya, manusia berharap notifikasi muncul dari udara tipis, padahal tetap harus ada server yang menendang FCM.

## Secret yang wajib diset

Jalankan dari root project setelah login Supabase CLI dan memilih project production yang benar.

```powershell
supabase secrets set `
  FIREBASE_PROJECT_ID="<firebase-project-id>" `
  FIREBASE_CLIENT_EMAIL="<service-account-client-email>" `
  FIREBASE_PRIVATE_KEY_BASE64="<base64-private-key-pem>" `
  WEBHOOK_SECRET="<random-long-secret>"
```

Gunakan `FIREBASE_PRIVATE_KEY_BASE64` agar newline private key tidak rusak di shell Windows.

Contoh membuat base64 private key dari file service account di PowerShell:

```powershell
$serviceAccount = Get-Content .\firebase-service-account.json | ConvertFrom-Json
$privateKeyBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($serviceAccount.private_key))
$privateKeyBase64
```

Jangan commit file service account. Jangan juga kirim ke grup kelas. Peradaban sudah cukup kacau tanpa private key bocor.

## Deploy function

```powershell
supabase functions deploy send-ticket-notification --no-verify-jwt
```

`verify_jwt = false` juga sudah dicatat di `supabase/config.toml`, karena Database Webhook tidak membawa JWT user aplikasi. Keamanan webhook dijaga oleh header `x-ticketq-webhook-secret`.

## Hubungkan Database Webhook

Di Supabase Dashboard:

1. Database -> Webhooks -> Create a new hook.
2. Table: `public.notifications`.
3. Events: `Insert`.
4. Type: HTTP Request.
5. Method: `POST`.
6. URL: `https://<project-ref>.functions.supabase.co/send-ticket-notification`.
7. Headers:
   - `content-type: application/json`
   - `x-ticketq-webhook-secret: <WEBHOOK_SECRET yang sama>`
8. Simpan dan uji dengan membuat komentar/status/assignment tiket.

## Payload yang didukung

Function menerima payload database webhook seperti:

```json
{
  "type": "INSERT",
  "table": "notifications",
  "record": {
    "id": "notification-id",
    "user_id": "target-user-id",
    "title": "Status tiket diperbarui",
    "message": "Status tiket berubah menjadi in_progress.",
    "ticket_id": "ticket-id",
    "notification_type": "status_changed",
    "payload": {}
  }
}
```

Payload FCM dikirim dengan dua gaya key agar kompatibel dengan app Flutter lama dan baru:

```text
notificationId / notification_id
ticketId / ticket_id
type
route
title
body
payload
```

## Smoke test server-side

Setelah deploy dan webhook aktif, buat notifikasi manual ke user yang sudah login minimal sekali di aplikasi agar `device_tokens` terisi.

```sql
insert into public.notifications (user_id, title, message, ticket_id, notification_type)
values (
  '<target-user-id>',
  'Tes Push TICKET-Q',
  'Jika ini muncul saat aplikasi ditutup, FCM sudah hidup.',
  '<ticket-id>',
  'manual_test'
);
```

Target sukses:

- row masuk ke `notifications`;
- Edge Function log menunjukkan `delivered >= 1`;
- notifikasi muncul saat aplikasi berada di background/terminated;
- tap notifikasi membuka detail tiket terkait.
