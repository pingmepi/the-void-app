import { test, expect } from '@playwright/test';
import { byId, byTextContains, waitForFlutter } from '../helpers/flutter';

test.describe('navigation', () => {
  test('tapping gems nav when signed out opens LoginScreen', async ({
    page,
  }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await byId(page, 'gems_nav_button').click({ force: true });

    // LoginScreen renders the wordmark "THE VOID" and a "Maybe later" button.
    await expect(byTextContains(page, 'Maybe later')).toBeVisible({
      timeout: 10_000,
    });
  });

  test('"Maybe later" dismisses LoginScreen back to VoidScreen', async ({
    page,
  }) => {
    await page.goto('/');
    await waitForFlutter(page);

    await byId(page, 'gems_nav_button').click({ force: true });
    await expect(byId(page, 'email_input')).toBeAttached({ timeout: 10_000 });

    // "Maybe later" may be below the fold — scroll into view, then click.
    const maybeLater = byId(page, 'maybe_later_button');
    await maybeLater.scrollIntoViewIfNeeded();
    await maybeLater.click({ force: true });

    // Back on VoidScreen — mic button (idle) is present.
    await expect(byId(page, 'mic_button_idle')).toBeAttached({
      timeout: 10_000,
    });
  });

  test('privacy policy link is present on LoginScreen', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await byId(page, 'gems_nav_button').click({ force: true });
    await expect(byTextContains(page, 'Privacy Policy')).toBeVisible({
      timeout: 10_000,
    });
  });
});
