-- Reproducible Phase 2 RLS/RPC/storage policy test.
-- Run against a disposable local Supabase database after `supabase db reset`:
--   supabase test db supabase/tests/phase_2_policy_test.sql
-- or:
--   psql "$LOCAL_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/phase_2_policy_test.sql
--
-- The entire test is rolled back. It never uses a service_role API key.

begin;

create extension if not exists pgtap with schema extensions;

set local client_min_messages = warning;
set local search_path = public, auth, storage, extensions;

select plan(1);

-- Fixed UUIDs make failures reproducible.
-- User A    10000000-0000-4000-8000-000000000001
-- User B    10000000-0000-4000-8000-000000000002
-- Helpdesk  10000000-0000-4000-8000-000000000003
-- Admin     10000000-0000-4000-8000-000000000004

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'usera@example.test', crypt('Test-only-UserA-2026!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"User A"}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'userb@example.test', crypt('Test-only-UserB-2026!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"User B"}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'helpdesk@example.test', crypt('Test-only-Helpdesk-2026!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Helpdesk"}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', '10000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'admin@example.test', crypt('Test-only-Admin-2026!', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Admin"}', now(), now())
on conflict (id) do nothing;

-- The auth trigger creates profiles as role 3. Bootstrap test roles as database owner.
update public.profiles set role = 2 where id = '10000000-0000-4000-8000-000000000003';
update public.profiles set role = 1 where id = '10000000-0000-4000-8000-000000000004';

insert into public.tickets (id, title, description, category, status, user_id)
values
  ('20000000-0000-4000-8000-000000000001', 'Ticket User A', 'Ticket policy milik User A', 'General', 'open', '10000000-0000-4000-8000-000000000001'),
  ('20000000-0000-4000-8000-000000000002', 'Ticket User B', 'Ticket policy milik User B', 'General', 'open', '10000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- User A can see only User A's ticket.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

do $$
declare
  v_count integer;
begin
  select count(*) into v_count from public.tickets;
  if v_count <> 1 then
    raise exception 'FAIL: User A expected 1 visible ticket, got %', v_count;
  end if;

  if exists (
    select 1 from public.tickets
    where id = '20000000-0000-4000-8000-000000000002'
  ) then
    raise exception 'FAIL: User A can read User B ticket';
  end if;
end
$$;

-- User A cannot upload to User B's ticket path.
do $$
begin
  begin
    insert into storage.objects (bucket_id, name, owner_id, metadata)
    values (
      'tickets',
      '20000000-0000-4000-8000-000000000002/10000000-0000-4000-8000-000000000001/evidence.pdf',
      '10000000-0000-4000-8000-000000000001',
      '{"mimetype":"application/pdf","size":"2048"}'::jsonb
    );
    raise exception 'FAIL: cross-user attachment insert unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
    when check_violation then null;
  end;
end
$$;

reset role;

-- ---------------------------------------------------------------------------
-- Admin can assign only an active Helpdesk account.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

select public.assign_ticket(
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000003',
  'Phase 2 assignment policy test'
);

do $$
declare
  v_assigned uuid;
  v_history_count integer;
  v_actor uuid;
  v_created_at timestamptz;
begin
  select assigned_to into v_assigned
  from public.tickets
  where id = '20000000-0000-4000-8000-000000000001';

  if v_assigned is distinct from '10000000-0000-4000-8000-000000000003'::uuid then
    raise exception 'FAIL: Admin assignment did not persist';
  end if;

  select count(*)
  into v_history_count
  from public.ticket_history
  where ticket_id = '20000000-0000-4000-8000-000000000001'
    and event_type = 'assigned';

  select changed_by, created_at
  into v_actor, v_created_at
  from public.ticket_history
  where ticket_id = '20000000-0000-4000-8000-000000000001'
    and event_type = 'assigned'
  order by created_at desc
  limit 1;

  if v_history_count < 1
     or v_actor is distinct from '10000000-0000-4000-8000-000000000004'::uuid
     or v_created_at is null then
    raise exception 'FAIL: assignment history actor/time missing';
  end if;
end
$$;

reset role;

-- ---------------------------------------------------------------------------
-- Helpdesk sees and may update assigned ticket, but not User B's ticket.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);

do $$
begin
  if not exists (
    select 1 from public.tickets
    where id = '20000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'FAIL: Helpdesk cannot read assigned ticket';
  end if;

  begin
    perform public.update_ticket_status(
      '20000000-0000-4000-8000-000000000002',
      'in_progress',
      'must be rejected'
    );
    raise exception 'FAIL: Helpdesk changed a non-assigned ticket';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

select public.update_ticket_status(
  '20000000-0000-4000-8000-000000000001',
  'in_progress',
  'Start handling assigned ticket'
);

reset role;

-- ---------------------------------------------------------------------------
-- Inactive user immediately loses RLS access.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

select public.admin_set_user_active(
  '10000000-0000-4000-8000-000000000001',
  false,
  'Phase 2 inactive access test'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

do $$
declare
  v_count integer;
begin
  select count(*) into v_count from public.tickets;
  if v_count <> 0 then
    raise exception 'FAIL: inactive User A still sees % tickets', v_count;
  end if;
end
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

select public.admin_set_user_active(
  '10000000-0000-4000-8000-000000000001',
  true,
  'Restore User A after policy test'
);

-- The earlier status change generated a notification for User A. Admin still
-- cannot read another user's private notification content by default.
do $$
begin
  if exists (
    select 1 from public.notifications
    where user_id = '10000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'FAIL: Admin can read another user private notifications';
  end if;
end
$$;

reset role;

-- Reaching this point means all exception-based assertions passed.
select pass(
  'Phase 2 RLS, RPC, storage, history, and inactive-user tests'
);

select * from finish();

rollback;
