-- TICKET-Q Phase 2: Supabase backend and security baseline.
--
-- Safety properties:
--   * additive/idempotent where PostgreSQL permits it;
--   * no DROP TABLE, DROP COLUMN, TRUNCATE, or destructive data rewrite;
--   * intended to run from a clean Supabase project;
--   * production execution requires backup and a reviewed dry run.

begin;

-- ---------------------------------------------------------------------------
-- 4. Security helper functions
-- ---------------------------------------------------------------------------

create or replace function public.current_profile_role()
returns smallint
language sql
stable
security definer
set search_path = public, auth
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid())
    and p.is_active = true
  limit 1
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active = true
  )
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(public.current_profile_role() = 1, false)
$$;

create or replace function public.is_technician()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(public.current_profile_role() = 2, false)
$$;

create or replace function public.can_access_ticket(p_ticket_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select public.is_active_user()
    and exists (
      select 1
      from public.tickets t
      where t.id = p_ticket_id
        and (
          public.is_admin()
          or (
            t.deleted_at is null
            and (
              t.user_id = (select auth.uid())
              or (public.is_technician() and t.assigned_to = (select auth.uid()))
            )
          )
        )
    )
$$;

create or replace function public.can_manage_ticket(p_ticket_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select public.is_active_user()
    and exists (
      select 1
      from public.tickets t
      where t.id = p_ticket_id
        and t.deleted_at is null
        and (
          public.is_admin()
          or (public.is_technician() and t.assigned_to = (select auth.uid()))
        )
    )
$$;

create or replace function public.can_view_profile(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select public.is_active_user()
    and (
      p_profile_id = (select auth.uid())
      or public.is_admin()
      or exists (
        select 1
        from public.tickets t
        where public.can_access_ticket(t.id)
          and (t.user_id = p_profile_id or t.assigned_to = p_profile_id)
      )
    )
$$;

create or replace function public.ticket_status_transition_allowed(p_old text, p_new text)
returns boolean
language sql
immutable
as $$
  select case p_old
    when 'open' then p_new in ('in_progress', 'pending', 'closed')
    when 'pending' then p_new in ('in_progress', 'resolved', 'closed')
    when 'in_progress' then p_new in ('resolved', 'pending', 'closed')
    when 'resolved' then p_new in ('closed', 'reopened')
    when 'reopened' then p_new in ('in_progress', 'pending', 'resolved')
    when 'closed' then p_new = 'reopened'
    else false
  end
$$;

create or replace function public.attachment_ticket_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = public
as $$
declare
  v_segment text;
begin
  v_segment := split_part(p_name, '/', 1);
  if v_segment !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return null;
  end if;
  return v_segment::uuid;
exception when others then
  return null;
end
$$;

create or replace function public.attachment_uploader_id(p_name text)
returns uuid
language plpgsql
immutable
set search_path = public
as $$
declare
  v_segment text;
begin
  v_segment := split_part(p_name, '/', 2);
  if v_segment !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    return null;
  end if;
  return v_segment::uuid;
exception when others then
  return null;
end
$$;

create or replace function public.is_valid_attachment_object(p_name text, p_metadata jsonb)
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
    and public.can_access_ticket(public.attachment_ticket_id(p_name))
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

-- ---------------------------------------------------------------------------
-- 5. Generic and domain triggers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (id, email, full_name, role, is_active)
  values (
    new.id,
    new.email,
    left(coalesce(new.raw_user_meta_data ->> 'full_name', ''), 150),
    3,
    true
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = case
          when public.profiles.full_name = '' then excluded.full_name
          else public.profiles.full_name
        end,
        updated_at = now();
  return new;
end
$$;

create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  update public.profiles
  set email = new.email,
      updated_at = now()
  where id = new.id;
  return new;
end
$$;

create or replace function public.protect_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_operation text := current_setting('ticketq.operation', true);
begin
  if auth.uid() is null then
    return new;
  end if;

  if new.id is distinct from old.id or new.created_at is distinct from old.created_at then
    raise exception using errcode = '42501', message = 'immutable profile fields cannot be changed';
  end if;

  if not public.is_admin() then
    if new.role is distinct from old.role
       or new.is_active is distinct from old.is_active
       or new.email is distinct from old.email then
      raise exception using errcode = '42501', message = 'role, activation, and email are protected fields';
    end if;
  elsif (new.role is distinct from old.role or new.is_active is distinct from old.is_active)
        and coalesce(v_operation, '') <> 'profile_admin' then
    raise exception using errcode = '42501', message = 'use an Admin profile management RPC';
  end if;

  new.updated_at := now();
  return new;
end
$$;

create or replace function public.validate_ticket_write()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_role smallint := public.current_profile_role();
  v_operation text := current_setting('ticketq.operation', true);
  v_target_role smallint;
  v_target_active boolean;
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      if not public.is_active_user() then
        raise exception using errcode = '42501', message = 'inactive users cannot create tickets';
      end if;
      if new.user_id is distinct from auth.uid() then
        raise exception using errcode = '42501', message = 'tickets can only be created for the authenticated user';
      end if;
      if new.assigned_to is not null then
        raise exception using errcode = '42501', message = 'ticket assignment is Admin-only';
      end if;
      new.status := 'open';
    end if;
  else
    if new.id is distinct from old.id
       or new.user_id is distinct from old.user_id
       or new.created_at is distinct from old.created_at then
      raise exception using errcode = '42501', message = 'ticket ownership and identity are immutable';
    end if;

    if auth.uid() is not null and not public.is_active_user() then
      raise exception using errcode = '42501', message = 'inactive users cannot update tickets';
    end if;

    if new.assigned_to is distinct from old.assigned_to then
      if coalesce(v_role, 0) <> 1 or coalesce(v_operation, '') not in ('assign', 'admin_override') then
        raise exception using errcode = '42501', message = 'assignment is Admin-only; use assign_ticket';
      end if;
    end if;

    if new.deleted_at is distinct from old.deleted_at then
      if coalesce(v_operation, '') not in ('soft_delete', 'restore') then
        raise exception using errcode = '42501', message = 'use the ticket soft-delete RPC';
      end if;
    end if;

    if new.status is distinct from old.status then
      if v_role = 2 and old.assigned_to is distinct from auth.uid() then
        raise exception using errcode = '42501', message = 'Helpdesk may only update assigned tickets';
      elsif v_role = 3 then
        raise exception using errcode = '42501', message = 'User may not change ticket status';
      end if;

      if not public.ticket_status_transition_allowed(old.status, new.status)
         and not (v_role = 1 and coalesce(v_operation, '') = 'admin_override') then
        raise exception using errcode = '23514', message = 'illegal ticket status transition';
      end if;
    end if;

    if v_role = 2 then
      if old.assigned_to is distinct from auth.uid() then
        raise exception using errcode = '42501', message = 'Helpdesk may only update assigned tickets';
      end if;
      if new.title is distinct from old.title
         or new.description is distinct from old.description
         or new.category is distinct from old.category
         or new.images is distinct from old.images
         or new.rating is distinct from old.rating
         or new.rating_feedback is distinct from old.rating_feedback then
        raise exception using errcode = '42501', message = 'Helpdesk may only update workflow fields';
      end if;
    elsif v_role = 3 then
      if old.user_id is distinct from auth.uid() then
        raise exception using errcode = '42501', message = 'Users may only update their own tickets';
      end if;
      if old.assigned_to is not null
         and (
           new.title is distinct from old.title
           or new.description is distinct from old.description
           or new.category is distinct from old.category
           or new.images is distinct from old.images
         ) then
        raise exception using errcode = '42501', message = 'assigned tickets can no longer be edited by the reporter';
      end if;
      if (new.rating is distinct from old.rating or new.rating_feedback is distinct from old.rating_feedback)
         and old.status not in ('resolved', 'closed') then
        raise exception using errcode = '23514', message = 'rating is only allowed after resolution';
      end if;
    end if;
  end if;

  if new.assigned_to is not null then
    select p.role, p.is_active
    into v_target_role, v_target_active
    from public.profiles p
    where p.id = new.assigned_to;

    if v_target_role is distinct from 2 or v_target_active is distinct from true then
      raise exception using errcode = '23514', message = 'assigned_to must reference an active Helpdesk account';
    end if;
  end if;

  new.updated_at := now();
  return new;
end
$$;

create or replace function public.log_ticket_activity()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_actor_role smallint;
  v_operation text := current_setting('ticketq.operation', true);
  v_reason text := nullif(current_setting('ticketq.reason', true), '');
begin
  select p.role into v_actor_role from public.profiles p where p.id = v_actor;

  if tg_op = 'INSERT' then
    insert into public.ticket_history (
      ticket_id, event_type, old_status, new_status, changed_by, actor_role, reason, metadata
    ) values (
      new.id, 'ticket_created', null, new.status, v_actor, v_actor_role, v_reason,
      jsonb_build_object('assigned_to', new.assigned_to)
    );
    return new;
  end if;

  if new.status is distinct from old.status then
    insert into public.ticket_history (
      ticket_id, event_type, old_status, new_status, changed_by, actor_role, reason, metadata
    ) values (
      new.id,
      case when v_operation = 'admin_override' then 'admin_override' else 'status_changed' end,
      old.status, new.status, v_actor, v_actor_role, v_reason,
      jsonb_build_object('assigned_to', new.assigned_to)
    );

    insert into public.notifications (user_id, title, message, ticket_id, notification_type, payload)
    select recipient_id,
           'Status tiket diperbarui',
           format('Status tiket "%s" berubah menjadi %s.', new.title, new.status),
           new.id,
           'status_changed',
           jsonb_build_object('old_status', old.status, 'new_status', new.status)
    from (
      select new.user_id as recipient_id
      union
      select new.assigned_to where new.assigned_to is not null
    ) recipients
    where recipient_id is distinct from v_actor;
  end if;

  if new.assigned_to is distinct from old.assigned_to then
    insert into public.ticket_history (
      ticket_id, event_type, old_status, new_status, changed_by, actor_role, reason, metadata
    ) values (
      new.id,
      case when new.assigned_to is null then 'unassigned' else 'assigned' end,
      old.status, new.status, v_actor, v_actor_role, v_reason,
      jsonb_build_object('old_assigned_to', old.assigned_to, 'new_assigned_to', new.assigned_to)
    );

    if new.assigned_to is not null then
      insert into public.notifications (user_id, title, message, ticket_id, notification_type, payload)
      values (
        new.assigned_to,
        'Tiket baru ditugaskan',
        format('Tiket "%s" ditugaskan kepada Anda.', new.title),
        new.id,
        'ticket_assigned',
        jsonb_build_object('assigned_by', v_actor)
      );
    end if;
  end if;

  if new.deleted_at is distinct from old.deleted_at then
    insert into public.ticket_history (
      ticket_id, event_type, old_status, new_status, changed_by, actor_role, reason, metadata
    ) values (
      new.id,
      case when new.deleted_at is null then 'ticket_restored' else 'ticket_deleted' end,
      old.status, new.status, v_actor, v_actor_role, v_reason,
      jsonb_build_object('deleted_at', new.deleted_at)
    );
  end if;

  return new;
end
$$;

create or replace function public.log_comment_activity()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor_role smallint;
begin
  select p.role into v_actor_role from public.profiles p where p.id = new.user_id;
  insert into public.ticket_history (
    ticket_id, event_type, changed_by, actor_role, metadata
  ) values (
    new.ticket_id, 'comment_added', new.user_id, v_actor_role,
    jsonb_build_object('comment_id', new.id)
  );
  return new;
end
$$;

create or replace function public.validate_attachment_record()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is not null then
    if new.uploaded_by is distinct from auth.uid() then
      raise exception using errcode = '42501', message = 'uploaded_by must match the authenticated user';
    end if;
    if not public.is_valid_attachment_object(
      new.storage_path,
      jsonb_build_object('mimetype', new.mime_type, 'size', new.size_bytes)
    ) then
      raise exception using errcode = '23514', message = 'invalid attachment metadata or storage path';
    end if;
  end if;
  return new;
end
$$;

create or replace function public.log_attachment_activity()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid;
  v_actor_role smallint;
begin
  if tg_op = 'INSERT' then
    v_actor := coalesce(auth.uid(), new.uploaded_by);
  else
    v_actor := coalesce(auth.uid(), new.uploaded_by, old.uploaded_by);
  end if;
  select p.role into v_actor_role from public.profiles p where p.id = v_actor;
  if tg_op = 'INSERT' then
    insert into public.ticket_history (
      ticket_id, event_type, changed_by, actor_role, metadata
    ) values (
      new.ticket_id, 'attachment_uploaded', v_actor, v_actor_role,
      jsonb_build_object('attachment_id', new.id, 'file_name', new.file_name)
    );
    return new;
  end if;

  if new.deleted_at is distinct from old.deleted_at and new.deleted_at is not null then
    insert into public.ticket_history (
      ticket_id, event_type, changed_by, actor_role, metadata
    ) values (
      new.ticket_id, 'attachment_deleted', v_actor, v_actor_role,
      jsonb_build_object('attachment_id', new.id, 'file_name', new.file_name)
    );
  end if;
  return new;
end
$$;

create or replace function public.log_profile_admin_change()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_reason text := nullif(current_setting('ticketq.reason', true), '');
begin
  if new.role is distinct from old.role then
    insert into public.admin_audit_log (
      event_type, actor_id, target_user_id, reason, old_value, new_value
    ) values (
      'role_changed', auth.uid(), new.id, v_reason,
      jsonb_build_object('role', old.role), jsonb_build_object('role', new.role)
    );
  end if;

  if new.is_active is distinct from old.is_active then
    insert into public.admin_audit_log (
      event_type, actor_id, target_user_id, reason, old_value, new_value
    ) values (
      case when new.is_active then 'user_reactivated' else 'user_deactivated' end,
      auth.uid(), new.id, v_reason,
      jsonb_build_object('is_active', old.is_active),
      jsonb_build_object('is_active', new.is_active)
    );
  end if;
  return new;
end
$$;

create or replace function public.prepare_notification_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.user_id is distinct from old.user_id
     or new.title is distinct from old.title
     or new.message is distinct from old.message
     or new.ticket_id is distinct from old.ticket_id
     or new.notification_type is distinct from old.notification_type
     or new.payload is distinct from old.payload
     or new.created_at is distinct from old.created_at then
    raise exception using errcode = '42501', message = 'only notification read state may be changed';
  end if;

  if new.is_read = true and old.is_read = false then
    new.read_at := now();
  elsif new.is_read = false then
    new.read_at := null;
  end if;
  return new;
end
$$;

create or replace function public.prepare_app_setting_write()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  new.updated_by := auth.uid();
  new.updated_at := now();
  return new;
end
$$;

-- Trigger creation is repeatable.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
after update of email on auth.users
for each row when (old.email is distinct from new.email)
execute function public.sync_profile_email();

drop trigger if exists profiles_protect_privileged_fields on public.profiles;
create trigger profiles_protect_privileged_fields
before update on public.profiles
for each row execute function public.protect_profile_privileged_fields();

drop trigger if exists profiles_admin_audit on public.profiles;
create trigger profiles_admin_audit
after update of role, is_active on public.profiles
for each row execute function public.log_profile_admin_change();

drop trigger if exists tickets_validate_write on public.tickets;
create trigger tickets_validate_write
before insert or update on public.tickets
for each row execute function public.validate_ticket_write();

drop trigger if exists tickets_audit_activity on public.tickets;
create trigger tickets_audit_activity
after insert or update on public.tickets
for each row execute function public.log_ticket_activity();

drop trigger if exists comments_set_updated_at on public.comments;
create trigger comments_set_updated_at
before update on public.comments
for each row execute function public.set_updated_at();

drop trigger if exists comments_audit_activity on public.comments;
create trigger comments_audit_activity
after insert on public.comments
for each row execute function public.log_comment_activity();

drop trigger if exists device_tokens_set_updated_at on public.device_tokens;
create trigger device_tokens_set_updated_at
before update on public.device_tokens
for each row execute function public.set_updated_at();

drop trigger if exists app_settings_prepare_write on public.app_settings;
create trigger app_settings_prepare_write
before insert or update on public.app_settings
for each row execute function public.prepare_app_setting_write();

drop trigger if exists ticket_attachments_validate on public.ticket_attachments;
create trigger ticket_attachments_validate
before insert or update on public.ticket_attachments
for each row execute function public.validate_attachment_record();

drop trigger if exists ticket_attachments_audit on public.ticket_attachments;
create trigger ticket_attachments_audit
after insert or update on public.ticket_attachments
for each row execute function public.log_attachment_activity();

drop trigger if exists notifications_prepare_update on public.notifications;
create trigger notifications_prepare_update
before update on public.notifications
for each row execute function public.prepare_notification_update();

-- ---------------------------------------------------------------------------
-- 6. Controlled RPCs
-- ---------------------------------------------------------------------------

create or replace function public.assign_ticket(
  p_ticket_id uuid,
  p_technician_id uuid,
  p_reason text default null
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ticket public.tickets;
  v_technician public.profiles;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;

  select * into v_ticket from public.tickets where id = p_ticket_id for update;
  if not found or v_ticket.deleted_at is not null then
    raise exception using errcode = 'P0002', message = 'ticket not found';
  end if;
  if v_ticket.status = 'closed' then
    raise exception using errcode = '23514', message = 'closed tickets cannot be assigned';
  end if;

  select * into v_technician
  from public.profiles
  where id = p_technician_id and role = 2 and is_active = true;
  if not found then
    raise exception using errcode = '23514', message = 'target must be an active Helpdesk account';
  end if;

  perform set_config('ticketq.operation', 'assign', true);
  perform set_config('ticketq.reason', coalesce(left(btrim(p_reason), 500), ''), true);

  update public.tickets
  set assigned_to = p_technician_id
  where id = p_ticket_id
  returning * into v_ticket;

  return v_ticket;
end
$$;

create or replace function public.update_ticket_status(
  p_ticket_id uuid,
  p_new_status text,
  p_reason text default null
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ticket public.tickets;
begin
  if p_new_status not in ('open', 'pending', 'in_progress', 'resolved', 'closed', 'reopened') then
    raise exception using errcode = '22023', message = 'unsupported ticket status';
  end if;
  if not public.can_manage_ticket(p_ticket_id) then
    raise exception using errcode = '42501', message = 'ticket is not assigned to this Helpdesk account';
  end if;

  perform set_config('ticketq.operation', 'status_update', true);
  perform set_config('ticketq.reason', coalesce(left(btrim(p_reason), 500), ''), true);

  update public.tickets
  set status = p_new_status
  where id = p_ticket_id
    and deleted_at is null
  returning * into v_ticket;

  if not found then
    raise exception using errcode = 'P0002', message = 'ticket not found';
  end if;
  return v_ticket;
end
$$;

create or replace function public.admin_override_ticket_status(
  p_ticket_id uuid,
  p_new_status text,
  p_reason text
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ticket public.tickets;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_new_status not in ('open', 'pending', 'in_progress', 'resolved', 'closed', 'reopened') then
    raise exception using errcode = '22023', message = 'unsupported ticket status';
  end if;
  if p_reason is null or char_length(btrim(p_reason)) < 5 then
    raise exception using errcode = '22023', message = 'an override reason of at least 5 characters is required';
  end if;

  perform set_config('ticketq.operation', 'admin_override', true);
  perform set_config('ticketq.reason', left(btrim(p_reason), 500), true);

  update public.tickets
  set status = p_new_status
  where id = p_ticket_id
    and deleted_at is null
  returning * into v_ticket;

  if not found then
    raise exception using errcode = 'P0002', message = 'ticket not found';
  end if;
  return v_ticket;
end
$$;

create or replace function public.soft_delete_ticket(
  p_ticket_id uuid,
  p_reason text
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ticket public.tickets;
  v_role smallint := public.current_profile_role();
begin
  if p_reason is null or char_length(btrim(p_reason)) < 3 then
    raise exception using errcode = '22023', message = 'delete reason is required';
  end if;

  select * into v_ticket from public.tickets where id = p_ticket_id for update;
  if not found or v_ticket.deleted_at is not null then
    raise exception using errcode = 'P0002', message = 'ticket not found';
  end if;

  if v_role = 1 then
    null;
  elsif v_role = 3
        and v_ticket.user_id = auth.uid()
        and v_ticket.status = 'open'
        and v_ticket.assigned_to is null then
    null;
  else
    raise exception using errcode = '42501', message = 'ticket cannot be deleted by this account';
  end if;

  perform set_config('ticketq.operation', 'soft_delete', true);
  perform set_config('ticketq.reason', left(btrim(p_reason), 500), true);

  update public.tickets
  set deleted_at = now(), deleted_by = auth.uid(), delete_reason = left(btrim(p_reason), 500)
  where id = p_ticket_id
  returning * into v_ticket;
  return v_ticket;
end
$$;

create or replace function public.restore_ticket(
  p_ticket_id uuid,
  p_reason text
)
returns public.tickets
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_ticket public.tickets;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_reason is null or char_length(btrim(p_reason)) < 3 then
    raise exception using errcode = '22023', message = 'restore reason is required';
  end if;

  perform set_config('ticketq.operation', 'restore', true);
  perform set_config('ticketq.reason', left(btrim(p_reason), 500), true);

  update public.tickets
  set deleted_at = null, deleted_by = null, delete_reason = null
  where id = p_ticket_id and deleted_at is not null
  returning * into v_ticket;

  if not found then
    raise exception using errcode = 'P0002', message = 'deleted ticket not found';
  end if;
  return v_ticket;
end
$$;

create or replace function public.admin_update_user_role(
  p_user_id uuid,
  p_new_role smallint,
  p_reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile public.profiles;
  v_current_role smallint;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_new_role not in (1, 2, 3) then
    raise exception using errcode = '22023', message = 'unsupported role';
  end if;
  if p_user_id = auth.uid() then
    raise exception using errcode = '42501', message = 'Admin cannot change their own role';
  end if;
  if p_reason is null or char_length(btrim(p_reason)) < 5 then
    raise exception using errcode = '22023', message = 'role change reason is required';
  end if;

  select role into v_current_role from public.profiles where id = p_user_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'profile not found';
  end if;

  if v_current_role = 1 and p_new_role <> 1
     and (select count(*) from public.profiles where role = 1 and is_active = true) <= 1 then
    raise exception using errcode = '23514', message = 'at least one active Admin must remain';
  end if;

  perform set_config('ticketq.operation', 'profile_admin', true);
  perform set_config('ticketq.reason', left(btrim(p_reason), 500), true);

  update public.profiles set role = p_new_role where id = p_user_id returning * into v_profile;
  return v_profile;
end
$$;

create or replace function public.admin_set_user_active(
  p_user_id uuid,
  p_is_active boolean,
  p_reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_profile public.profiles;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_user_id = auth.uid() and p_is_active = false then
    raise exception using errcode = '42501', message = 'Admin cannot deactivate their own account';
  end if;
  if p_reason is null or char_length(btrim(p_reason)) < 5 then
    raise exception using errcode = '22023', message = 'activation change reason is required';
  end if;

  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'profile not found';
  end if;

  if v_profile.role = 1 and p_is_active = false
     and (select count(*) from public.profiles where role = 1 and is_active = true) <= 1 then
    raise exception using errcode = '23514', message = 'at least one active Admin must remain';
  end if;

  perform set_config('ticketq.operation', 'profile_admin', true);
  perform set_config('ticketq.reason', left(btrim(p_reason), 500), true);

  update public.profiles set is_active = p_is_active where id = p_user_id returning * into v_profile;
  return v_profile;
end
$$;

create or replace function public.register_device_token(
  p_token text,
  p_platform text,
  p_device_id text
)
returns public.device_tokens
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_token public.device_tokens;
begin
  if not public.is_active_user() then
    raise exception using errcode = '42501', message = 'active authenticated user required';
  end if;
  if p_platform not in ('android', 'ios', 'web') then
    raise exception using errcode = '22023', message = 'unsupported platform';
  end if;
  if char_length(btrim(p_token)) < 20 or char_length(btrim(p_device_id)) < 3 then
    raise exception using errcode = '22023', message = 'invalid token or device id';
  end if;

  delete from public.device_tokens
  where token = p_token and user_id <> auth.uid();

  insert into public.device_tokens (user_id, token, platform, device_id, is_active, last_seen_at)
  values (auth.uid(), btrim(p_token), p_platform, left(btrim(p_device_id), 200), true, now())
  on conflict (user_id, device_id) do update
    set token = excluded.token,
        platform = excluded.platform,
        is_active = true,
        last_seen_at = now(),
        updated_at = now()
  returning * into v_token;

  return v_token;
end
$$;

create or replace function public.unregister_device_token(p_device_id text)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  delete from public.device_tokens
  where user_id = auth.uid() and device_id = p_device_id;
end
$$;

create or replace function public.register_ticket_attachment(
  p_ticket_id uuid,
  p_storage_path text,
  p_file_name text,
  p_mime_type text,
  p_size_bytes bigint
)
returns public.ticket_attachments
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_attachment public.ticket_attachments;
begin
  if not public.can_access_ticket(p_ticket_id) then
    raise exception using errcode = '42501', message = 'ticket attachment access denied';
  end if;
  if public.attachment_ticket_id(p_storage_path) is distinct from p_ticket_id
     or public.attachment_uploader_id(p_storage_path) is distinct from auth.uid() then
    raise exception using errcode = '22023', message = 'storage path does not match ticket and uploader';
  end if;

  insert into public.ticket_attachments (
    ticket_id, storage_path, file_name, mime_type, size_bytes, uploaded_by
  ) values (
    p_ticket_id, p_storage_path, p_file_name, lower(p_mime_type), p_size_bytes, auth.uid()
  )
  returning * into v_attachment;

  return v_attachment;
end
$$;

create or replace function public.get_ticket_stats()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'total', count(*),
    'open', count(*) filter (where status = 'open'),
    'assigned', count(*) filter (where assigned_to is not null and status <> 'closed'),
    'pending', count(*) filter (where status = 'pending'),
    'in_progress', count(*) filter (where status = 'in_progress'),
    'resolved', count(*) filter (where status = 'resolved'),
    'closed', count(*) filter (where status = 'closed'),
    'reopened', count(*) filter (where status = 'reopened')
  )
  from public.tickets
  where deleted_at is null
$$;

commit;
