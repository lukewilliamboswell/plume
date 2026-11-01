import assert from 'node:assert/strict';
import test from 'node:test';
import { PNG } from 'pngjs';
import { compareImages, checkInventory } from './compare.mjs';

const image = (width, height, values) => PNG.sync.write(Object.assign(new PNG({ width, height }), { data: Buffer.from(values) }));
const white = image(1, 1, [255, 255, 255, 255]);

test('the visual gate accepts equal pixels and rejects a single-channel change', () => {
  assert.equal(compareImages(white, white).changed, 0);
  assert.equal(compareImages(white, image(1, 1, [254, 255, 255, 255])).changed, 1);
});
test('dimension changes produce a visible failing diff', () => {
  const result = compareImages(white, image(2, 1, [255, 255, 255, 255, 255, 255, 255, 255]));
  assert.equal(result.changed, 1);
  assert.equal(PNG.sync.read(result.diff).width, 2);
});
test('missing, stale and unlisted gallery images fail instead of reducing coverage', () => {
  assert.throws(() => checkInventory({ names: ['one'], baselines: [], gallery: ['one.png'], update: false }));
  assert.throws(() => checkInventory({ names: ['one'], baselines: ['one.png', 'stale.png'], gallery: ['one.png'], update: true }));
  assert.throws(() => checkInventory({ names: ['one'], baselines: ['one.png'], gallery: [], update: true }));
  checkInventory({ names: ['one'], baselines: [], gallery: ['one.png'], update: true });
});
