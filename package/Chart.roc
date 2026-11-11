import InternalJson
import Bar
import Scatter
import Sankey
import Layout
import Pie
import Heatmap
import Histogram

## A complete Plotly figure containing any supported trace kinds.
## Construct validated traces first, then pass their tags to [Chart.new].
## The package is pure: [Chart.to_json] and [Chart.to_html] return text,
## and the application chooses where to write it.
Chart :: { traces : List(Trace), layout : Layout, title : [FromLayout, Text(Str)] }.{

	## A trace paired with its chart kind.
	## Wrap values produced by [Bar.new], [Scatter.new], [Pie.new],
	## [Sankey.new], [Heatmap.new] or [Histogram.new] in the matching tag.
	## Different kinds and coordinate shapes can share one chart; list order
	## controls trace order.
	Trace : [Bar(Bar), Scatter(Scatter), Sankey(Sankey), Pie(Pie), Heatmap(Heatmap), Histogram(Histogram)]

	## Configure the whole figure and its HTML document title.
	## - `traces` defaults to an empty list, producing a valid empty figure.
	## - `layout` defaults to [Layout.new] with default props.
	## - `title: FromLayout` derives the HTML document title from the layout's
	##   title, or uses "My Chart" when no title is set.
	## - `title: Text(text)` overrides only the HTML document title. The
	##   visible chart title remains [Layout.Props]'s `title`.
	## The document-title setting is not included in [Chart.to_json].
	Props := { traces : List(Trace) ?? [], layout : Layout ?? Layout.new({}), title : [FromLayout, Text(Str)] ?? FromLayout }

	## Assemble a figure from validated traces and layout settings.
	## Construction is infallible, and `Chart.new({})` is a valid empty chart.
	##
	## ```roc
	## expect {
	##     bars = Bar.new({ data: [{ x: "Apples", y: 3 }] })?
	##     chart = Chart.new({ traces: [Bar(bars)], title: Text("Fruit sales") })
	##     chart.to_html().contains("<title>Fruit sales</title>")
	## }
	## ```
	new : Props -> Chart
	new = |props| Chart.({ traces: props.traces, layout: props.layout, title: props.title })

	## Return a complete Plotly figure object with `data` and `layout`.
	## The result is standalone JSON, with strings escaped by Roc's encoder.
	## It contains no script tags or renderer dependency. An application can
	## parse it or pass the object to its own Plotly instance.
	to_json : Chart -> Str
	to_json = |Chart.(chart)| InternalJson.object([
		{ name: "data", value: traces_json_value(chart.traces) },
		{ name: "layout", value: chart.layout.to_json_value() },
	]).to_json()

	## Return only the figure's `data`: the JSON array of traces, in order.
	## Together with [Layout.to_json] for the layout, this lets a host that
	## redraws often send the two parts separately and skip resending a
	## layout that has not changed. See [Chart.to_json] for the whole figure.
	data_to_json : Chart -> Str
	data_to_json = |Chart.(chart)| traces_json_value(chart.traces).to_json()

	## Return a complete HTML document loading the pinned Plotly CDN script.
	## Viewing it requires access to `cdn.plot.ly`. The document includes
	## the figure as JSON and creates a chart in its `chart` element.
	## Document-title text and embedded JSON are escaped for their separate
	## HTML contexts, including script terminators. This does not change
	## Plotly's own interpretation of chart text and supported markup.
	to_html : Chart -> Str
	to_html = |chart| {
		Chart.(inner) = chart
		title = match inner.title {
			FromLayout => inner.layout.get_title()
			Text(text) => text
		}
		escaped_title = replace_sequences(
			title,
			[
				{ pattern: "&", replacement: "&amp;" },
				{ pattern: "<", replacement: "&lt;" },
				{ pattern: ">", replacement: "&gt;" },
				{ pattern: "\"", replacement: "&quot;" },
				{ pattern: "'", replacement: "&#39;" },
			],
		)
		json = replace_sequences(
			chart.to_json(),
			[
				{ pattern: "<", replacement: "\\u003c" },
				{ pattern: ">", replacement: "\\u003e" },
				{ pattern: "&", replacement: "\\u0026" },
			],
		)
		\\<!doctype html>
		\\<html>
		\\    <head>
		\\        <title>${escaped_title}</title>
		\\        <meta charset="utf-8" />
		\\        <meta name="viewport" content="width=device-width, initial-scale=1" />
		\\        <script src="https://cdn.plot.ly/plotly-4.2.0.min.js" integrity="sha384-F4AdcRk3NYRZZUZ7qARRp/wPkwvdta756IMuHDAZcmtM5nuHKykTbDJd7N9h+Qff" crossorigin="anonymous"></script>
		\\    </head>
		\\    <body>
		\\        <div id="chart"></div>
		\\        <script type="application/json" id="chartData">${json}</script>
		\\        <script>
		\\            const chartData = JSON.parse(document.getElementById("chartData").textContent);
		\\            Plotly.newPlot("chart", chartData);
		\\        </script>
		\\    </body>
		\\</html>
	}
}

