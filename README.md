# Plume

A pure [Roc](https://www.roc-lang.org) package for building interactive charts with [Plotly.js](https://github.com/plotly/plotly.js). Create typed traces and layouts, then render JSON or a complete HTML document.

[Documentation](https://lukewilliamboswell.github.io/plume/) · [Latest release](https://github.com/lukewilliamboswell/plume/releases/latest)

## Gallery

Select a chart to open its runnable source.

| | | |
| :---: | :---: | :---: |
| [<img src="examples/demo-images/bar-chart.png" alt="Vertical bars comparing Roc programmers by country" width="260">](examples/bar-chart.roc)<br>**Bars** | [<img src="examples/demo-images/horizontal-bar-chart.png" alt="Horizontal bars comparing Roc programmers by country" width="260">](examples/horizontal-bar-chart.roc)<br>**Horizontal bars** | [<img src="examples/demo-images/scatter.png" alt="Scatter points showing house price against floor area" width="260">](examples/scatter.roc)<br>**Scatter** |
| [<img src="examples/demo-images/line.png" alt="A line connecting house prices against floor area" width="260">](examples/line.roc)<br>**Lines** | [<img src="examples/demo-images/bubble.png" alt="Bubble traces using different marker shapes, sizes and colors" width="260">](examples/bubble.roc)<br>**Bubbles** | [<img src="examples/demo-images/simple.png" alt="Purple diamond markers and a dashed line showing fruit sales" width="260">](examples/simple.roc)<br>**Styled scatter** |
| [<img src="examples/demo-images/pie.png" alt="Pie slices comparing Roc programmers by country" width="260">](examples/pie.roc)<br>**Pie** | [<img src="examples/demo-images/donut.png" alt="A donut chart comparing Roc programmers by country" width="260">](examples/donut.roc)<br>**Donut** | [<img src="examples/demo-images/hello.png" alt="Bar and scatter traces sharing a chart of snacks and fruit" width="260">](examples/hello.roc)<br>**Mixed traces** |
| [<img src="examples/demo-images/equation-sine.png" alt="A sine wave plotted as a line" width="260">](examples/equation-sine.roc)<br>**Sine** | [<img src="examples/demo-images/equation-cosine.png" alt="A cosine wave plotted as a line" width="260">](examples/equation-cosine.roc)<br>**Cosine** | [<img src="examples/demo-images/sankey.png" alt="Colored Sankey nodes connected by weighted flows" width="260">](examples/sankey.roc)<br>**Sankey** |
| [<img src="examples/demo-images/budget.png" alt="A budget Sankey diagram connecting income, bills and household expenses" width="260">](examples/budget.roc)<br>**Budget flows** | | |

## Try an example

Use the current Roc nightly. From this checkout:

```sh
roc examples/simple.roc > chart.html
```

Open `chart.html` in your browser. The generated HTML loads Plotly from its CDN, so viewing the chart requires network access. Examples print HTML to standard output and never launch a browser.

Release examples are bound to their package release; checkout examples use the local package. See the [manual](https://lukewilliamboswell.github.io/plume/) for installation, chart construction, API guarantees and contributor setup.


See [Contributing](CONTRIBUTING.md) to change the package or its gallery.
