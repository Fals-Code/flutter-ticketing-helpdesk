begin;

drop function if exists public.delete_ticket_with_attachments(uuid, text);

create or replace function public.can_delete_ticket_attachment_object(
  p_name text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and public.is_active_user()
    and exists (
      select 1
      from public.ticket_attachments ta
      join public.tickets t on t.id = ta.ticket_id
      where ta.storage_path = p_name
        and (
          public.is_admin()
          or t.deleted_by = auth.uid()
        )
    )
$$;

revoke all on function public.can_delete_ticket_attachment_object(text)
  from public;
grant execute on function public.can_delete_ticket_attachment_object(text)
  to authenticated;

create or replace function public.is_valid_pending_ticket_attachment_object(
  p_name text,
  p_metadata jsonb
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_user()
    and p_name ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9][A-Za-z0-9._-]{0,119}$'
    and position('..' in p_name) = 0
    and public.attachment_uploader_id(p_name) = auth.uid()
    and public.attachment_ticket_id(p_name) is not null
    and not exists (
      select 1
      from public.tickets t
      where t.id = public.attachment_ticket_id(p_name)
    )
    and (
      lower(coalesce(p_metadata ->> 'mimetype', '')) in (
        'image/jpeg', 'image/png', 'image/webp',
        'application/pdf', 'text/plain',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      )
      or lower(split_part(p_name, '.', array_length(string_to_array(p_name, '.'), 1))) in (
        'jpg', 'jpeg', 'png', 'webp', 'pdf', 'txt', 'doc', 'docx'
      )
    )
    and case
      when coalesce(p_metadata ->> 'size', '') ~ '^[0-9]+$'
        then (p_metadata ->> 'size')::bigint between 1 and 10485760
      else true
    end
$$;

revoke all on function public.is_valid_pending_ticket_attachment_object(text, jsonb)
  from public;
grant execute on function public.is_valid_pending_ticket_attachment_object(text, jsonb)
  to authenticated;

drop policy if exists ticket_objects_delete_scope on storage.objects;
create policy ticket_objects_delete_scope on storage.objects
for delete to authenticated
using (
  bucket_id = 'tickets'
  and public.can_delete_ticket_attachment_object(name)
);

create or replace function public.delete_ticket_with_attachments(
  p_ticket_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets;
  v_storage_paths text[] := array[]::text[];
begin
  select coalesce(array_agg(ta.storage_path order by ta.created_at), array[]::text[])
  into v_storage_paths
  from public.ticket_attachments ta
  where ta.ticket_id = p_ticket_id
    and ta.deleted_at is null;

  update public.ticket_attachments ta
  set deleted_at = now(),
      deleted_by = auth.uid()
  where ta.ticket_id = p_ticket_id
    and ta.deleted_at is null;

  select *
  into v_ticket
  from public.soft_delete_ticket(p_ticket_id, p_reason);

  return jsonb_build_object(
    'deleted', true,
    'ticket_id', v_ticket.id,
    'attachment_paths', to_jsonb(v_storage_paths),
    'cleanup_status', case
      when coalesce(array_length(v_storage_paths, 1), 0) = 0
        then 'deletedAndCleaned'
      else 'deletedWithCleanupPending'
    end
  );
end
$$;

revoke all on function public.delete_ticket_with_attachments(uuid, text)
  from public;
grant execute on function public.delete_ticket_with_attachments(uuid, text)
  to authenticated;

commit;