## Empty charts always contain valid JSON objects and an empty trace array.
expect {
	decoded : { data : List({}), layout : {} }
	decoded = Json.parse(Chart.new({}).to_json())?
	decoded == { data: [], layout: {} }
}

## One chart may combine traces with unrelated coordinate types.
expect {
	bar = Bar.new({ data: [{ x: "apples", y: 3 }] })?
	scatter = Scatter.new({ data: [{ x: 1.5, y: 2.5 }] })
	chart = Chart.new({ traces: [Bar(bar), Scatter(scatter)] })
	decoded : { data : List({ type : Str }) }
	decoded = Json.parse(chart.to_json())?
	decoded.data == [{ type: "bar" }, { type: "scatter" }]
}

## The data part is exactly the figure's data array.
expect {
	bar = Bar.new({ data: [{ x: "a", y: 1 }] })?
	spread = Histogram.new({ values: [1, 2] })?
	grid = Heatmap.new({ x: [1], rows: [{ y: 1, values: [2] }] })?
	chart = Chart.new({ traces: [Bar(bar), Histogram(spread), Heatmap(grid)] })
	decoded : List({ type : Str })
	decoded = Json.parse(chart.data_to_json())?
	decoded == [{ type: "bar" }, { type: "histogram" }, { type: "heatmap" }] and chart.to_json() == "{\"data\":${chart.data_to_json()},\"layout\":${Layout.new({}).to_json()}}"
}

## HTML titles cannot inject markup and template-like data remains literal.
expect {
	chart = Chart.new({ title: Text("</title><script>alert('x')</script>&{{CHART_JSON}}") })
	chart.to_html().contains("<title>&lt;/title&gt;&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;&amp;{{CHART_JSON}}</title>")
}

## JSON embedded in HTML cannot close its script element.
expect {
	pie = Pie.new({ data: [{ label: "</script><script>alert(1)</script>&雪", value: 1 }] })?
	html = Chart.new({ traces: [Pie(pie)] }).to_html()
	html.contains("\\u003c/script\\u003e\\u003cscript\\u003ealert(1)\\u003c/script\\u003e\\u0026雪")
}

traces_json_value : List(Chart.Trace) -> InternalJson
traces_json_value = |traces| InternalJson.array(
	traces.map(
		|trace| match trace {
			Bar(bar) => bar.to_json_value()
			Scatter(scatter) => scatter.to_json_value()
			Sankey(sankey) => sankey.to_json_value()
			Pie(pie) => pie.to_json_value()
			Heatmap(heatmap) => heatmap.to_json_value()
			Histogram(histogram) => histogram.to_json_value()
		},
	),
)

replace_sequences : Str, List({ pattern : Str, replacement : Str }) -> Str
replace_sequences = |text, replacements| replacements.fold(text, |escaped, rule| Str.join_with(escaped.split_on(rule.pattern), rule.replacement))

## The complete empty figure has stable JSON output.
expect Chart.new({}).to_json() ==
	\\{"data":[],"layout":{"font":{},"title":{},"xaxis":{},"yaxis":{},"showlegend":false}}

## The complete document is generated with Roc multiline interpolation.
expect Chart.new({}).to_html() ==
	\\<!doctype html>
	\\<html>
	\\    <head>
	\\        <title>My Chart</title>
	\\        <meta charset="utf-8" />
	\\        <meta name="viewport" content="width=device-width, initial-scale=1" />
	\\        <script src="https://cdn.plot.ly/plotly-4.2.0.min.js" integrity="sha384-F4AdcRk3NYRZZUZ7qARRp/wPkwvdta756IMuHDAZcmtM5nuHKykTbDJd7N9h+Qff" crossorigin="anonymous"></script>
	\\    </head>
	\\    <body>
	\\        <div id="chart"></div>
	\\        <script type="application/json" id="chartData">{"data":[],"layout":{"font":{},"title":{},"xaxis":{},"yaxis":{},"showlegend":false}}</script>
	\\        <script>
	\\            const chartData = JSON.parse(document.getElementById("chartData").textContent);
	\\            Plotly.newPlot("chart", chartData);
	\\        </script>
	\\    </body>
	\\</html>
