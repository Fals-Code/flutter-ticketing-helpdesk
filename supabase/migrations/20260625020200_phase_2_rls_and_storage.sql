-- TICKET-Q Phase 2: Supabase backend and security baseline.
--
-- Safety properties:
--   * additive/idempotent where PostgreSQL permits it;
--   * no DROP TABLE, DROP COLUMN, TRUNCATE, or destructive data rewrite;
--   * intended to run from a clean Supabase project;
--   * production execution requires backup and a reviewed dry run.

begin;

-- ---------------------------------------------------------------------------
-- 7. Security-invoker views
-- ---------------------------------------------------------------------------

create or replace view public.v_ticket_scope
with (security_invoker = true)
as
select
  t.*,
  (t.assigned_to is not null and t.status <> 'closed') as is_assigned
from public.tickets t
where t.deleted_at is null;

-- ---------------------------------------------------------------------------
-- 8. Private ticket attachment bucket
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'tickets',
  'tickets',
  false,
  10485760,
  array[
    'image/jpeg', 'image/png', 'image/webp',
    'application/pdf', 'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]::text[]
)
on conflict (id) do update
set name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 9. RLS policies
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.tickets enable row level security;
alter table public.comments enable row level security;
alter table public.ticket_history enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.app_settings enable row level security;
alter table public.ticket_attachments enable row level security;
alter table public.admin_audit_log enable row level security;

-- Profiles
drop policy if exists profiles_select_scope on public.profiles;
create policy profiles_select_scope on public.profiles
for select to authenticated
using (public.can_view_profile(id));

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
for insert to authenticated
with check (
  public.is_active_user()
  and id = (select auth.uid())
  and role = 3
  and is_active = true
);

drop policy if exists profiles_update_self_or_admin on public.profiles;
create policy profiles_update_self_or_admin on public.profiles
for update to authenticated
using (public.is_active_user() and (id = (select auth.uid()) or public.is_admin()))
with check (public.is_active_user() and (id = (select auth.uid()) or public.is_admin()));

-- Tickets
drop policy if exists tickets_select_scope on public.tickets;
create policy tickets_select_scope on public.tickets
for select to authenticated
using (public.can_access_ticket(id));

drop policy if exists tickets_insert_authenticated on public.tickets;
create policy tickets_insert_authenticated on public.tickets
for insert to authenticated
with check (
  public.is_active_user()
  and user_id = (select auth.uid())
  and assigned_to is null
  and status = 'open'
  and deleted_at is null
);

drop policy if exists tickets_update_scope on public.tickets;
create policy tickets_update_scope on public.tickets
for update to authenticated
using (
  public.is_active_user()
  and (
    public.is_admin()
    or (public.is_technician() and assigned_to = (select auth.uid()))
    or user_id = (select auth.uid())
  )
)
with check (
  public.is_active_user()
  and (
    public.is_admin()
    or (public.is_technician() and assigned_to = (select auth.uid()))
    or user_id = (select auth.uid())
  )
);

-- Comments
drop policy if exists comments_select_scope on public.comments;
create policy comments_select_scope on public.comments
for select to authenticated
using (deleted_at is null and public.can_access_ticket(ticket_id));

drop policy if exists comments_insert_scope on public.comments;
create policy comments_insert_scope on public.comments
for insert to authenticated
with check (
  public.is_active_user()
  and user_id = (select auth.uid())
  and public.can_access_ticket(ticket_id)
);

-- History is append-only through trusted triggers.
drop policy if exists ticket_history_select_scope on public.ticket_history;
create policy ticket_history_select_scope on public.ticket_history
for select to authenticated
using (public.can_access_ticket(ticket_id));

-- Notification privacy: even Admin sees only their own notification rows.
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
for select to authenticated
using (public.is_active_user() and user_id = (select auth.uid()));

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
for update to authenticated
using (public.is_active_user() and user_id = (select auth.uid()))
with check (public.is_active_user() and user_id = (select auth.uid()));

drop policy if exists notifications_delete_own on public.notifications;
create policy notifications_delete_own on public.notifications
for delete to authenticated
using (public.is_active_user() and user_id = (select auth.uid()));

-- Device tokens
drop policy if exists device_tokens_select_own on public.device_tokens;
create policy device_tokens_select_own on public.device_tokens
for select to authenticated
using (public.is_active_user() and user_id = (select auth.uid()));

drop policy if exists device_tokens_insert_own on public.device_tokens;
create policy device_tokens_insert_own on public.device_tokens
for insert to authenticated
with check (public.is_active_user() and user_id = (select auth.uid()));

drop policy if exists device_tokens_update_own on public.device_tokens;
create policy device_tokens_update_own on public.device_tokens
for update to authenticated
using (public.is_active_user() and user_id = (select auth.uid()))
with check (public.is_active_user() and user_id = (select auth.uid()));

drop policy if exists device_tokens_delete_own on public.device_tokens;
create policy device_tokens_delete_own on public.device_tokens
for delete to authenticated
using (public.is_active_user() and user_id = (select auth.uid()));

-- App settings
drop policy if exists app_settings_select_public_or_admin on public.app_settings;
create policy app_settings_select_public_or_admin on public.app_settings
for select to authenticated
using (public.is_active_user() and (is_public = true or public.is_admin()));

drop policy if exists app_settings_insert_admin on public.app_settings;
create policy app_settings_insert_admin on public.app_settings
for insert to authenticated
with check (public.is_admin());

drop policy if exists app_settings_update_admin on public.app_settings;
create policy app_settings_update_admin on public.app_settings
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Attachment metadata
drop policy if exists ticket_attachments_select_scope on public.ticket_attachments;
create policy ticket_attachments_select_scope on public.ticket_attachments
for select to authenticated
using (deleted_at is null and public.can_access_ticket(ticket_id));

