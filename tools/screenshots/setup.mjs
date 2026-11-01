import { spawnSync } from 'node:child_process';

const options = process.argv.slice(2);
if (options.length && (options.length !== 1 || options[0] !== '--with-deps')) {
  throw new Error('Use screenshots-setup, optionally with --with-deps in CI');
}
if (Number(process.versions.node.split('.')[0]) < 18) throw new Error('Screenshots require Node.js 18 or later');
for (const [program, args] of [
  ['npm', ['ci', '--ignore-scripts', '--no-audit', '--no-fund', '--prefix', 'tools/screenshots']],
  [process.execPath, ['tools/screenshots/node_modules/playwright/cli.js', 'install', '--only-shell', ...options, 'chromium']],
]) {
  const result = spawnSync(program, args, { stdio: 'inherit', timeout: 600_000 });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
