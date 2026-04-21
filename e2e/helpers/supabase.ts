import { SUPABASE_URL, SUPABASE_ANON_KEY } from './env';

/**
 * Minimal REST helpers against Supabase GoTrue. Keeps the test harness from
 * pulling in the full supabase-js client.
 */

export async function supabaseSignUp(email: string, password: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`signUp failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function supabaseDeleteViaPassword(email: string, password: string) {
  // Best-effort: sign in to get a token, then invoke the delete-account fn.
  const tokenRes = await fetch(
    `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
    {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    },
  );
  if (!tokenRes.ok) return; // best-effort cleanup
  const { access_token } = await tokenRes.json();
  await fetch(`${SUPABASE_URL}/functions/v1/delete-account`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${access_token}`,
    },
  });
}
