import { test, expect } from '@playwright/test';
import { waitForFlutter, byId } from '../helpers/flutter';

test.describe('smoke', () => {
  test('app boots with semantics enabled', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  test('idle mic button is identified', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await expect(byId(page, 'mic_button_idle')).toBeAttached({
      timeout: 15_000,
    });
  });

  test('gems nav button is identified', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await expect(byId(page, 'gems_nav_button')).toBeAttached({
      timeout: 15_000,
    });
  });
});
