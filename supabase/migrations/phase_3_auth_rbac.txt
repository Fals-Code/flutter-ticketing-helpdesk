-- TICKET-Q Phase 3: Authentication and RBAC support.
begin;

create unique index if not exists auth_users_username_unique
  on auth.users (lower(raw_user_meta_data ->> 'username'))
  where nullif(btrim(raw_user_meta_data ->> 'username'), '') is not null;

create or replace function public.resolve_login_email(p_identifier text)
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select lower(u.email)
  from auth.users u
  join public.profiles p on p.id = u.id
  where p.is_active = true
    and lower(u.raw_user_meta_data ->> 'username') = lower(btrim(p_identifier))
  limit 1
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;

commit;
