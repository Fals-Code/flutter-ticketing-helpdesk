-- ============================================================================
-- TICKET-Q MAIN RUNTIME COMPATIBILITY MIGRATION
-- Target repository: Fals-Code/flutter-ticketing-helpdesk
-- Target branch/commit: main @ 5994998
--
-- Run AFTER the existing repository migrations:
--   20260625020000_phase_2_schema.sql
--   20260625020100_phase_2_functions_and_triggers.sql
--   20260625020200_phase_2_rls_and_storage.sql
--   20260630030000_phase_3_auth_rbac.sql
--
-- Purpose:
--   1. Preserve the secure Phase 2/3 baseline.
--   2. Add missing contracts used by the Flutter code currently on main.
--   3. Make the migration repeatable and non-destructive.
--
-- IMPORTANT:
--   * Back up production before execution.
--   * Dry-run on staging or a cloned database first.
--   * The legacy ticket image flow on main uses getPublicUrl() and the path
--     ticket_images/<uuid>.<ext>. Therefore this patch keeps compatibility by
--     making the tickets bucket public for legacy images. A later Flutter patch
--     should migrate to private signed URLs and the canonical secure path.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 0. Baseline guard
-- ---------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.profiles') is null
     or to_regclass('public.tickets') is null
     or to_regclass('public.comments') is null
     or to_regclass('public.notifications') is null then
    raise exception using
      errcode = 'P0002',
      message = 'TICKET-Q baseline tables are missing. Run the Phase 2 and Phase 3 repository migrations first.';
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- 1. Phase 3 auth compatibility
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists username text;

update public.profiles as profile
set username = lower(
  nullif(
    btrim(auth_user.raw_user_meta_data ->> 'username'),
    ''
  )
)
from auth.users as auth_user
where auth_user.id = profile.id
  and profile.username is null
  and nullif(
    btrim(auth_user.raw_user_meta_data ->> 'username'),
    ''
  ) is not null;

create unique index if not exists profiles_username_unique
  on public.profiles (lower(username))
  where nullif(btrim(username), '') is not null;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_username text := lower(
    nullif(
      btrim(new.raw_user_meta_data ->> 'username'),
      ''
    )
  );
begin
  insert into public.profiles (
    id,
    email,
    username,
    full_name,
    role,
    is_active
  )
  values (
    new.id,
    lower(new.email),
    v_username,
    left(
      coalesce(new.raw_user_meta_data ->> 'full_name', ''),
      150
    ),
    3,
    true
  )
  on conflict (id) do update
  set
    email = excluded.email,
    username = coalesce(
      public.profiles.username,
      excluded.username
    ),
    full_name = case
      when public.profiles.full_name = ''
        then excluded.full_name
      else public.profiles.full_name
    end,
    updated_at = now();

  return new;
end
$$;

create or replace function public.resolve_login_email(
  p_identifier text
)
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select lower(auth_user.email)
  from public.profiles as profile
  join auth.users as auth_user
    on auth_user.id = profile.id
  where profile.is_active = true
    and lower(profile.username) = lower(btrim(p_identifier))
  limit 1
$$;

revoke all
  on function public.resolve_login_email(text)
  from public;

grant execute
  on function public.resolve_login_email(text)
  to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Rating feedback alias used by the current main Flutter source
-- ---------------------------------------------------------------------------

alter table public.tickets
  add column if not exists feedback text;

update public.tickets
set
  rating_feedback = coalesce(rating_feedback, feedback),
  feedback = coalesce(feedback, rating_feedback)
where rating_feedback is null
   or feedback is null;

create or replace function public.sync_ticket_feedback_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.rating_feedback := coalesce(new.rating_feedback, new.feedback);
    new.feedback := coalesce(new.feedback, new.rating_feedback);
    return new;
  end if;

  if new.feedback is distinct from old.feedback
     and new.rating_feedback is not distinct from old.rating_feedback then
    new.rating_feedback := new.feedback;
  elsif new.rating_feedback is distinct from old.rating_feedback
        and new.feedback is not distinct from old.feedback then
    new.feedback := new.rating_feedback;
  end if;

  return new;
