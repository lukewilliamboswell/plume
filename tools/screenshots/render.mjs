import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir, readdir, copyFile, rm } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { chromium } from 'playwright';
import { compareImages, checkInventory } from './compare.mjs';
import { classifyValidation } from './validation.mjs';

const require = createRequire(import.meta.url);
const update = process.argv.slice(2).join(' ') === '--update';
assert.ok(process.argv.length === 2 || update, 'Use no arguments to check, or --update to refresh reviewed images');
assert.equal(process.platform, 'linux', 'Run through the pinned Docker environment');
assert.equal(process.arch, 'x64', 'Run the screenshot environment with --platform linux/amd64');
const output = '/output';
const baselines = '/baselines';
const report = { format: 'plume-screenshots/1', mode: update ? 'update' : 'check', results: [] };
let browser;

try {
  const dockerfile = await readFile('/workspace/tools/screenshots/Dockerfile', 'utf8');
  const imageVersion = dockerfile.match(/FROM mcr\.microsoft\.com\/playwright:v([\d.]+)-noble@sha256:[a-f0-9]{64}/)?.[1];
  assert.equal(require('playwright/package.json').version, imageVersion, 'Playwright package and browser image versions must match');
  const manifest = JSON.parse(await readFile(`${output}/manifest.json`, 'utf8'));
  assert.equal(manifest.format, 'plume-screenshot-inputs/1');
  assert.ok(manifest.examples.every(example => /^[a-z0-9][a-z0-9-]*$/.test(example.name)));
  const readme = await readFile('/workspace/README.md', 'utf8');
  const gallery = [...new Set([...readme.matchAll(/examples\/demo-images\/([a-z0-9-]+\.png)/g)].map(match => match[1]))];
  checkInventory({
    names: manifest.examples.map(example => example.name),
    baselines: (await readdir(baselines)).filter(name => name.endsWith('.png')),
    gallery,
    update,
  });
  for (const folder of ['expected', 'actual', 'diff']) {
    await rm(`${output}/${folder}`, { recursive: true, force: true });
    await mkdir(`${output}/${folder}`, { recursive: true });
  }

  // Download only the asset named by the current generated HTML. Browser route
  // fulfilment uses these exact bytes; the document's SRI check remains active.
  const assets = new Map();
  for (const example of manifest.examples) {
    const html = await readFile(`${output}/html/${example.name}.html`, 'utf8');
    const scripts = [...html.matchAll(/<script\s+src="(https:\/\/cdn\.plot\.ly\/plotly-([\d.]+)\.min\.js)"\s+integrity="(sha384-[A-Za-z0-9+/=]+)"\s+crossorigin="anonymous"><\/script>/g)];
    assert.equal(scripts.length, 1, `${example.name}: expected one versioned Plotly script with SRI`);
    const [, url, version, integrity] = scripts[0];
    if (!assets.has(url)) {
      const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
      assert.ok(response.ok, `${url}: HTTP ${response.status}`);
      const bytes = Buffer.from(await response.arrayBuffer());
      assert.equal(`sha384-${createHash('sha384').update(bytes).digest('base64')}`, integrity, `${url}: SRI mismatch`);
      assets.set(url, { bytes, version });
    }
    example.renderer = { url, version };
  }

  browser = await chromium.launch({
    headless: true,
    args: ['--disable-gpu', '--font-render-hinting=none', '--disable-lcd-text'],
  });
  report.browser = browser.version();
  report.viewport = { width: 960, height: 540, device_scale_factor: 1 };
  for (const [index, example] of manifest.examples.entries()) {
    console.log(`[${index + 1}/${manifest.examples.length}] render ${example.name}`);
    const context = await browser.newContext({
      viewport: { width: 960, height: 540 }, deviceScaleFactor: 1,
      locale: 'en-US', timezoneId: 'UTC', colorScheme: 'light', reducedMotion: 'reduce',
      serviceWorkers: 'block',
    });
    const errors = [];
    const page = await context.newPage();
    page.setDefaultTimeout(30_000);
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('requestfailed', request => errors.push(`${request.url()}: ${request.failure()?.errorText}`));
    await context.route('**/*', async route => {
      const url = route.request().url();
      if (url === example.renderer.url) {
        await route.fulfill({ body: assets.get(url).bytes, contentType: 'application/javascript', headers: { 'access-control-allow-origin': '*' } });
      } else if (url === `file:///output/html/${example.name}.html`) {
        await route.continue();
      } else {
        errors.push(`Unexpected network request: ${url}`);
        await route.abort();
      }
    });
    await page.addInitScript(() => {
      Object.defineProperty(window, 'Plotly', {
        configurable: true,
        set(value) {
          Object.defineProperty(window, 'Plotly', { value, writable: true, configurable: true });
          const newPlot = value.newPlot;
          value.newPlot = function (...args) {
            window.__plumePlot = Promise.resolve(newPlot.apply(this, args));
            return window.__plumePlot;
          };
        },
      });
    });
    try {
      await page.goto(`file:///output/html/${example.name}.html`, { waitUntil: 'load' });
      await page.waitForFunction(() => Boolean(window.__plumePlot));
      const observed = await page.evaluate(async version => {
        await Promise.race([
          (async () => { await window.__plumePlot; await document.fonts.ready; })(),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Plot/font completion deadline exceeded')), 30_000)),
        ]);
        if (Plotly.version !== version) throw new Error(`Wrong renderer: ${Plotly.version}`);
        const figure = JSON.parse(document.getElementById('chartData').textContent);
        const problems = Plotly.validate(figure.data, figure.layout);
        const chart = document.getElementById('chart');
        if (!chart._fullLayout || chart._fullData.length !== figure.data.length || !chart.querySelector('.main-svg')) {
          throw new Error('Plotly did not finish rendering the current figure');
        }
        await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
        return { figure, problems };
      }, example.renderer.version);
      const validation = classifyValidation(observed.figure, observed.problems);
      assert.equal(validation.fatal.length, 0, `Plotly schema: ${JSON.stringify(validation.fatal)}`);
      await page.mouse.move(0, 0);
      const screenshot = () => page.locator('#chart').screenshot({ animations: 'disabled', caret: 'hide', scale: 'css' });
      const first = await screenshot();
      const actual = await screenshot();
      assert.equal(compareImages(first, actual).changed, 0, 'Plot still changes after completion and fonts are ready');
      assert.deepEqual(errors, [], 'Browser errors are never accepted as a screenshot');
      await writeFile(`${output}/actual/${example.name}.png`, actual);
      const baseline = `${baselines}/${example.name}.png`;
      let changed = null;
      if (!update) {
        const expected = await readFile(baseline);
        await copyFile(baseline, `${output}/expected/${example.name}.png`);
        const comparison = compareImages(expected, actual);
        changed = comparison.changed;
        if (changed) {
          await writeFile(`${output}/diff/${example.name}.png`, comparison.diff);
          console.error(`FAIL ${example.name}: ${changed} changed pixels`);
        }
      }
      report.results.push({ name: example.name, source: example.source, case: example.case_name, renderer: example.renderer.version, unused_schema_diagnostics: validation.unused, changed_pixels: changed, passed: update || changed === 0 });
    } catch (error) {
      report.results.push({ name: example.name, passed: false, error: `${error.message}\n${errors.join('\n')}` });
      console.error(`FAIL ${example.name}: ${error.message}`);
    } finally {
      await context.close();
    }
  }
  assert.ok(report.results.every(result => result.passed), 'Screenshot checks failed; inspect actual/expected/diff and report.json');
  if (update) {
    for (const example of manifest.examples) await copyFile(`${output}/actual/${example.name}.png`, `${baselines}/${example.name}.png`);
  }
  console.log(`PASS ${report.results.length} screenshots (${update ? 'updated; review the PNG diffs' : 'exact pixel match'})`);
} catch (error) {
  report.error = error.stack;
  process.exitCode = 1;
  console.error(error.message);
} finally {
  await browser?.close();
  await writeFile(`${output}/report.json`, `${JSON.stringify(report, null, 2)}\n`);
}
