import { test, expect } from '@playwright/test';
import { byId, byTextContains, waitForFlutter } from '../helpers/flutter';

/**
 * Voiding flow: IDLE → LISTENING → TRANSCRIBING → COUNTDOWN → VOIDED | SAVED.
 *
 * Playwright's fake media stream produces silent audio, so the browser's
 * SpeechRecognition never emits results and the app won't naturally reach
 * COUNTDOWN. These specs therefore cover only the user-visible affordances
 * that don't depend on real speech-to-text output:
 *
 *   - idle mic button is tappable and triggers the listening UI
 *   - mic button in listening state is tappable (stops recording)
 *   - going idle → listening → idle leaves the app in a navigable state
 *
 * Further states (countdown, rescue, voided, saved) require either a real
 * transcript or a test-only hook into the state machine. Flagged as TODO
 * in e2e/SELECTORS.md.
 */
test.describe('voiding — UI transitions', () => {
  test('tapping idle mic shows the listening-state mic button', async ({
    page,
  }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await byId(page, 'mic_button_idle').click({ force: true });

    await expect(byId(page, 'mic_button_listening')).toBeAttached({
      timeout: 10_000,
    });
  });

  test('tapping listening mic is accepted (no crash)', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await byId(page, 'mic_button_idle').click({ force: true });
    await expect(byId(page, 'mic_button_listening')).toBeAttached({
      timeout: 10_000,
    });

    // Clicking the listening mic invokes stopRecording. In a real session this
    // feeds the transcript into the state machine; under Playwright's fake
    // audio pipeline SpeechRecognition never emits results, so the app may
    // remain in LISTENING / TRANSCRIBING. We only verify the click doesn't
    // crash the page (semantics tree still populated).
    await byId(page, 'mic_button_listening').click({ force: true });

    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  test('landing tagline is visible on first load', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    // VoidScreen landing tagline at bottom: "LISTEN TO THE / what remains."
    await expect(byTextContains(page, 'what remains')).toBeVisible({
      timeout: 10_000,
    });
  });
});
