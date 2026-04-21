import { test, expect } from '@playwright/test';
import {
  byId,
  byTextContains,
  fillField,
  waitForFlutter,
} from '../helpers/flutter';
import { hasAuthCreds, uniqueEmail } from '../helpers/env';

async function openLogin(page: import('@playwright/test').Page) {
  await page.goto('/');
  await waitForFlutter(page);
  await byId(page, 'gems_nav_button').click({ force: true });
  await expect(byId(page, 'email_input')).toBeAttached({ timeout: 10_000 });
}

test.describe('auth form — rendering & mode toggle', () => {
  test('sign-in mode shows email, password, and forgot link', async ({
    page,
  }) => {
    await openLogin(page);

    await expect(byId(page, 'email_input')).toBeAttached();
    await expect(byId(page, 'password_input')).toBeAttached();
    await expect(byId(page, 'email_submit_button')).toBeAttached();
    await expect(byId(page, 'toggle_mode_button')).toBeAttached();
    await expect(byId(page, 'forgot_password_button')).toBeAttached();

    // Submit label reads "Sign in" in sign-in mode.
    await expect(byTextContains(page, 'Sign in')).toBeVisible({
      timeout: 5_000,
    });
  });

  test('toggling mode hides forgot-password and relabels submit', async ({
    page,
  }) => {
    await openLogin(page);

    await byId(page, 'toggle_mode_button').click({ force: true });

    // Sign-up mode: submit now says "Create account"; forgot link goes away.
    await expect(byTextContains(page, 'Create account')).toBeVisible({
      timeout: 5_000,
    });
    await expect(byId(page, 'forgot_password_button')).toHaveCount(0);
  });
});

test.describe('auth form — validation', () => {
  test('empty submit shows validation errors', async ({ page }) => {
    await openLogin(page);

    await byId(page, 'email_submit_button').click({ force: true });

    // Flutter renders validator errors below each field.
    await expect(byTextContains(page, 'Email is required')).toBeVisible({
      timeout: 5_000,
    });
    await expect(byTextContains(page, 'Password is required')).toBeVisible({
      timeout: 5_000,
    });
  });

  test('invalid email format is rejected', async ({ page }) => {
    await openLogin(page);

    await fillField(page, 'email_input', 'not-an-email');
    await fillField(page, 'password_input', 'validpass123');
    await byId(page, 'email_submit_button').click({ force: true });

    await expect(byTextContains(page, 'Enter a valid email')).toBeVisible({
      timeout: 5_000,
    });
  });

  test('short password is rejected', async ({ page }) => {
    await openLogin(page);

    await fillField(page, 'email_input', 'ok@example.com');
    await fillField(page, 'password_input', '123');
    await byId(page, 'email_submit_button').click({ force: true });

    await expect(byTextContains(page, 'At least 6 characters')).toBeVisible({
      timeout: 5_000,
    });
  });

  test('forgot-password without email prompts for email first', async ({
    page,
  }) => {
    await openLogin(page);

    await byId(page, 'forgot_password_button').click({ force: true });

    await expect(
      byTextContains(page, 'Enter your email above first'),
    ).toBeVisible({ timeout: 5_000 });
  });
});

test.describe('auth form — credential flows', () => {
  test.skip(
    !hasAuthCreds,
    'Requires SUPABASE_URL, SUPABASE_ANON_KEY, E2E_EMAIL, E2E_PASSWORD',
  );

  test('wrong credentials surface an auth error', async ({ page }) => {
    await openLogin(page);

    await fillField(page, 'email_input', 'definitely-not-a-real-user@void-e2e.test');
    await fillField(page, 'password_input', 'wrong-password-xyz');
    await byId(page, 'email_submit_button').click({ force: true });

    // Supabase returns "Invalid login credentials" for bad sign-in. We just
    // check that *any* error surfaces within the form's error slot.
    await expect(
      byTextContains(page, 'Invalid'),
    ).toBeVisible({ timeout: 15_000 });
  });

  test('sign-up with a fresh email logs the user in', async ({ page }) => {
    await openLogin(page);

    const email = uniqueEmail();
    const password = 'e2e-test-password-123';

    await byId(page, 'toggle_mode_button').click({ force: true });
    await fillField(page, 'email_input', email);
    await fillField(page, 'password_input', password);
    await byId(page, 'email_submit_button').click({ force: true });

    // On successful sign-up the LoginScreen pops and the GemsScreen (or
    // VoidScreen) is shown. Either way the email input should be gone.
    await expect(byId(page, 'email_input')).toHaveCount(0, {
      timeout: 20_000,
    });
  });
});
