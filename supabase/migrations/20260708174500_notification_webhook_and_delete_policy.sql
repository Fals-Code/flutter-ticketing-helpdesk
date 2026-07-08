create extension if not exists pg_net;

alter table public.notifications enable row level security;

drop policy if exists "Users can delete own notifications"
on public.notifications;

create policy "Users can delete own notifications"
on public.notifications
for delete
to authenticated
using (auth.uid() = user_id);

drop trigger if exists send_ticket_notification_webhook
on public.notifications;

drop function if exists public.send_ticket_notification_webhook();

create or replace function public.send_ticket_notification_webhook()
returns trigger
language plpgsql
security definer
set search_path = public, net, extensions
as $$
declare
  webhook_secret text;
begin
  webhook_secret := current_setting('app.ticketq_webhook_secret', true);

  perform net.http_post(
    url := 'https://lfxwvrlvefrjhmqaerbz.supabase.co/functions/v1/send-ticket-notification',
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'notifications',
      'schema', 'public',
      'record', to_jsonb(new),
      'old_record', null
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-ticketq-webhook-secret', coalesce(webhook_secret, '')
    ),
    timeout_milliseconds := 5000
  );

  return new;
end;
$$;

create trigger send_ticket_notification_webhook
after insert on public.notifications
for each row
execute function public.send_ticket_notification_webhook();
