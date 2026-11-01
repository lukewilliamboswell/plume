import { mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

// Execute a native Roc driver. Launching the driver through `roc run` changes
// inherited process state and can break a product compiler launched as a child.
// Keep each command an argv array: no shell expansion or inherited shell state.
function run(program, args) {
  const result = spawnSync(program, args, { stdio: 'inherit', timeout: 600_000 });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
mkdirSync('.screenshots-out', { recursive: true });
run('roc-stable', ['test', '--opt=dev', 'scripts/screenshots.roc']);
run('roc-stable', ['build', '--opt=dev', '--output=.screenshots-out/driver', 'scripts/screenshots.roc']);
run('.screenshots-out/driver', process.argv.slice(2));
