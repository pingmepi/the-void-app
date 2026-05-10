# Selector Inventory

Every locator used in the Playwright suite. Each row is either **semantic**
(robust, identifier-based) or **fallback** (fragile, text-based). If any
fallback starts misfiring, promote it by adding an `e2eId(...)` wrapper at
the source site and swap the helper call.

## Identifier-based (robust)

Source of truth: `e2eId(...)` wrappers in Flutter source. DOM attribute is
`flt-semantics-identifier="<id>"` once `--dart-define=E2E=true` is in effect.

| ID | Widget / source | Used by |
|---|---|---|
| `mic_button_idle` | [lib/screens/void_screen.dart](../lib/screens/void_screen.dart) — AnimatedGlowingMicButton | smoke, navigation, voiding, edge |
| `mic_button_listening` | [lib/screens/void_screen.dart](../lib/screens/void_screen.dart) — GlowingMicButton | voiding |
| `gems_nav_button` | [lib/screens/void_screen.dart](../lib/screens/void_screen.dart) — top-right nav | smoke, navigation, auth, edge |
| `rescue_button` | [lib/widgets/void_timer_widget.dart](../lib/widgets/void_timer_widget.dart) — FilledButton | (not yet asserted — blocked on stubbed transcript) |
| `email_input` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | auth, edge |
| `password_input` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | auth, edge |
| `email_submit_button` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | auth, edge |
| `toggle_mode_button` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | auth, edge |
| `forgot_password_button` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | auth |
| `auth_error_message` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | (available, not yet asserted) |
| `auth_info_message` | [lib/widgets/email_auth_form.dart](../lib/widgets/email_auth_form.dart) | (available, not yet asserted) |
| `maybe_later_button` | [lib/screens/login_screen.dart](../lib/screens/login_screen.dart) | navigation |
| `no-model-open-settings` | [lib/widgets/no_offline_model_sheet.dart](../lib/widgets/no_offline_model_sheet.dart) — "Open settings" button | (available, not yet asserted) |
| `no-model-cancel` | [lib/widgets/no_offline_model_sheet.dart](../lib/widgets/no_offline_model_sheet.dart) — "Cancel" button | (available, not yet asserted) |
| `privacy-policy-link` | [lib/screens/auth_screen.dart](../lib/screens/auth_screen.dart) — pre-auth privacy link | (available, not yet asserted) |

## Text-based (fallback — brittle if copy changes)

Each entry says *why* no identifier was added. If any of these strings moves,
the corresponding spec breaks with a clear `element(s) not found` error —
easy to triage from the Playwright HTML report.

| Match | Where | Why no ID |
|---|---|---|
| `Maybe later` | navigation.spec (indirect via button) | Now `maybe_later_button`; text match removed |
| `Privacy Policy` | navigation.spec — LoginScreen footer | Low churn; link text is a product constant |
| `Sign in` / `Create account` | auth.spec — submit label | Testing the *label flip* itself, so text is load-bearing |
| `Email is required`, `Enter a valid email`, `At least 6 characters`, `Password is required` | auth.spec — validator messages | Testing validator output by design; these strings are the assertion |
| `Enter your email above first` | auth.spec — forgot-password guard | Same as above |
| `Invalid` | auth.spec — Supabase error passthrough | Server-produced string; we only check it appears, don't assert exact copy |
| `what remains` | voiding.spec — landing tagline | Product copy is stable-ish; low-priority assertion |

## Not yet tested (gaps)

These widgets are ready (identifier wired in source) but don't yet have
coverage, usually because the flow is blocked on something else.

| Widget | Blocker |
|---|---|
| `rescue_button` | Needs a stubbed or real transcript to reach COUNTDOWN — Playwright's fake audio produces silence. |
| `auth_error_message` / `auth_info_message` | Need Supabase creds wired in `.env.json` for meaningful end-to-end paths. |
| `account_button`, `sign_out_button`, `delete_account_button`, `confirm_delete_account_button` (on GemsScreen) | Require an authed session. Will come online once auth credential specs run. |
| `gem_title_display`, `privacy_policy_link`, `account_privacy_policy_link` | Present in source (`Key(...)`) but not wrapped with `e2eId` yet — do this lazily when a spec needs them. |

## Debugging a selector failure

1. Open `playwright-report/index.html`. Each failure has a DOM snapshot and
   screenshot attached.
2. If a selector is missing from the snapshot's `<flt-semantics>` tree, the
   widget either isn't rendered, isn't wrapped with `e2eId`, or the build
   didn't include `--dart-define=E2E=true`.
3. If a text-based fallback broke because copy changed, either update the
   string in the spec *or* promote the widget to an `e2eId` (preferred for
   anything the tests will touch repeatedly).
4. If semantics are missing entirely (`flt-semantics` count near 0), check
   that `E2E=true` made it through: `grep E2E build/web/main.dart.js` should
   show traces.