end
$$;

drop trigger if exists tickets_00_sync_feedback_fields on public.tickets;
create trigger tickets_00_sync_feedback_fields
before insert or update on public.tickets
for each row execute function public.sync_ticket_feedback_fields();

-- ---------------------------------------------------------------------------
-- 3. Profile direct-write compatibility for the current Admin UI
-- ---------------------------------------------------------------------------

create or replace function public.protect_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_is_admin boolean := public.is_admin();
  v_active_admin_count integer;
begin
  if auth.uid() is null then
    new.updated_at := now();
    return new;
  end if;

  if new.id is distinct from old.id
     or new.created_at is distinct from old.created_at then
    raise exception using
      errcode = '42501',
      message = 'immutable profile fields cannot be changed';
  end if;

  if not v_is_admin then
    if new.role is distinct from old.role
       or new.is_active is distinct from old.is_active
       or new.email is distinct from old.email then
      raise exception using
        errcode = '42501',
        message = 'role, activation, and email are protected fields';
    end if;
  else
    if new.id = auth.uid()
       and new.role is distinct from old.role then
      raise exception using
        errcode = '42501',
        message = 'Admin cannot change their own role';
    end if;

    if new.id = auth.uid()
       and old.is_active = true
       and new.is_active = false then
      raise exception using
        errcode = '42501',
        message = 'Admin cannot deactivate their own account';
    end if;

    if old.role = 1
       and old.is_active = true
       and (
         new.role is distinct from 1
         or new.is_active = false
       ) then
      select count(*)
      into v_active_admin_count
      from public.profiles
      where role = 1
        and is_active = true;

      if v_active_admin_count <= 1 then
        raise exception using
          errcode = '23514',
          message = 'at least one active Admin must remain';
      end if;
    end if;

    if new.role is distinct from old.role
       or new.is_active is distinct from old.is_active then
      perform set_config('ticketq.operation', 'profile_admin', true);
      perform set_config(
        'ticketq.reason',
        'Updated from current main Admin UI',
        true
      );
    end if;
  end if;

  new.updated_at := now();
  return new;
end
$$;

-- Existing trigger keeps using the replaced function.
drop trigger if exists profiles_protect_privileged_fields on public.profiles;
create trigger profiles_protect_privileged_fields
before update on public.profiles
for each row execute function public.protect_profile_privileged_fields();

