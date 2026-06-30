-- Run after `supabase db reset`.
begin;

create extension if not exists pgtap with schema extensions;
set local client_min_messages = warning;
set local search_path = public, auth, extensions;

select plan(1);

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
) values (
  '00000000-0000-0000-0000-000000000000',
  '30000000-0000-4000-8000-000000000001',
  'authenticated',
  'authenticated',
  'phase3@example.test',
  crypt('Phase3-Test-2026!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Phase 3 User","username":"phase3_user"}',
  now(),
  now()
);

set local role anon;

do $$
declare
  v_email text;
begin
  select public.resolve_login_email('PHASE3_USER') into v_email;
  if v_email is distinct from 'phase3@example.test' then
    raise exception 'FAIL: username did not resolve to the expected email';
  end if;
end
$$;

reset role;
update public.profiles
set is_active = false
where id = '30000000-0000-4000-8000-000000000001';

set local role anon;

do $$
declare
  v_email text;
begin
  select public.resolve_login_email('phase3_user') into v_email;
  if v_email is not null then
    raise exception 'FAIL: inactive username still resolves';
  end if;
end
$$;

reset role;

do $$
begin
  begin
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
    ) values (
      '00000000-0000-0000-0000-000000000000',
      '30000000-0000-4000-8000-000000000002',
      'authenticated',
      'authenticated',
      'duplicate@example.test',
      crypt('Phase3-Duplicate-2026!', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Duplicate","username":"PHASE3_USER"}',
      now(),
      now()
    );
    raise exception 'FAIL: duplicate username unexpectedly succeeded';
  exception
    when unique_violation then null;
  end;
end
$$;

select pass('Phase 3 username auth and inactive account rules pass');
select * from finish();
rollback;
