import dotenv from 'dotenv';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(__dirname, '..', '..');

dotenv.config({ path: path.join(__dirname, '..', '.env'), quiet: true });

type SupabaseEnv = {
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
};

function readSupabaseEnv(): SupabaseEnv {
  const envJson = path.join(ROOT, '.env.json');
  if (!existsSync(envJson)) return {};
  try {
    const parsed = JSON.parse(readFileSync(envJson, 'utf-8'));
    return {
      SUPABASE_URL: parsed.SUPABASE_URL,
      SUPABASE_ANON_KEY: parsed.SUPABASE_ANON_KEY,
    };
  } catch {
    return {};
  }
}

const supa = readSupabaseEnv();

export const E2E_EMAIL = process.env.E2E_EMAIL ?? '';
export const E2E_PASSWORD = process.env.E2E_PASSWORD ?? '';
export const SUPABASE_URL = supa.SUPABASE_URL ?? '';
export const SUPABASE_ANON_KEY = supa.SUPABASE_ANON_KEY ?? '';

export const hasAuthCreds = Boolean(
  E2E_EMAIL && E2E_PASSWORD && SUPABASE_URL && SUPABASE_ANON_KEY,
);

export function uniqueEmail(prefix = 'e2e') {
  const stamp = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 7);
  const domain = process.env.E2E_EMAIL_DOMAIN ?? 'void-e2e.test';
  return `${prefix}+${stamp}${rand}@${domain}`;
}