-- ---------------------------------------------------------------------------
-- 4. Ticket direct-write compatibility for current main
-- ---------------------------------------------------------------------------

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
  v_content_changed boolean;
  v_rating_changed boolean;
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      if not public.is_active_user() then
        raise exception using
          errcode = '42501',
          message = 'inactive users cannot create tickets';
      end if;

      if new.user_id is distinct from auth.uid() then
        raise exception using
          errcode = '42501',
          message = 'tickets can only be created for the authenticated user';
      end if;

      if new.assigned_to is not null then
        raise exception using
          errcode = '42501',
          message = 'new tickets cannot be pre-assigned';
      end if;

      new.status := 'open';
    end if;
  else
    if new.id is distinct from old.id
       or new.user_id is distinct from old.user_id
       or new.created_at is distinct from old.created_at then
      raise exception using
        errcode = '42501',
        message = 'ticket ownership and identity are immutable';
    end if;

    if auth.uid() is not null
       and not public.is_active_user() then
      raise exception using
        errcode = '42501',
        message = 'inactive users cannot update tickets';
    end if;

    if new.deleted_at is distinct from old.deleted_at
       and coalesce(v_operation, '') not in ('soft_delete', 'restore') then
      raise exception using
        errcode = '42501',
        message = 'use the ticket soft-delete RPC';
    end if;

    if new.assigned_to is distinct from old.assigned_to
       and coalesce(v_role, 0) <> 1 then
      raise exception using
        errcode = '42501',
        message = 'ticket assignment is Admin-only';
    end if;

    v_content_changed :=
      new.title is distinct from old.title
      or new.description is distinct from old.description
      or new.category is distinct from old.category
      or new.images is distinct from old.images;

    v_rating_changed :=
      new.rating is distinct from old.rating
      or new.rating_feedback is distinct from old.rating_feedback
      or new.feedback is distinct from old.feedback;

    if new.status is distinct from old.status then
      if v_role = 1 then
        if not public.ticket_status_transition_allowed(
          old.status,
          new.status
        )
        and coalesce(v_operation, '') <> 'admin_override' then
          raise exception using
            errcode = '23514',
            message = 'illegal ticket status transition';
        end if;
      elsif v_role = 2 then
        if old.assigned_to is distinct from auth.uid() then
          raise exception using
            errcode = '42501',
            message = 'Helpdesk may only update assigned tickets';
        end if;

        if not public.ticket_status_transition_allowed(
          old.status,
          new.status
        ) then
          raise exception using
            errcode = '23514',
            message = 'illegal ticket status transition';
        end if;
      elsif v_role = 3 then
        if not (
          old.user_id = auth.uid()
          and old.status in ('resolved', 'closed')
          and new.status = 'closed'
          and new.rating between 1 and 5
        ) then
          raise exception using
            errcode = '42501',
            message = 'User may only close a resolved ticket while submitting a rating';
        end if;
      else
        raise exception using
          errcode = '42501',
          message = 'unsupported account role';
      end if;
    end if;

    if v_role = 2 then
      if old.assigned_to is distinct from auth.uid() then
        raise exception using
          errcode = '42501',
          message = 'Helpdesk may only update assigned tickets';
      end if;

      if v_content_changed or v_rating_changed then
        raise exception using
          errcode = '42501',
          message = 'Helpdesk may only update workflow fields';
      end if;
    elsif v_role = 3 then
      if old.user_id is distinct from auth.uid() then
        raise exception using
          errcode = '42501',
          message = 'Users may only update their own tickets';
      end if;

      if v_content_changed
         and (
           old.assigned_to is not null
           or old.status <> 'open'
         ) then
        raise exception using
          errcode = '42501',
          message = 'only an unassigned open ticket can be edited by its reporter';
      end if;

      if v_rating_changed then
        if old.status not in ('resolved', 'closed') then
          raise exception using
            errcode = '23514',
            message = 'rating is only allowed after resolution';
        end if;

        if new.rating is null
           or new.rating not between 1 and 5 then
          raise exception using
            errcode = '23514',
            message = 'rating must be between 1 and 5';
        end if;
      end if;
    end if;
  end if;

  if new.assigned_to is not null then
    select profile.role, profile.is_active
    into v_target_role, v_target_active
    from public.profiles as profile
    where profile.id = new.assigned_to;

    if v_target_role is distinct from 2
       or v_target_active is distinct from true then
      raise exception using
        errcode = '23514',
        message = 'assigned_to must reference an active Helpdesk account';
    end if;
  end if;

  new.updated_at := now();
  return new;
end
$$;

drop trigger if exists tickets_validate_write on public.tickets;
create trigger tickets_validate_write
before insert or update on public.tickets
for each row execute function public.validate_ticket_write();

-- ---------------------------------------------------------------------------
-- 5. Legacy configs table expected by the current Admin data source
-- ---------------------------------------------------------------------------

