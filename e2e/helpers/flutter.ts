import { expect, Locator, Page } from '@playwright/test';

/**
 * Flutter web renders to a canvas by default. With E2E=true the app calls
 * SemanticsBinding.ensureSemantics(), emitting a DOM semantics tree under
 * `<flt-semantics-host>`. Selectors below target that tree.
 *
 * Stability note: `Key('foo')` in Flutter surfaces in semantics as an element
 * with a matching `id` OR as a labelled node. We use a resilient query that
 * looks up the tree by `flt-semantics-identifier`, `id`, and label text.
 */

export async function waitForFlutter(page: Page) {
  // Flutter boots when <flt-glass-pane> is attached. It's styled as a 0-opacity
  // pointer-events:none element, so we wait for "attached", not "visible".
  await page.waitForSelector('flt-glass-pane', {
    state: 'attached',
    timeout: 60_000,
  });
  // Wait for the semantics host to render at least one labelled node. If this
  // never appears, the app didn't enable semantics — fail fast.
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics').length > 1,
    null,
    { timeout: 30_000 },
  );
}

/**
 * Locate a Flutter widget by its `Semantics(identifier: '<id>')` value.
 * The identifier surfaces on the DOM node as `flt-semantics-identifier`.
 * In this codebase that comes from the `e2eId(...)` wrapper (lib/widgets/e2e_id.dart).
 */
export function byId(page: Page, id: string): Locator {
  return page.locator(`flt-semantics[flt-semantics-identifier="${id}"]`);
}

/**
 * Tap target inside an identified wrapper. `e2eId` uses `explicitChildNodes`,
 * so the wrapper is a parent and the tappable child (e.g. button) is nested.
 */
export function tappableInside(page: Page, id: string): Locator {
  return page.locator(
    `flt-semantics[flt-semantics-identifier="${id}"] [flt-tappable], ` +
      `flt-semantics[flt-semantics-identifier="${id}"][flt-tappable]`,
  ).first();
}

/** Locate any semantics node whose text span content includes `text`. */
export function byText(page: Page, text: string): Locator {
  return page.locator(`flt-semantics:has(span:text-is("${text}"))`).first();
}

/** Partial match against semantics span text. */
export function byTextContains(page: Page, text: string): Locator {
  return page.locator(`flt-semantics:has-text("${text}")`).first();
}

/** Click a locator after waiting for it to be attached. */
export async function tap(locator: Locator) {
  await locator.waitFor({ state: 'attached', timeout: 10_000 });
  await locator.click({ force: true });
}

/**
 * Fill a Flutter TextField by its `e2eId`. Flutter web renders the text editor
 * into a host element that accepts keyboard input — we click to focus, clear,
 * then type.
 */
export async function fillField(page: Page, id: string, value: string) {
  const field = byId(page, id);
  await field.waitFor({ state: 'attached', timeout: 10_000 });
  await field.click({ force: true });
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.press('Delete');
  await page.keyboard.type(value, { delay: 15 });
}

export { expect };
