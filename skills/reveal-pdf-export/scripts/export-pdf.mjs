#!/usr/bin/env node
/**
 * export-pdf.mjs — Export a Reveal.js presentation to PDF via Chrome CDP.
 *
 * Usage:
 *   node export-pdf.mjs [presentation.html] [output.pdf]
 *
 * Defaults:
 *   input  = presentation.html  (in the same directory as the script)
 *   output = <input-basename>.pdf
 *
 * Requirements: Node 22+, Google Chrome installed at the default macOS path.
 * Chrome path can be overridden with the CHROME env variable.
 *
 * Page size: 1280×720px (16:9). Override with WIDTH / HEIGHT env vars (px).
 */

import { spawn }       from 'child_process';
import { createServer } from 'http';
import { readFileSync, writeFileSync } from 'fs';
import path            from 'path';

// ── Config ────────────────────────────────────────────────────────────────────
const [,, inputArg, outputArg] = process.argv;
const INPUT     = path.resolve(inputArg ?? 'presentation.html');
const DIR       = path.dirname(INPUT);
const BASENAME  = path.basename(INPUT, path.extname(INPUT));
const OUTPUT    = path.resolve(outputArg ?? path.join(DIR, `${BASENAME}.pdf`));

const WIDTH_PX  = Number(process.env.WIDTH  ?? 1280);
const HEIGHT_PX = Number(process.env.HEIGHT ?? 720);
const PAPER_W   = WIDTH_PX  / 96;   // inches at 96 dpi
const PAPER_H   = HEIGHT_PX / 96;

const HTTP_PORT = 8766;
const CDP_PORT  = 9223;
const CHROME    = process.env.CHROME ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const URL = `http://localhost:${HTTP_PORT}/${path.basename(INPUT)}?print-pdf`;

// ── 1. HTTP server ────────────────────────────────────────────────────────────
const httpServer = await new Promise((resolve) => {
  const server = createServer((req, res) => {
    const filePath = path.join(DIR, req.url.split('?')[0]);
    try {
      const data = readFileSync(filePath);
      const ext  = path.extname(filePath).slice(1);
      const mime = {
        html: 'text/html', css: 'text/css', js: 'application/javascript',
        mjs: 'application/javascript', jpg: 'image/jpeg', jpeg: 'image/jpeg',
        png: 'image/png', svg: 'image/svg+xml', woff2: 'font/woff2',
      }[ext] ?? 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      res.end(data);
    } catch { res.writeHead(404); res.end(); }
  });
  server.listen(HTTP_PORT, () => {
    console.log(`HTTP  :${HTTP_PORT}`);
    resolve(server);
  });
});

// ── 2. Chrome ─────────────────────────────────────────────────────────────────
const chrome = spawn(CHROME,
  ['--headless=new', '--disable-gpu', '--no-sandbox',
   `--remote-debugging-port=${CDP_PORT}`]);
chrome.stderr.on('data', () => {});
await new Promise(r => setTimeout(r, 2000));

// ── 3. CDP setup ──────────────────────────────────────────────────────────────
const tab   = await fetch(`http://localhost:${CDP_PORT}/json/new`,
                          { method: 'PUT' }).then(r => r.json());
const ws    = new WebSocket(tab.webSocketDebuggerUrl);
let   msgId = 1;
const pending = new Map();

console.log(`WS    ${tab.webSocketDebuggerUrl}`);
await new Promise(r => ws.addEventListener('open', r));

ws.addEventListener('message', ({ data }) => {
  const msg = JSON.parse(data);
  if (msg.id && pending.has(msg.id)) pending.get(msg.id)(msg);
});

const send = (method, params = {}) => new Promise((resolve, reject) => {
  const id = msgId++;
  pending.set(id, msg => msg.error ? reject(msg.error) : resolve(msg.result));
  ws.send(JSON.stringify({ id, method, params }));
});

// ── 4. Navigate + wait for Reveal.js layout ───────────────────────────────────
await send('Page.enable');
await send('Page.navigate', { url: URL });
console.log('Waiting for Reveal.js layout…');
await new Promise(r => setTimeout(r, 7000));

// ── 5. Print ──────────────────────────────────────────────────────────────────
console.log('Printing…');
const { data } = await send('Page.printToPDF', {
  printBackground:     true,
  preferCSSPageSize:   true,
  paperWidth:          PAPER_W,
  paperHeight:         PAPER_H,
  marginTop:           0,
  marginBottom:        0,
  marginLeft:          0,
  marginRight:         0,
  displayHeaderFooter: false,
});

writeFileSync(OUTPUT, Buffer.from(data, 'base64'));
console.log(`Saved ${OUTPUT}`);

ws.close();
chrome.kill();
httpServer.close();
