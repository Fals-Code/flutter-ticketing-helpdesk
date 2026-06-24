-- TICKET-Q Phase 2: Supabase backend and security baseline.
--
-- Safety properties:
--   * additive/idempotent where PostgreSQL permits it;
--   * no DROP TABLE, DROP COLUMN, TRUNCATE, or destructive data rewrite;
--   * intended to run from a clean Supabase project;
--   * production execution requires backup and a reviewed dry run.

begin;

-- ---------------------------------------------------------------------------
-- 1. Core tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  role smallint not null default 3,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists full_name text not null default '';
alter table public.profiles add column if not exists role smallint not null default 3;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists is_active boolean not null default true;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null default 'General',
  status text not null default 'open',
  user_id uuid not null references public.profiles(id) on delete restrict,
  assigned_to uuid references public.profiles(id) on delete set null,
  images text[] not null default '{}'::text[],
  rating smallint,
  rating_feedback text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete set null,
  delete_reason text
);

alter table public.tickets add column if not exists title text;
alter table public.tickets add column if not exists description text;
alter table public.tickets add column if not exists category text not null default 'General';
alter table public.tickets add column if not exists status text not null default 'open';
alter table public.tickets add column if not exists user_id uuid;
alter table public.tickets add column if not exists assigned_to uuid;
alter table public.tickets add column if not exists images text[] not null default '{}'::text[];
alter table public.tickets add column if not exists rating smallint;
alter table public.tickets add column if not exists rating_feedback text;
alter table public.tickets add column if not exists created_at timestamptz not null default now();
alter table public.tickets add column if not exists updated_at timestamptz not null default now();
alter table public.tickets add column if not exists deleted_at timestamptz;
alter table public.tickets add column if not exists deleted_by uuid;
alter table public.tickets add column if not exists delete_reason text;

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete restrict,
  message text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.comments add column if not exists ticket_id uuid;
alter table public.comments add column if not exists user_id uuid;
alter table public.comments add column if not exists message text;
alter table public.comments add column if not exists created_at timestamptz not null default now();
alter table public.comments add column if not exists updated_at timestamptz not null default now();
alter table public.comments add column if not exists deleted_at timestamptz;

create table if not exists public.ticket_history (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete restrict,
  event_type text not null default 'status_changed',
  old_status text,
  new_status text,
  changed_by uuid references public.profiles(id) on delete set null,
  actor_role smallint,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.ticket_history add column if not exists ticket_id uuid;
alter table public.ticket_history add column if not exists event_type text not null default 'status_changed';
alter table public.ticket_history add column if not exists old_status text;
alter table public.ticket_history add column if not exists new_status text;
alter table public.ticket_history add column if not exists changed_by uuid;
alter table public.ticket_history add column if not exists actor_role smallint;
alter table public.ticket_history add column if not exists reason text;
alter table public.ticket_history add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.ticket_history add column if not exists created_at timestamptz not null default now();

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  ticket_id uuid references public.tickets(id) on delete set null,
  notification_type text not null default 'ticket_activity',
  payload jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.notifications add column if not exists user_id uuid;
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists message text;
alter table public.notifications add column if not exists ticket_id uuid;
alter table public.notifications add column if not exists notification_type text not null default 'ticket_activity';
alter table public.notifications add column if not exists payload jsonb not null default '{}'::jsonb;
alter table public.notifications add column if not exists is_read boolean not null default false;
alter table public.notifications add column if not exists read_at timestamptz;
alter table public.notifications add column if not exists created_at timestamptz not null default now();

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null,
  device_id text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (token),
  unique (user_id, device_id)
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  is_public boolean not null default false,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete restrict,
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null,
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  actor_id uuid references public.profiles(id) on delete set null,
  target_user_id uuid references public.profiles(id) on delete set null,
  reason text,
  old_value jsonb,
  new_value jsonb,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 2. Integrity constraints
-- ---------------------------------------------------------------------------

-- Role mapping is intentionally compatible with the Flutter source:
-- 1 = admin, 2 = technician/helpdesk, 3 = user.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_role_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_check check (role in (1, 2, 3)) not valid;
  end if;
end
$$;

alter table public.profiles validate constraint profiles_role_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tickets_status_check'
      and conrelid = 'public.tickets'::regclass
  ) then
    alter table public.tickets
      add constraint tickets_status_check
      check (status in ('open', 'pending', 'in_progress', 'resolved', 'closed', 'reopened')) not valid;
  end if;
