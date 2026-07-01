begin;

create extension if not exists pgcrypto with schema extensions;

set local client_min_messages = warning;
set local search_path = public, auth, storage, extensions;

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
  (
    '00000000-0000-0000-0000-000000000000',
    '81000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'phase4-delete-user-a@example.test',
    crypt('Phase4-Delete-UserA-2026!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Delete User A"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '81000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'phase4-delete-user-b@example.test',
    crypt('Phase4-Delete-UserB-2026!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Delete User B"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '81000000-0000-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'phase4-delete-helpdesk@example.test',
    crypt('Phase4-Delete-Helpdesk-2026!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Delete Helpdesk"}',
    now(),
    now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '81000000-0000-4000-8000-000000000004',
    'authenticated',
    'authenticated',
    'phase4-delete-admin@example.test',
    crypt('Phase4-Delete-Admin-2026!', gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Delete Admin"}',
    now(),
    now()
  )
on conflict (id) do update set updated_at = excluded.updated_at;

update public.profiles
set role = 2
where id = '81000000-0000-4000-8000-000000000003';

update public.profiles
set role = 1
where id = '81000000-0000-4000-8000-000000000004';

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select public.create_ticket_with_attachments(
  '82000000-0000-4000-8000-000000000001',
  'Delete valid owner',
  'Ticket with attachment',
  'General',
  jsonb_build_array(jsonb_build_object(
    'storage_path',
    '82000000-0000-4000-8000-000000000001/81000000-0000-4000-8000-000000000001/invoice-v1.pdf',
    'file_name',
    'invoice-v1.pdf',
    'mime_type',
    'application/pdf',
    'size_bytes',
    2048
  ))
);

do $$
declare
  v_result jsonb;
  v_functiondef text;
begin
  select public.delete_ticket_with_attachments(
    '82000000-0000-4000-8000-000000000001',
    'Owner requested deletion'
  )
  into v_result;

  if v_result ->> 'ticket_id' <> '82000000-0000-4000-8000-000000000001' then
    raise exception 'FAIL: delete RPC returned wrong ticket id: %', v_result;
  end if;

  if not (v_result -> 'attachment_paths') ? '82000000-0000-4000-8000-000000000001/81000000-0000-4000-8000-000000000001/invoice-v1.pdf' then
    raise exception 'FAIL: delete RPC did not return text storage path: %', v_result;
  end if;

  select pg_get_functiondef('public.delete_ticket_with_attachments(uuid,text)'::regprocedure)
  into v_functiondef;

  if lower(v_functiondef) like '%delete from storage.objects%'
     or lower(v_functiondef) like '%update storage.objects%'
     or lower(v_functiondef) like '%insert into storage.objects%' then
    raise exception 'FAIL: delete RPC still mutates storage.objects directly';
  end if;
end
$$;

reset role;

do $$
declare
  v_history_count integer;
  v_deleted_at timestamptz;
  v_attachment_deleted_at timestamptz;
begin
  select deleted_at
  into v_deleted_at
  from public.tickets
  where id = '82000000-0000-4000-8000-000000000001';

  if v_deleted_at is null then
    raise exception 'FAIL: ticket was not soft deleted';
  end if;

  select deleted_at
  into v_attachment_deleted_at
  from public.ticket_attachments
  where ticket_id = '82000000-0000-4000-8000-000000000001';

  if v_attachment_deleted_at is null then
    raise exception 'FAIL: attachment metadata was not soft deleted';
  end if;

  select count(*)
  into v_history_count
  from public.ticket_history
  where ticket_id = '82000000-0000-4000-8000-000000000001'
    and event_type = 'ticket_deleted';

  if v_history_count <> 1 then
    raise exception 'FAIL: expected one ticket_deleted history row, got %', v_history_count;
  end if;
end
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

do $$
begin
  begin
    perform public.delete_ticket_with_attachments(
      '82000000-0000-4000-8000-000000000001',
      'Duplicate delete'
    );
    raise exception 'FAIL: duplicate delete unexpectedly succeeded';
  exception
    when no_data_found then null;
    when sqlstate 'P0002' then null;
  end;
end
$$;

select public.create_ticket_with_attachments(
  '82000000-0000-4000-8000-000000000002',
  'Delete unauthorized',
  'Ticket owned by User A',
  'General',
  '[]'::jsonb
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

do $$
begin
  begin
    perform public.delete_ticket_with_attachments(
      '82000000-0000-4000-8000-000000000002',
      'Unauthorized delete'
    );
    raise exception 'FAIL: non-owner delete unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

do $$
begin
  begin
    perform public.delete_ticket_with_attachments(
      '82000000-0000-4000-8000-000000009999',
      'Missing ticket'
    );
    raise exception 'FAIL: missing ticket delete unexpectedly succeeded';
  exception
    when no_data_found then null;
    when sqlstate 'P0002' then null;
  end;
end
$$;

select public.create_ticket_with_attachments(
  '82000000-0000-4000-8000-000000000003',
  'Assigned ticket',
  'Owner should not delete assigned ticket',
  'General',
  '[]'::jsonb
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);

select public.assign_ticket(
  '82000000-0000-4000-8000-000000000003',
  '81000000-0000-4000-8000-000000000003',
  'Assign for delete policy test'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"81000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

do $$
begin
  begin
    perform public.delete_ticket_with_attachments(
      '82000000-0000-4000-8000-000000000003',
      'Assigned ticket delete'
    );
    raise exception 'FAIL: assigned ticket delete unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
set local role anon;

do $$
begin
  begin
    perform public.delete_ticket_with_attachments(
      '82000000-0000-4000-8000-000000000002',
      'Anonymous delete'
    );
    raise exception 'FAIL: unauthenticated delete unexpectedly succeeded';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

rollback;
