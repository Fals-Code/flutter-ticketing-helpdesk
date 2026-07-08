import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.48.1';

type NotificationRecord = {
  id: string;
  user_id: string;
  title: string;
  message: string;
  ticket_id?: string | null;
  notification_type?: string | null;
  payload?: Record<string, unknown> | null;
};

type DeviceToken = {
  token: string;
  platform: 'android' | 'ios' | 'web';
};

type DeliveryResult = {
  token: string;
  ok: boolean;
  status: number;
  response: string;
};

const encoder = new TextEncoder();

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const configuredSecret = Deno.env.get('WEBHOOK_SECRET')?.trim() ?? '';
  if (configuredSecret.isNotEmpty) {
    const incomingSecret = request.headers.get('x-ticketq-webhook-secret') ?? '';
    if (incomingSecret !== configuredSecret) {
      return jsonResponse({ error: 'unauthorized_webhook' }, 401);
    }
  }

  const body = await request.json().catch(() => null);
  const record = extractNotificationRecord(body);
  if (record == null) {
    return jsonResponse({ delivered: 0, skipped: 'no_notification_record' });
  }

  const supabaseUrl = readEnv('SUPABASE_URL');
  const serviceRoleKey = readEnv('SUPABASE_SERVICE_ROLE_KEY');
  const firebaseProjectId = readEnv('FIREBASE_PROJECT_ID');
  const firebaseClientEmail = readEnv('FIREBASE_CLIENT_EMAIL');
  const firebasePrivateKey = readPrivateKey();

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: tokens, error } = await supabase
    .from('device_tokens')
    .select('token, platform')
    .eq('user_id', record.user_id)
    .eq('is_active', true);

  if (error != null) {
    return jsonResponse({ error: error.message }, 500);
  }

  const activeTokens = (tokens ?? []) as DeviceToken[];
  if (activeTokens.length === 0) {
    return jsonResponse({ delivered: 0, skipped: 'no_active_device_token' });
  }

  const accessToken = await getFirebaseAccessToken(
    firebaseClientEmail,
    firebasePrivateKey,
  );

  const results = await Promise.all(
    activeTokens.map((deviceToken) =>
      sendMessage(firebaseProjectId, accessToken, record, deviceToken),
    ),
  );

  const invalidTokens = results
    .filter((result) => !result.ok && shouldDeactivateToken(result))
    .map((result) => result.token);

  if (invalidTokens.length > 0) {
    await supabase
      .from('device_tokens')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
      })
      .in('token', invalidTokens);
  }

  return jsonResponse({
    delivered: results.filter((result) => result.ok).length,
    failed: results.filter((result) => !result.ok).length,
    deactivated: invalidTokens.length,
    results,
  });
});

function extractNotificationRecord(body: unknown): NotificationRecord | null {
  if (body == null || typeof body !== 'object') {
    return null;
  }

  const maybePayload = body as Record<string, unknown>;
  const candidate = (maybePayload.record ??
    maybePayload.new ??
    maybePayload) as Record<string, unknown>;

  if (
    typeof candidate.id !== 'string' ||
    typeof candidate.user_id !== 'string' ||
    typeof candidate.title !== 'string' ||
    typeof candidate.message !== 'string'
  ) {
    return null;
  }

  return {
    id: candidate.id,
    user_id: candidate.user_id,
    title: candidate.title,
    message: candidate.message,
    ticket_id: typeof candidate.ticket_id === 'string' ? candidate.ticket_id : null,
    notification_type: typeof candidate.notification_type === 'string'
      ? candidate.notification_type
      : 'ticket_activity',
    payload: isRecord(candidate.payload) ? candidate.payload : null,
  };
}

async function sendMessage(
  firebaseProjectId: string,
  accessToken: string,
  record: NotificationRecord,
  deviceToken: DeviceToken,
): Promise<DeliveryResult> {
  const data = buildMessageData(record);
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: deviceToken.token,
          notification: {
            title: record.title,
            body: record.message,
          },
          data,
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'ticketq_ticket_updates',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
              sound: 'default',
              default_vibrate_timings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
                'content-available': 1,
              },
            },
          },
        },
      }),
    },
  );

  return {
    token: deviceToken.token,
    ok: response.ok,
    status: response.status,
    response: await response.text(),
  };
}

function buildMessageData(record: NotificationRecord): Record<string, string> {
  const payload = record.payload ?? {};
  return {
    notificationId: record.id,
    notification_id: record.id,
    ticketId: record.ticket_id ?? '',
    ticket_id: record.ticket_id ?? '',
    type: record.notification_type ?? 'ticket_activity',
    route: record.ticket_id == null ? '/notifications' : `/tickets/${record.ticket_id}`,
    title: record.title,
    body: record.message,
    payload: JSON.stringify(payload),
  };
}

async function getFirebaseAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const unsignedJwt = `${base64Url(JSON.stringify(header))}.${base64Url(
    JSON.stringify(claimSet),
  )}`;
  const key = await importPrivateKey(privateKey);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(unsignedJwt),
  );
  const assertion = `${unsignedJwt}.${base64Url(signature)}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`firebase_oauth_failed: ${await response.text()}`);
  }

  const tokenResponse = await response.json() as { access_token?: string };
  if (tokenResponse.access_token == null) {
    throw new Error('firebase_oauth_missing_access_token');
  }
  return tokenResponse.access_token;
}

async function importPrivateKey(privateKey: string): Promise<CryptoKey> {
  const pemBody = privateKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replaceAll('\n', '')
    .replaceAll('\r', '')
    .trim();
  const binaryDer = Uint8Array.from(atob(pemBody), (char) => char.charCodeAt(0));

  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );
}

function base64Url(value: string | ArrayBuffer): string {
  const bytes = typeof value === 'string'
    ? encoder.encode(value)
    : new Uint8Array(value);
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}

function shouldDeactivateToken(result: DeliveryResult): boolean {
  return result.status === 404 ||
    result.response.includes('UNREGISTERED') ||
    result.response.includes('registration-token-not-registered') ||
    result.response.includes('INVALID_ARGUMENT');
}

function readEnv(name: string): string {
  const value = Deno.env.get(name)?.trim() ?? '';
  if (value.length === 0) {
    throw new Error(`missing_env:${name}`);
  }
  return value;
}

function readPrivateKey(): string {
  const base64Value = Deno.env.get('FIREBASE_PRIVATE_KEY_BASE64')?.trim();
  if (base64Value != null && base64Value.isNotEmpty) {
    return atob(base64Value);
  }

  return readEnv('FIREBASE_PRIVATE_KEY').replaceAll('\\n', '\n');
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

declare global {
  interface String {
    readonly isNotEmpty: boolean;
  }
}

Object.defineProperty(String.prototype, 'isNotEmpty', {
  get() {
    return this.length > 0;
  },
});