create table if not exists public.configs (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.configs
  add column if not exists value jsonb not null default '{}'::jsonb;
alter table public.configs
  add column if not exists updated_by uuid;
alter table public.configs
  add column if not exists created_at timestamptz not null default now();
alter table public.configs
  add column if not exists updated_at timestamptz not null default now();

insert into public.configs (
  key,
  value,
  updated_by,
  created_at,
  updated_at
)
select
  setting.key,
  setting.value,
  setting.updated_by,
  setting.created_at,
  setting.updated_at
from public.app_settings as setting
on conflict (key) do nothing;

insert into public.configs (
  key,
  value
)
values (
  'app_settings',
  jsonb_build_object(
    'maintenance_mode', false,
    'sla_hours', 4,
    'auto_assign', true,
    'default_priority', 'Medium'
  )
)
on conflict (key) do nothing;

create or replace function public.prepare_config_write()
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

create or replace function public.sync_config_to_app_settings()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.app_settings (
    key,
    value,
    is_public,
    updated_by,
    created_at,
    updated_at
  )
  values (
    new.key,
    new.value,
    false,
    auth.uid(),
    coalesce(new.created_at, now()),
    now()
  )
  on conflict (key) do update
  set
    value = excluded.value,
    updated_by = excluded.updated_by,
    updated_at = now();

  return new;
end
$$;

drop trigger if exists configs_prepare_write on public.configs;
create trigger configs_prepare_write
before insert or update on public.configs
for each row execute function public.prepare_config_write();

drop trigger if exists configs_sync_app_settings on public.configs;
create trigger configs_sync_app_settings
after insert or update on public.configs
for each row execute function public.sync_config_to_app_settings();

alter table public.configs enable row level security;

drop policy if exists configs_select_admin on public.configs;
create policy configs_select_admin on public.configs
for select to authenticated
using (public.is_admin());

drop policy if exists configs_insert_admin on public.configs;
create policy configs_insert_admin on public.configs
for insert to authenticated
with check (public.is_admin());

drop policy if exists configs_update_admin on public.configs;
create policy configs_update_admin on public.configs
for update to authenticated
using (public.is_admin())
with check (public.is_admin());

revoke all on table public.configs from anon;
grant select, insert, update on table public.configs to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Admin report RPC expected by the current main Flutter source
-- ---------------------------------------------------------------------------

-- PostgreSQL cannot change a function return type with CREATE OR REPLACE.
-- Drop the previous overload with the same identity arguments inside this
-- transaction, then recreate it with the runtime contract expected by Flutter.
drop function if exists public.get_admin_reports(timestamptz, timestamptz);

create or replace function public.get_admin_reports(
  p_start_date timestamptz default null,
  p_end_date timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_result jsonb;
begin
  if not public.is_admin() then
    raise exception using
      errcode = '42501',
      message = 'Admin role required';
  end if;

  select jsonb_build_object(
    'team_performance',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'technician_id', team.technician_id,
            'full_name', team.full_name,
            'resolved_count', team.resolved_count
          )
          order by team.resolved_count desc, team.full_name asc
        )
        from (
          select
            profile.id as technician_id,
            profile.full_name,
            count(ticket.id) filter (
              where ticket.status in ('resolved', 'closed')
            )::integer as resolved_count
          from public.profiles as profile
          left join public.tickets as ticket
            on ticket.assigned_to = profile.id
           and ticket.deleted_at is null
           and (
             p_start_date is null
             or ticket.created_at >= p_start_date
           )
           and (
             p_end_date is null
             or ticket.created_at <= p_end_date
           )
          where profile.role = 2
            and profile.is_active = true
          group by profile.id, profile.full_name
        ) as team
      ),
      '[]'::jsonb
    ),
    'category_distribution',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'category', category_rows.category,
            'count', category_rows.ticket_count
          )
          order by category_rows.ticket_count desc,
                   category_rows.category asc
        )
        from (
          select
            ticket.category,
            count(*)::integer as ticket_count
          from public.tickets as ticket
          where ticket.deleted_at is null
            and (
              p_start_date is null
              or ticket.created_at >= p_start_date
            )
            and (
              p_end_date is null
              or ticket.created_at <= p_end_date
            )
          group by ticket.category
        ) as category_rows
      ),
      '[]'::jsonb
    )
  )
  into v_result;

  return v_result;
end
$$;

revoke all
  on function public.get_admin_reports(timestamptz, timestamptz)
  from public;

grant execute
  on function public.get_admin_reports(timestamptz, timestamptz)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Notification insertion used by the current ticket flow
-- ---------------------------------------------------------------------------

drop policy if exists notifications_insert_runtime_scope
  on public.notifications;

