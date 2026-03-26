---
name: android:mobile-test
version: 1.0.0
description: |
  Run, add, or debug Android (chromium) mobile layout tests for the aigensa landing page.
  Uses raw playwright + Jest (jest project: mobile). Trigger when the user wants to
  run mobile tests on Android/Pixel, add a new page test, or debug a chromium test failure.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# Android Mobile Test Skill

Stack: `playwright` (raw) + Jest. Test files live in `tests/playwright/*.mobile.test.ts`.
Device: Chromium simulating a Pixel 8 (Android).

## Commands that WORK

```bash
# Run all mobile tests
npm run test:playwright

# Run all mobile tests with verbose output
npm run test:playwright:report

# Run a single test file (e.g. home page only)
jest --selectProjects mobile --testPathPattern=home
```

## Commands that do NOT work

| Command | Why it fails |
|---------|-------------|
| `npx playwright test` | `@playwright/test` runner is NOT installed; only the raw `playwright` package is |
| `import { test } from '@playwright/test'` | Wrong import — tests use `playwright` directly |
| Running with multiple workers | Port 8001 conflicts; `maxWorkers: 1` is enforced in `jest.config.ts` |

## Pre-requisite

`dist/` must exist before running tests. If missing:

```bash
npm run build:astro
```

## Step-by-step: Run existing tests

```bash
npm run build:astro          # build site into dist/
npm run test:playwright      # run all mobile tests
```

## Device config

Add the Pixel 8 device to `tests/playwright/device.ts`:

```typescript
export const PIXEL_8 = {
  name: 'Pixel 8',
  width: 412,
  height: 915,
  deviceScaleFactor: 2.625,
  isMobile: true,
  hasTouch: true,
};
```

Note: `IPHONE_17_PRO` (webkit) is already in `device.ts`. Add `PIXEL_8` alongside it.

## Step-by-step: Add a new page test

1. Add `PIXEL_8` to `tests/playwright/device.ts` if not already present (see above)
2. Create `tests/playwright/<page-name>.android.mobile.test.ts`
3. Use this template:

```typescript
/** @jest-environment node */
import { chromium, Browser, BrowserContext, Page } from 'playwright';
import { spawn, ChildProcess } from 'child_process';
import { PIXEL_8 } from './device';

jest.setTimeout(60000);

const BASE_URL = 'http://127.0.0.1:8001';
let server: ChildProcess | null = null;
let browser: Browser;
let context: BrowserContext;
let page: Page;

beforeAll(async () => {
  await new Promise<void>((resolve, reject) => {
    server = spawn('npx', ['http-server', 'dist', '-p', '8001', '-c-1', '--silent'], {
      stdio: 'pipe',
    });
    server.on('error', (err) => reject(err));
    setTimeout(resolve, 2000);
  });
  browser = await chromium.launch({ headless: true });
  context = await browser.newContext({
    viewport: { width: PIXEL_8.width, height: PIXEL_8.height },
    deviceScaleFactor: PIXEL_8.deviceScaleFactor,
    isMobile: PIXEL_8.isMobile,
    hasTouch: PIXEL_8.hasTouch,
  });
  page = await context.newPage();
});

afterAll(async () => {
  await context?.close();
  await browser?.close();
  server?.kill();
});

describe('<Page name> — Android mobile layout', () => {
  beforeEach(async () => {
    await page.goto(`${BASE_URL}/en/<path>`, { waitUntil: 'networkidle' });
  });

  it('page loads — h1 visible', async () => {
    expect(await page.locator('h1').isVisible()).toBe(true);
  });

  it('no horizontal overflow', async () => {
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth
    );
    expect(overflow).toBe(true);
  });

  it('screenshot', async () => {
    await page.screenshot({
      path: `tests/playwright/screenshots/<page-name>-${PIXEL_8.name.replace(/\s/g, '-').toLowerCase()}.png`,
      fullPage: true,
    });
  });
});
```

4. Run `npm run test:playwright` to verify.

## Key difference vs iOS

| | iOS | Android |
|--|-----|---------|
| Browser engine | `webkit` | `chromium` |
| Import | `import { webkit } from 'playwright'` | `import { chromium } from 'playwright'` |
| Device config | `IPHONE_17_PRO` (already in `device.ts`) | `PIXEL_8` (add to `device.ts`) |
| File naming | `*.mobile.test.ts` | `*.android.mobile.test.ts` (convention) |

## Screenshots

Screenshots are saved to `tests/playwright/screenshots/` (gitignored). Safe to write during test runs.

## Debugging tips

- If the server fails to start: check port 8001 is free (`lsof -ti :8001 | xargs kill -9 || true`)
- If chromium is missing: run `npx playwright install chromium`
- Timeout errors usually mean `dist/` is stale — re-run `npm run build:astro`
- Both iOS and Android tests share port 8001 — run them in the same `jest --selectProjects mobile` call, not separately in parallel
