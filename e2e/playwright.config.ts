import { defineConfig, devices } from '@playwright/test';
import { existsSync } from 'node:fs';
import path from 'node:path';

const APP_DIR = path.resolve(__dirname, '..');
const ENV_FILE = path.join(APP_DIR, '.env.json');
const PORT = Number(process.env.E2E_PORT ?? 8080);
const BASE_URL = `http://127.0.0.1:${PORT}`;

if (!existsSync(ENV_FILE)) {
  console.warn(
    `[e2e] ${ENV_FILE} not found — auth-dependent specs will skip.`,
  );
}

export default defineConfig({
  testDir: './tests',
  fullyParallel: false, // Flutter web + Supabase shared state — serialize
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
    ['list'],
  ],
  timeout: 60_000,
  expect: { timeout: 10_000 },
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
    // Flutter semantics render to DOM only in E2E=true builds; the URL is
    // a static-file host, so hash/path-based nav is handled by the app.
    permissions: ['microphone'],
    launchOptions: {
      args: [
        '--use-fake-ui-for-media-stream',
        '--use-fake-device-for-media-stream',
        '--autoplay-policy=no-user-gesture-required',
      ],
    },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    // Build the web app once, then serve the static output. The release build
    // is much faster to load per-test than `flutter run -d web-server` (which
    // compiles lazily on first request). E2E=true enables the semantics tree;
    // Supabase creds are injected from .env.json if present.
    command: [
      'cd ..',
      existsSync(ENV_FILE)
        ? 'flutter build web --dart-define-from-file=.env.json --dart-define=E2E=true'
        : 'flutter build web --dart-define=E2E=true',
      `python3 -m http.server ${PORT} --bind 127.0.0.1 --directory build/web`,
    ].join(' && '),
    url: BASE_URL,
    reuseExistingServer: !process.env.CI,
    timeout: 300_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