create policy notifications_insert_runtime_scope
on public.notifications
for insert to authenticated
with check (
  public.is_active_user()
  and (
    user_id = auth.uid()
    or public.is_admin()
    or (
      public.is_technician()
      and ticket_id is not null
      and exists (
        select 1
        from public.tickets as ticket
        where ticket.id = public.notifications.ticket_id
          and ticket.deleted_at is null
          and ticket.assigned_to = auth.uid()
          and ticket.user_id = public.notifications.user_id
      )
    )
  )
);

grant insert on table public.notifications to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Avatar bucket expected by AuthRemoteDataSource
-- ---------------------------------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]::text[]
)
on conflict (id) do update
set
  name = excluded.name,
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists avatar_objects_select_public
  on storage.objects;
create policy avatar_objects_select_public
on storage.objects
for select
using (bucket_id = 'avatars');

drop policy if exists avatar_objects_insert_own
  on storage.objects;
create policy avatar_objects_insert_own
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'avatars'
  and public.is_active_user()
  and split_part(name, '/', 1) = 'avatars'
  and split_part(name, '/', 2) = auth.uid()::text
  and position('..' in name) = 0
);

drop policy if exists avatar_objects_update_own
  on storage.objects;
create policy avatar_objects_update_own
on storage.objects
for update to authenticated
using (
  bucket_id = 'avatars'
  and public.is_active_user()
  and split_part(name, '/', 1) = 'avatars'
  and split_part(name, '/', 2) = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and public.is_active_user()
  and split_part(name, '/', 1) = 'avatars'
  and split_part(name, '/', 2) = auth.uid()::text
  and position('..' in name) = 0
);

drop policy if exists avatar_objects_delete_own
  on storage.objects;
create policy avatar_objects_delete_own
on storage.objects
for delete to authenticated
using (
  bucket_id = 'avatars'
  and public.is_active_user()
  and split_part(name, '/', 1) = 'avatars'
  and split_part(name, '/', 2) = auth.uid()::text
);

-- ---------------------------------------------------------------------------
-- 9. Legacy ticket image compatibility for current main
-- ---------------------------------------------------------------------------

update storage.buckets
set
  public = true,
  allowed_mime_types = array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/octet-stream',
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]::text[]
where id = 'tickets';

drop policy if exists ticket_objects_select_legacy_main
  on storage.objects;
create policy ticket_objects_select_legacy_main
on storage.objects
for select
using (
  bucket_id = 'tickets'
  and split_part(name, '/', 1) = 'ticket_images'
);

drop policy if exists ticket_objects_insert_legacy_main
  on storage.objects;
create policy ticket_objects_insert_legacy_main
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'tickets'
  and public.is_active_user()
  and split_part(name, '/', 1) = 'ticket_images'
  and name ~ '^ticket_images/[A-Za-z0-9][A-Za-z0-9._-]{0,150}$'
  and position('..' in name) = 0
);

-- ---------------------------------------------------------------------------
-- 10. Realtime membership, safe to rerun
-- ---------------------------------------------------------------------------

do $$
begin
  alter publication supabase_realtime
    add table public.tickets;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.comments;
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.notifications;
exception
  when duplicate_object then null;
end
$$;

-- ---------------------------------------------------------------------------
-- 11. Installation assertions
-- ---------------------------------------------------------------------------

do $$
begin
  if to_regprocedure(
    'public.resolve_login_email(text)'
  ) is null then
    raise exception 'resolve_login_email(text) was not installed';
  end if;

  if to_regprocedure(
    'public.get_admin_reports(timestamp with time zone,timestamp with time zone)'
  ) is null then
    raise exception 'get_admin_reports(timestamptz,timestamptz) was not installed';
  end if;

  if not exists (
    select 1
    from storage.buckets
    where id = 'avatars'
  ) then
    raise exception 'avatars storage bucket was not installed';
  end if;

  if not exists (
    select 1
    from storage.buckets
    where id = 'tickets'
  ) then
    raise exception 'tickets storage bucket is missing';
  end if;
end
$$;

-- Ask PostgREST to refresh its schema cache after the transaction commits.
notify pgrst, 'reload schema';

commit;
