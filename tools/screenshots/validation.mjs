// Plotly reports these supported containers as unused when the selected trace
// does not draw them. Retain the diagnostics, while rejecting unknown paths,
// nonempty ignored axes and every other validation problem.
export function classifyValidation(figure, problems) {
  const unused = [];
  const fatal = [];
  for (const problem of problems ?? []) {
    const path = problem.path ?? [];
    let permitted = false;
    if (problem.code === 'unused' && path.length === 1) {
      if (problem.container === 'data' && Number.isInteger(problem.trace)) {
        const trace = figure.data[problem.trace];
        if (['scatter', 'scattergl'].includes(trace?.type) && typeof trace.mode === 'string') {
          const components = trace.mode.split('+');
          permitted = (path[0] === 'line' && !components.includes('lines')) ||
            (path[0] === 'marker' && !components.includes('markers'));
        }
      } else if (problem.container === 'layout' && ['xaxis', 'yaxis'].includes(path[0])) {
        const axis = figure.layout[path[0]];
        permitted = axis && Object.keys(axis).length === 0 &&
          figure.data.every(trace => ['pie', 'sankey'].includes(trace.type));
      }
    }
    (permitted ? unused : fatal).push(problem);
  }
  return { unused, fatal };
}
