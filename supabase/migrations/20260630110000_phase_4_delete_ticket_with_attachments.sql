begin;

create or replace function public.delete_ticket_with_attachments(
  p_ticket_id uuid,
  p_reason text
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_ticket public.tickets;
  v_storage_paths text[] := '{}';
  v_attachment_count integer := 0;
  v_deleted_storage_count integer := 0;
begin
  select public.soft_delete_ticket(p_ticket_id, p_reason)
  into v_ticket;

  select
    coalesce(array_agg(storage_path order by created_at), '{}'),
    count(*)
  into v_storage_paths, v_attachment_count
  from public.ticket_attachments
  where ticket_id = p_ticket_id
    and deleted_at is null;

  if v_attachment_count > 0 then
    delete from storage.objects
    where bucket_id = 'tickets'
      and name = any(v_storage_paths);

    get diagnostics v_deleted_storage_count = row_count;

    if v_deleted_storage_count <> v_attachment_count then
      raise exception using
        errcode = 'P0001',
        message = 'ticket attachment cleanup incomplete';
    end if;

    update public.ticket_attachments
    set deleted_at = now(),
        deleted_by = auth.uid()
    where ticket_id = p_ticket_id
      and deleted_at is null;
  end if;

  return v_ticket;
end
$$;

revoke all on function public.delete_ticket_with_attachments(uuid, text) from public;
grant execute on function public.delete_ticket_with_attachments(uuid, text) to authenticated;

commit;
