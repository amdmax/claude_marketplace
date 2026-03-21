---
name: ios:mobile-test
version: 1.0.0
description: |
  Run, add, or debug iOS (webkit) mobile layout tests for the aigensa landing page.
  Uses raw playwright + Jest (jest project: mobile). Trigger when the user wants to
  run mobile tests, add a new page test for iOS, or debug a webkit test failure.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# iOS Mobile Test Skill

Stack: `playwright` (raw) + Jest. Test files live in `tests/playwright/*.mobile.test.ts`.
Device: WebKit (Safari engine) simulating iPhone 17 Pro.

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

## Device config (`tests/playwright/device.ts`)

```typescript
export const IPHONE_17_PRO = {
  name: 'iPhone 17 Pro',
  width: 393,
  height: 852,
  deviceScaleFactor: 3,
  isMobile: true,
  hasTouch: true,
};
```

## Step-by-step: Add a new page test

1. Create `tests/playwright/<page-name>.mobile.test.ts`
2. Use this template:

```typescript
/** @jest-environment node */
import { webkit, Browser, BrowserContext, Page } from 'playwright';
import { spawn, ChildProcess } from 'child_process';
import { IPHONE_17_PRO } from './device';

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
  browser = await webkit.launch({ headless: true });
  context = await browser.newContext({
    viewport: { width: IPHONE_17_PRO.width, height: IPHONE_17_PRO.height },
    deviceScaleFactor: IPHONE_17_PRO.deviceScaleFactor,
    isMobile: IPHONE_17_PRO.isMobile,
    hasTouch: IPHONE_17_PRO.hasTouch,
  });
  page = await context.newPage();
});

afterAll(async () => {
  await context?.close();
  await browser?.close();
  server?.kill();
});

describe('<Page name> — mobile layout', () => {
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
      path: `tests/playwright/screenshots/<page-name>-${IPHONE_17_PRO.name.replace(/\s/g, '-').toLowerCase()}.png`,
      fullPage: true,
    });
  });
});
```

3. Run `npm run test:playwright` to verify.

## Screenshots

Screenshots are saved to `tests/playwright/screenshots/` (gitignored). Safe to write during test runs.

## Debugging tips

- If the server fails to start: check port 8001 is free (`lsof -ti :8001 | xargs kill -9 || true`)
- If webkit is missing: run `npx playwright install webkit`
- Timeout errors usually mean `dist/` is stale — re-run `npm run build:astro`
