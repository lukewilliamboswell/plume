import { PNG } from 'pngjs';

// Compare decoded RGBA pixels, with zero tolerance, independently of PNG compression.
export function compareImages(expectedBytes, actualBytes) {
  const expected = PNG.sync.read(expectedBytes);
  const actual = PNG.sync.read(actualBytes);
  const width = Math.max(expected.width, actual.width);
  const height = Math.max(expected.height, actual.height);
  const diff = new PNG({ width, height });
  let changed = 0;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const a = (y * actual.width + x) * 4;
      const e = (y * expected.width + x) * 4;
      const d = (y * width + x) * 4;
      const isChanged = x >= actual.width || y >= actual.height ||
        x >= expected.width || y >= expected.height ||
        [0, 1, 2, 3].some(channel => actual.data[a + channel] !== expected.data[e + channel]);
      if (isChanged) {
        changed++;
        diff.data.set([255, 0, 0, 255], d);
      } else {
        const gray = Math.round((actual.data[a] + actual.data[a + 1] + actual.data[a + 2]) / 3);
        diff.data.set([gray, gray, gray, 100], d);
      }
    }
  }
  return { changed, diff: PNG.sync.write(diff) };
}

export function checkInventory({ names, baselines, gallery, update }) {
  const expected = names.map(name => `${name}.png`).sort();
  if (new Set(expected).size !== expected.length || expected.length === 0) {
    throw new Error('Screenshot inventory must be nonempty and have unique names');
  }
  for (const [label, observed] of [['baseline', baselines], ['README gallery', gallery]]) {
    const missing = expected.filter(name => !observed.includes(name));
    const extra = observed.filter(name => !expected.includes(name));
    if (extra.length || (missing.length && !(update && label === 'baseline'))) {
      throw new Error(`${label} inventory differs: missing [${missing}], extra [${extra}]`);
    }
  }
}
