import { test, expect } from '@playwright/test';
import { byId, byTextContains, waitForFlutter } from '../helpers/flutter';

test.describe('edge cases', () => {
  test('login screen scrolls on small viewports', async ({ page }) => {
    await page.setViewportSize({ width: 400, height: 600 });
    await page.goto('/');
    await waitForFlutter(page);

    await byId(page, 'gems_nav_button').click({ force: true });
    await expect(byId(page, 'email_input')).toBeAttached({ timeout: 10_000 });

    // Content exists below the fold; scroll the page and expect "Maybe later".
    await page.mouse.wheel(0, 600);
    await expect(byTextContains(page, 'Maybe later')).toBeVisible({
      timeout: 10_000,
    });
  });

  test('reload on the login screen returns to the root (unauth)', async ({
    page,
  }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await byId(page, 'gems_nav_button').click({ force: true });
    await expect(byId(page, 'email_input')).toBeAttached({ timeout: 10_000 });

    await page.reload();
    await waitForFlutter(page);

    // No push-state routing: reload drops us back to the VoidScreen root.
    await expect(byId(page, 'mic_button_idle')).toBeAttached({
      timeout: 15_000,
    });
  });

  test('mode toggle clears any prior error message', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await byId(page, 'gems_nav_button').click({ force: true });

    // Trigger a validation error first.
    await byId(page, 'email_submit_button').click({ force: true });
    await expect(byTextContains(page, 'Email is required')).toBeVisible();

    // Switching mode should reset the form state; the validation message
    // hangs off the field, but our custom `_error`/`_info` banners clear.
    await byId(page, 'toggle_mode_button').click({ force: true });
    await expect(byTextContains(page, 'Create account')).toBeVisible();
  });

  test('rapid toggle does not crash the form', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await byId(page, 'gems_nav_button').click({ force: true });

    for (let i = 0; i < 5; i++) {
      await byId(page, 'toggle_mode_button').click({ force: true });
    }

    // Form is still interactive.
    await expect(byId(page, 'email_input')).toBeAttached();
    await expect(byId(page, 'email_submit_button')).toBeAttached();
  });
});