drop policy if exists ticket_attachments_insert_scope on public.ticket_attachments;
create policy ticket_attachments_insert_scope on public.ticket_attachments
for insert to authenticated
with check (
  public.is_active_user()
  and uploaded_by = (select auth.uid())
  and public.can_access_ticket(ticket_id)
  and public.is_valid_attachment_object(
    storage_path,
    jsonb_build_object('mimetype', mime_type, 'size', size_bytes)
  )
);

-- Admin audit is separate from private notifications.
drop policy if exists admin_audit_select_admin on public.admin_audit_log;
create policy admin_audit_select_admin on public.admin_audit_log
for select to authenticated
using (public.is_admin());

-- Storage object policies.
drop policy if exists ticket_objects_select_scope on storage.objects;
create policy ticket_objects_select_scope on storage.objects
for select to authenticated
using (
  bucket_id = 'tickets'
  and public.can_access_ticket(public.attachment_ticket_id(name))
);

drop policy if exists ticket_objects_insert_scope on storage.objects;
create policy ticket_objects_insert_scope on storage.objects
for insert to authenticated
with check (
  bucket_id = 'tickets'
  and public.is_valid_attachment_object(name, metadata)
);

drop policy if exists ticket_objects_delete_scope on storage.objects;
create policy ticket_objects_delete_scope on storage.objects
for delete to authenticated
using (
  bucket_id = 'tickets'
  and public.is_active_user()
  and public.can_access_ticket(public.attachment_ticket_id(name))
  and (
    public.is_admin()
    or public.attachment_uploader_id(name) = (select auth.uid())
  )
);

-- No UPDATE policy is intentionally created for storage.objects. Uploads must
-- use unique names, not upsert/overwrite.

-- ---------------------------------------------------------------------------
-- 10. Grants
-- ---------------------------------------------------------------------------

revoke all on table public.profiles from anon;
revoke all on table public.tickets from anon;
revoke all on table public.comments from anon;
revoke all on table public.ticket_history from anon;
revoke all on table public.notifications from anon;
revoke all on table public.device_tokens from anon;
revoke all on table public.app_settings from anon;
revoke all on table public.ticket_attachments from anon;
revoke all on table public.admin_audit_log from anon;
revoke all on table public.v_ticket_scope from anon;

revoke delete on table public.profiles from authenticated;
revoke delete on table public.tickets from authenticated;
revoke update, delete on table public.comments from authenticated;
revoke insert, update, delete on table public.ticket_history from authenticated;
revoke insert on table public.notifications from authenticated;
revoke update, delete on table public.ticket_attachments from authenticated;
revoke insert, update, delete on table public.admin_audit_log from authenticated;

grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update on table public.tickets to authenticated;
grant select, insert on table public.comments to authenticated;
grant select on table public.ticket_history to authenticated;
grant select, update, delete on table public.notifications to authenticated;
grant select, insert, update, delete on table public.device_tokens to authenticated;
grant select, insert, update on table public.app_settings to authenticated;
grant select, insert on table public.ticket_attachments to authenticated;
grant select on table public.admin_audit_log to authenticated;
grant select on table public.v_ticket_scope to authenticated;

-- Lock down helper and RPC execution, then grant only the public contract.
revoke all on function public.current_profile_role() from public;
revoke all on function public.is_active_user() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.is_technician() from public;
revoke all on function public.can_access_ticket(uuid) from public;
revoke all on function public.can_manage_ticket(uuid) from public;
revoke all on function public.can_view_profile(uuid) from public;
revoke all on function public.is_valid_attachment_object(text, jsonb) from public;
revoke all on function public.assign_ticket(uuid, uuid, text) from public;
revoke all on function public.update_ticket_status(uuid, text, text) from public;
revoke all on function public.admin_override_ticket_status(uuid, text, text) from public;
revoke all on function public.soft_delete_ticket(uuid, text) from public;
revoke all on function public.restore_ticket(uuid, text) from public;
revoke all on function public.admin_update_user_role(uuid, smallint, text) from public;
revoke all on function public.admin_set_user_active(uuid, boolean, text) from public;
revoke all on function public.register_device_token(text, text, text) from public;
revoke all on function public.unregister_device_token(text) from public;
revoke all on function public.register_ticket_attachment(uuid, text, text, text, bigint) from public;
revoke all on function public.get_ticket_stats() from public;

grant execute on function public.current_profile_role() to authenticated;
grant execute on function public.is_active_user() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_technician() to authenticated;
grant execute on function public.can_access_ticket(uuid) to authenticated;
grant execute on function public.can_manage_ticket(uuid) to authenticated;
grant execute on function public.can_view_profile(uuid) to authenticated;
grant execute on function public.is_valid_attachment_object(text, jsonb) to authenticated;
grant execute on function public.assign_ticket(uuid, uuid, text) to authenticated;
grant execute on function public.update_ticket_status(uuid, text, text) to authenticated;
grant execute on function public.admin_override_ticket_status(uuid, text, text) to authenticated;
grant execute on function public.soft_delete_ticket(uuid, text) to authenticated;
grant execute on function public.restore_ticket(uuid, text) to authenticated;
grant execute on function public.admin_update_user_role(uuid, smallint, text) to authenticated;
grant execute on function public.admin_set_user_active(uuid, boolean, text) to authenticated;
grant execute on function public.register_device_token(text, text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;
grant execute on function public.register_ticket_attachment(uuid, text, text, text, bigint) to authenticated;
grant execute on function public.get_ticket_stats() to authenticated;

-- Realtime publication. Duplicate membership is ignored.
do $$
begin
  alter publication supabase_realtime add table public.tickets;
exception when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime add table public.comments;
exception when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null;
end
$$;

commit;