end
$$;

alter table public.tickets validate constraint tickets_status_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tickets_rating_check'
      and conrelid = 'public.tickets'::regclass
  ) then
    alter table public.tickets
      add constraint tickets_rating_check check (rating is null or rating between 1 and 5) not valid;
  end if;
end
$$;

alter table public.tickets validate constraint tickets_rating_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tickets_required_text_check'
      and conrelid = 'public.tickets'::regclass
  ) then
    alter table public.tickets
      add constraint tickets_required_text_check
      check (
        char_length(btrim(title)) between 3 and 200
        and char_length(btrim(description)) between 5 and 10000
        and char_length(btrim(category)) between 1 and 100
      ) not valid;
  end if;
end
$$;

alter table public.tickets validate constraint tickets_required_text_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'comments_message_check'
      and conrelid = 'public.comments'::regclass
  ) then
    alter table public.comments
      add constraint comments_message_check
      check (char_length(btrim(message)) between 1 and 5000) not valid;
  end if;
end
$$;

alter table public.comments validate constraint comments_message_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'ticket_history_event_type_check'
      and conrelid = 'public.ticket_history'::regclass
  ) then
    alter table public.ticket_history
      add constraint ticket_history_event_type_check
      check (event_type in (
        'ticket_created', 'status_changed', 'admin_override', 'assigned', 'unassigned',
        'ticket_deleted', 'ticket_restored', 'comment_added',
        'attachment_uploaded', 'attachment_deleted'
      )) not valid;
  end if;
end
$$;

alter table public.ticket_history validate constraint ticket_history_event_type_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'device_tokens_platform_check'
      and conrelid = 'public.device_tokens'::regclass
  ) then
    alter table public.device_tokens
      add constraint device_tokens_platform_check
      check (platform in ('android', 'ios', 'web')) not valid;
  end if;
end
$$;

alter table public.device_tokens validate constraint device_tokens_platform_check;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'ticket_attachments_file_check'
      and conrelid = 'public.ticket_attachments'::regclass
  ) then
    alter table public.ticket_attachments
      add constraint ticket_attachments_file_check
      check (
        size_bytes between 1 and 10485760
        and char_length(file_name) between 1 and 120
        and file_name ~ '^[A-Za-z0-9][A-Za-z0-9._-]*$'
        and position('..' in file_name) = 0
        and mime_type in (
          'image/jpeg', 'image/png', 'image/webp',
          'application/pdf', 'text/plain',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        )
      ) not valid;
  end if;
end
$$;

alter table public.ticket_attachments validate constraint ticket_attachments_file_check;

-- Explicit foreign keys for installations that already had partial tables.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'tickets_user_id_fkey' and conrelid = 'public.tickets'::regclass) then
    alter table public.tickets add constraint tickets_user_id_fkey foreign key (user_id) references public.profiles(id) on delete restrict not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'tickets_assigned_to_fkey' and conrelid = 'public.tickets'::regclass) then
    alter table public.tickets add constraint tickets_assigned_to_fkey foreign key (assigned_to) references public.profiles(id) on delete set null not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'tickets_deleted_by_fkey' and conrelid = 'public.tickets'::regclass) then
    alter table public.tickets add constraint tickets_deleted_by_fkey foreign key (deleted_by) references public.profiles(id) on delete set null not valid;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- 3. Indexes used by RLS and application queries
-- ---------------------------------------------------------------------------

create index if not exists profiles_role_active_idx on public.profiles(role, is_active);
create index if not exists tickets_user_id_created_at_idx on public.tickets(user_id, created_at desc);
create index if not exists tickets_assigned_to_created_at_idx on public.tickets(assigned_to, created_at desc);
create index if not exists tickets_status_created_at_idx on public.tickets(status, created_at desc);
create index if not exists tickets_active_idx on public.tickets(id) where deleted_at is null;
create index if not exists comments_ticket_id_created_at_idx on public.comments(ticket_id, created_at);
create index if not exists ticket_history_ticket_id_created_at_idx on public.ticket_history(ticket_id, created_at desc);
create index if not exists notifications_user_read_created_idx on public.notifications(user_id, is_read, created_at desc);
create index if not exists ticket_attachments_ticket_id_idx on public.ticket_attachments(ticket_id) where deleted_at is null;
create index if not exists admin_audit_target_created_idx on public.admin_audit_log(target_user_id, created_at desc);

commit;
