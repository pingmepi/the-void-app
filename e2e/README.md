# The Void — End-to-End Tests

Playwright suite exercising the Flutter web build from a real browser.

## Quick start

```bash
# From repo root — one-time setup
cd e2e
npm install
npx playwright install chromium ffmpeg

# Run everything (builds the Flutter web app once, then runs specs)
npm test

# Watch mode (Playwright UI)
npm run test:ui

# Open the HTML report from the last run
npm run test:report
```

The Playwright `webServer` block automatically runs
`flutter build web --dart-define=E2E=true` and serves `build/web` on
`127.0.0.1:8080`. If you already have the build served elsewhere on that
port, set `reuseExistingServer: true` (default when not on CI).

## Why `--dart-define=E2E=true`

Flutter web renders to a canvas by default, leaving the DOM empty — Playwright
can't query pixels. In `E2E=true` builds, [lib/main.dart](../lib/main.dart)
calls `SemanticsBinding.ensureSemantics()`, which makes Flutter mirror the
widget tree into `<flt-semantics>` DOM nodes. Selectors in
[helpers/flutter.ts](helpers/flutter.ts) target those nodes.

Widgets that need a stable selector are wrapped with `e2eId('id', child)`
from [lib/widgets/e2e_id.dart](../lib/widgets/e2e_id.dart), which emits
`flt-semantics-identifier="id"` in the DOM. Zero visual or behavioral change.

## Credentials

| Var | Required for |
|---|---|
| `.env.json` → `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Anything Supabase-backed (auth credential specs) |
| `E2E_EMAIL`, `E2E_PASSWORD` | Auth credential happy-paths (passed via env or shell) |

If any are missing, the credential-dependent specs (`auth.spec.ts > credential flows`)
are auto-skipped with a `test.skip(...)` reason. Everything else still runs.

Email sign-up in Supabase: turn **Confirm email OFF** in the dashboard for
the project under test, otherwise the sign-up spec won't get an active
session.

## Layout

```
e2e/
  playwright.config.ts   # webServer + browser/permissions setup
  helpers/
    flutter.ts           # byId / byText / fillField / waitForFlutter
    env.ts               # credential loading
    supabase.ts          # REST helpers for cleanup
  tests/
    smoke.spec.ts        # semantics sanity
    navigation.spec.ts   # screen transitions
    auth.spec.ts         # email/password form, validation, credential flows
    voiding.spec.ts      # mic button state transitions
    edge.spec.ts         # small viewports, reload, rapid input
  SELECTORS.md           # inventory + fragility notes
```

## Coverage gaps (on purpose)

- **Full voiding flow** (LISTENING → COUNTDOWN → VOIDED / SAVED). Playwright's
  `--use-fake-device-for-media-stream` produces silent audio, so the browser's
  SpeechRecognition API never emits results and the app stays in LISTENING.
  Testing the rest requires either a test-only hook into `VoidController` to
  stub a transcript, or migrating those flows to Flutter's `integration_test`.
- **Google / Apple OAuth**. Needs real provider accounts and popup handling.
- **Audio playback of saved gems** — depends on authenticated gems, so blocked
  on the same creds gap.

See [SELECTORS.md](SELECTORS.md) for a per-element map of what's queryable.
