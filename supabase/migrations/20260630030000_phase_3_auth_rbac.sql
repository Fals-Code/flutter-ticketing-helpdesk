-- TICKET-Q Phase 3: Authentication and RBAC support.

begin;

alter table public.profiles
  add column if not exists username text;

update public.profiles as profile
set username = lower(
  btrim(auth_user.raw_user_meta_data ->> 'username')
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

commit;
