import assert from 'node:assert/strict';
import test from 'node:test';
import { classifyValidation } from './validation.mjs';

const unused = (container, path, trace = null) => ({ code: 'unused', container, path, trace });
test('only mode-inactive scatter containers are classified as expected unused', () => {
  const figure = { data: [{ type: 'scatter', mode: 'markers' }], layout: {} };
  const line = unused('data', ['line'], 0);
  const marker = unused('data', ['marker'], 0);
  assert.deepEqual(classifyValidation(figure, [line, marker]), { unused: [line], fatal: [marker] });
});
test('the WebGL scatter renderer shares the mode-inactive container rule', () => {
  const figure = { data: [{ type: 'scattergl', mode: 'markers' }, { type: 'bar' }], layout: {} };
  const line = unused('data', ['line'], 0);
  const barLine = unused('data', ['line'], 1);
  assert.deepEqual(classifyValidation(figure, [line, barLine]), { unused: [line], fatal: [barLine] });
});
test('empty non-Cartesian axes are harmless, configured ignored axes are not', () => {
  const diagnostic = unused('layout', ['xaxis']);
  assert.equal(classifyValidation({ data: [{ type: 'pie' }], layout: { xaxis: {} } }, [diagnostic]).unused.length, 1);
  assert.equal(classifyValidation({ data: [{ type: 'pie' }], layout: { xaxis: { title: 'lost' } } }, [diagnostic]).fatal.length, 1);
});
test('unsupported attributes and nested paths remain fatal even in inactive containers', () => {
  const figure = { data: [{ type: 'scatter', mode: 'markers' }], layout: {} };
  for (const diagnostic of [unused('data', ['orientation'], 0), unused('data', ['line', 'unknown'], 0), { code: 'schema', container: 'data', path: ['line'], trace: 0 }]) {
    assert.deepEqual(classifyValidation(figure, [diagnostic]), { unused: [], fatal: [diagnostic] });
  }
});
