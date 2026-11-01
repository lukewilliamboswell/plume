import InternalJson
import Bar
import Scatter
import Sankey
import Layout
import Pie

## A mixed collection of traces and its presentation.
Chart :: { traces : List(Trace), layout : Layout, title : [FromLayout, Text(Str)] }.{
	Trace : [Bar(Bar), Scatter(Scatter), Sankey(Sankey), Pie(Pie)]
	Props := { traces : List(Trace) ?? [], layout : Layout ?? Layout.new({}), title : [FromLayout, Text(Str)] ?? FromLayout }

	## Construct the complete chart through one props record.
	new : Props -> Chart
	new = |props| Chart.({ traces: props.traces, layout: props.layout, title: props.title })

	## Serialize a complete Plotly figure, including the empty chart.
	to_json : Chart -> Str
	to_json = |Chart.(chart)| {
		traces = chart.traces.map(
			|trace| match trace {
				Bar(bar) => bar.to_json_value()
				Scatter(scatter) => scatter.to_json_value()
				Sankey(sankey) => sankey.to_json_value()
				Pie(pie) => pie.to_json_value()
			},
		)
		InternalJson.object([
			{ name: "data", value: InternalJson.array(traces) },
			{ name: "layout", value: chart.layout.to_json_value() },
		]).to_json()
	}

	## Render a standalone document. Plotly is loaded from its pinned CDN URL.
	## User strings cannot terminate the document title or JSON script element.
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
		\\        <script src="https://cdn.plot.ly/plotly-2.35.2.min.js" integrity="sha384-cCVCZkAjYNxaYKbM8lsArLznDF/SvMFr1jcZrvOpSTCa0W40ZAdLzHCEulnUa5i7" crossorigin="anonymous"></script>
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
	scatter = Scatter.new({ data: [{ x: 1.5, y: 2.5 }] })?
	chart = Chart.new({ traces: [Bar(bar), Scatter(scatter)] })
	decoded : { data : List({ type : Str }) }
	decoded = Json.parse(chart.to_json())?
	decoded.data == [{ type: "bar" }, { type: "scatter" }]
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
	\\        <script src="https://cdn.plot.ly/plotly-2.35.2.min.js" integrity="sha384-cCVCZkAjYNxaYKbM8lsArLznDF/SvMFr1jcZrvOpSTCa0W40ZAdLzHCEulnUa5i7" crossorigin="anonymous"></script>
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
