-- TICKET-Q Phase 4: atomic ticket creation with attachment metadata.
--
-- This migration keeps the private `tickets` bucket model. New ticket uploads
-- are allowed only for an active authenticated user under the existing backend
-- path contract:
--
--   <ticket_uuid>/<uploader_uuid>/<safe_file_name>
--
-- The database transaction below creates the ticket and all attachment metadata
-- after storage uploads complete. If it fails, the client must remove uploaded
-- objects as compensation.

begin;

create or replace function public.is_valid_pending_ticket_attachment_object(
  p_name text,
  p_metadata jsonb
)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select public.is_active_user()
    and p_name ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9][A-Za-z0-9._-]{0,119}$'
    and position('..' in p_name) = 0
    and public.attachment_uploader_id(p_name) = (select auth.uid())
    and public.attachment_ticket_id(p_name) is not null
    and not exists (
      select 1
      from public.tickets t
      where t.id = public.attachment_ticket_id(p_name)
    )
    and lower(coalesce(p_metadata ->> 'mimetype', '')) in (
      'image/jpeg', 'image/png', 'image/webp',
      'application/pdf', 'text/plain',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    )
    and case
      when coalesce(p_metadata ->> 'size', '') ~ '^[0-9]+$'
        then (p_metadata ->> 'size')::bigint between 1 and 10485760
      else false
    end
$$;

drop policy if exists ticket_objects_insert_pending_ticket_create on storage.objects;
create policy ticket_objects_insert_pending_ticket_create on storage.objects
for insert to authenticated
with check (
  bucket_id = 'tickets'
  and public.is_valid_pending_ticket_attachment_object(name, metadata)
);

drop policy if exists ticket_objects_delete_unregistered_own_upload on storage.objects;
create policy ticket_objects_delete_unregistered_own_upload on storage.objects
for delete to authenticated
using (
  bucket_id = 'tickets'
  and public.is_active_user()
  and public.attachment_uploader_id(name) = (select auth.uid())
  and not exists (
    select 1
    from public.ticket_attachments ta
    where ta.storage_path = name
      and ta.deleted_at is null
  )
);

create or replace function public.create_ticket_with_attachments(
  p_ticket_id uuid,
  p_title text,
  p_description text,
  p_category text,
  p_attachments jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_attachment jsonb;
  v_storage_path text;
  v_file_name text;
  v_mime_type text;
  v_size_bytes bigint;
begin
  if v_actor is null then
    raise exception using errcode = '42501', message = 'authenticated user required';
  end if;

  if not public.is_active_user() then
    raise exception using errcode = '42501', message = 'active authenticated user required';
  end if;

  if p_ticket_id is null then
    raise exception using errcode = '22023', message = 'ticket id is required';
  end if;

  if p_attachments is null or jsonb_typeof(p_attachments) <> 'array' then
    raise exception using errcode = '22023', message = 'attachments must be an array';
  end if;

  insert into public.tickets (
    id,
    title,
    description,
    category,
    status,
    user_id,
    assigned_to,
    images
  ) values (
    p_ticket_id,
    btrim(p_title),
    btrim(p_description),
    btrim(p_category),
    'open',
    v_actor,
    null,
    '{}'::text[]
  );

  for v_attachment in
    select value from jsonb_array_elements(p_attachments)
  loop
    v_storage_path := nullif(btrim(v_attachment ->> 'storage_path'), '');
    v_file_name := nullif(btrim(v_attachment ->> 'file_name'), '');
    v_mime_type := lower(nullif(btrim(v_attachment ->> 'mime_type'), ''));
    v_size_bytes := nullif(v_attachment ->> 'size_bytes', '')::bigint;

    if v_storage_path is null
       or v_file_name is null
       or v_mime_type is null
       or v_size_bytes is null then
      raise exception using errcode = '22023', message = 'attachment manifest is incomplete';
    end if;

    if public.attachment_ticket_id(v_storage_path) is distinct from p_ticket_id
       or public.attachment_uploader_id(v_storage_path) is distinct from v_actor then
      raise exception using errcode = '22023', message = 'attachment path does not match ticket and actor';
    end if;

    insert into public.ticket_attachments (
      ticket_id,
      storage_path,
      file_name,
      mime_type,
      size_bytes,
      uploaded_by
    ) values (
      p_ticket_id,
      v_storage_path,
      v_file_name,
      v_mime_type,
      v_size_bytes,
      v_actor
    );
  end loop;

  return p_ticket_id;
end
$$;

revoke all on function public.is_valid_pending_ticket_attachment_object(text, jsonb) from public;
revoke all on function public.create_ticket_with_attachments(uuid, text, text, text, jsonb) from public;

grant execute on function public.is_valid_pending_ticket_attachment_object(text, jsonb) to authenticated;
grant execute on function public.create_ticket_with_attachments(uuid, text, text, text, jsonb) to authenticated;

commit;
