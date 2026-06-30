# Phase 4 Ticket Core Implementation Plan

## Tujuan Phase 4

Phase 4 membangun fondasi Ticket Core untuk pembuatan, daftar, detail, komentar, history, tracking, soft delete, dan isolasi cache per user tanpa memperluas workflow Phase 5.

## Requirement Acuan

- `FR-005`: pengguna terautentikasi dapat membuat tiket helpdesk.
- `FR-010`: aplikasi menampilkan detail tiket beserta komentar dan lampiran terkait.
- `FR-011`: aplikasi menampilkan history dan tracking perjalanan tiket.
- `BR-002 Ticket Service`: akses tiket, lampiran, komentar, history, dan delete mengikuti role caller serta backend authorization Supabase.

## Scope Phase 4

- Create ticket untuk `User`, `Helpdesk`, dan `Admin`
- Attachment abstraction dan validasi attachment
- Ticket list dengan query contract dan pagination contract
- Ticket detail read/display
- Comments read/create dan realtime display
- History read/display
- Tracking read/display
- Delete contract dan policy integration
- Cache isolation per authenticated user

## Acceptance Criteria

- Domain memiliki contract `TicketAttachment`, `LocalAttachmentCandidate`, `TicketQuery`, `PaginatedResult`, dan tracking representation.
- Create ticket dapat diakses oleh seluruh role authenticated tanpa memilih actor manual.
- Legacy `tickets.images` tetap kompatibel sambil menyiapkan representasi utama berbasis attachment metadata.
- Validasi attachment terpusat memeriksa jumlah, ukuran, MIME type, extension, zero-byte, missing path, empty filename, duplicate, dan mismatch MIME-extension.
- List, detail, comments, history, tracking, dan delete tidak mengandalkan client filtering sebagai authorization.
- Cache tiket dipisahkan per user dan dibersihkan saat logout.

## Checkpoint Plan

### Checkpoint 1

- Domain contracts
- Attachment abstraction
- Create access rules
- Validation

### Checkpoint 2

- Datasource `ticket_attachments`
- Document picker
- Storage upload contract
- Rollback dan compensation integration

### Checkpoint 3

- Query integration
- Pagination integration
- Realtime merge safety
- Detail data completeness

### Checkpoint 4

- Dedicated tracking page dan route
- Delete contract dan confirmation flow

### Checkpoint 5

- User-scoped cache
- Logout cleanup
- Subscription lifecycle hardening

### Checkpoint 6

- Phase 4 hardening
- Legacy cleanup yang aman

### Final Review

- Traceability ke requirement
- Full test pass
- Security and architecture review

## Explicit Out Of Scope

- Assignment
- Status workflow
- Close/reopen workflow
- Notifications
- Dashboard
- User management

## Backend Assumptions

- Supabase RLS tetap menjadi batas otorisasi utama.
- Storage attachment bersifat private.
- Metadata attachment disimpan pada `ticket_attachments`.
- History dan tracking membaca dari `ticket_history`.
- Delete mengikuti policy backend dan/atau RPC soft delete.

## Quality Gate

- `dart format .`
- `flutter analyze`
- `flutter test`
- `git diff --check`
