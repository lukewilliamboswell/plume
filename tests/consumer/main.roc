# Exercise the public package as a consumer and decode its wire format independently.
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Axis
import plume.Bar
import plume.Chart
import plume.Color
import plume.Coordinate
import plume.Heatmap
import plume.Histogram
import plume.Layout
import plume.Line
import plume.Marker
import plume.Pie
import plume.Sankey
import plume.Scatter
import plume.Shape
import plume.Size
import plume.Time
import plume.Title

# Quotes, controls, Unicode and script delimiters must survive a JSON round trip.
hostile = "quote: \"; slash: \\; newline:\n; tab:\t; nul:\u(0000); é😀; </ScRiPt><script>alert(1)</script>; {{CHART_TITLE}}"

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	check_bar()?
	check_scatter()?
	check_pie()?
	check_sankey()?
	check_html()?
	check_text_corpus()?
	check_coordinates()?
	check_time_series()?
	check_grids()?
	Stdout.line!("Consumer contract: 9 checks passed")?
	Ok({})
}

check_bar : () -> Try({}, _)
check_bar = || {
	color = Color.rgb({ red: 1, green: 2, blue: 3 })
	series = Bar.new({ data: [{ x: Coordinate.from_text(hostile), y: -2.5, color }], name: hostile, width: 2.5, orientation: Horizontal })?
	parsed : { x : List(Str), y : List(F64), name : Str, width : F64, orientation : Str, type : Str, marker : { color : Str } }
	parsed = Json.parse(series.to_json())?
	expected = {
		x: [hostile],
		y: [-2.5.F64],
		name: hostile,
		width: 2.5,
		orientation: "h",
		type: "bar",
		marker: { color: "rgb(1, 2, 3)" },
	}
	if parsed != expected {
		return Err(ContractFailure("bar fields or escaping"))
	}
	Ok({})
}

check_scatter : () -> Try({}, _)
check_scatter = || {
	marker = Marker.new({ color: Color.rgb({ red: 10, green: 20, blue: 30 }), size: 7, symbol: Diamond })?
	curve = Scatter.new({
		data: [{ x: 1, y: 2, text: hostile, marker }],
		mode: LinesMarkersText,
		line: Line.new({ width: 3, dash: DashDot })?,
		name: hostile,
	})
	parsed : { x : List(F64), y : List(F64), text : Str, mode : Str, type : Str, name : Str, line : { width : F64, dash : Str }, marker : { color : Str, size : F64, symbol : Str } }
	parsed = Json.parse(curve.to_json())?
	actual = { x: parsed.x, y: parsed.y, text: parsed.text, mode: parsed.mode, type: parsed.type, name: parsed.name, width: parsed.line.width, dash: parsed.line.dash, marker: parsed.marker }
	expected = { x: [1.F64], y: [2.F64], text: hostile, mode: "lines+markers+text", type: "scatter", name: hostile, width: 3.F64, dash: "dashdot", marker: { color: "rgb(10, 20, 30)", size: 7.F64, symbol: "diamond" } }
	if actual != expected {
		return Err(ContractFailure("scatter fields or escaping"))
	}
	Ok({})
}

check_pie : () -> Try({}, _)
check_pie = || {
	portions = Pie.new({ data: [{ label: hostile, value: 0 }, { label: "second", value: 5 }], hole: 0.4, name: hostile })?
	parsed : { labels : List(Str), values : List(F64), hole : F64, name : Str, type : Str }
	parsed = Json.parse(portions.to_json())?
	expected = { labels: [hostile, "second"], values: [0.F64, 5], hole: 0.4, name: hostile, type: "pie" }
	if parsed != expected {
		return Err(ContractFailure("pie fields or escaping"))
	}
	Ok({})
}

check_sankey : () -> Try({}, _)
check_sankey = || {
	flows = Sankey.new({
		nodes: [
			{ id: "source", label: hostile, hover: Text(hostile) },
			{ id: "target", label: hostile },
		],
		links: [{ source: "source", target: "target", value: 5, hover: Text(hostile) }],
		orientation: Vertical,
	})?
	parsed : { type : Str, orientation : Str, node : { label : List(Str), customdata : List(Str) }, link : { source : List(U64), target : List(U64), value : List(F64), customdata : List(Str) } }
	parsed = Json.parse(flows.to_json())?
	actual = { type: parsed.type, orientation: parsed.orientation, labels: parsed.node.label, node_hover: parsed.node.customdata, source: parsed.link.source, target: parsed.link.target, values: parsed.link.value, link_hover: parsed.link.customdata }
	expected = { type: "sankey", orientation: "v", labels: [hostile, hostile], node_hover: [hostile, ""], source: [0.U64], target: [1.U64], values: [5.F64], link_hover: [hostile] }
	if actual != expected {
		return Err(ContractFailure("Sankey identity, indices or escaping"))
	}
	Ok({})
}

check_html : () -> Try({}, _)
check_html = || check_html_text(hostile)

check_html_text : Str -> Try({}, _)
check_html_text = |text| {
	chart = Chart.new({
		layout: Layout.new({
			title: Title.new({ text: text }),
		}),
	})
	html = chart.to_html()
	payload = match html.split_on("<script type=\"application/json\" id=\"chartData\">") {
		[_, tail] => match tail.split_on("</script>") {
			[json, ..] => json
			_ => return Err(ContractFailure("missing script end"))
		}
		_ => return Err(ContractFailure("missing JSON data element"))
	}
	decoded : { data : List({}), layout : { title : { text : Str } } }
	decoded = Json.parse(payload)?
	if decoded != { data: [], layout: { title: { text: text } } } {
		return Err(ContractFailure("HTML payload round trip"))
	}
	if payload.contains("<") {
		return Err(ContractFailure("script terminator in payload"))
	}
	if text.contains("<") and html.contains("<title>${text}</title>") {
		return Err(ContractFailure("unescaped document title"))
	}
	if text == hostile and !html.contains("&lt;/ScRiPt&gt;") {
		return Err(ContractFailure("document title lost escaped text"))
	}
	Ok({})
}

## Bar output preserves exact data, marker columns and escaped user text.
expect {
	check_bar()? == {}
}

## Scatter output preserves mode, point text and nested line settings.
expect {
	check_scatter()? == {}
}

## Pie labels and values preserve their order and JSON types.
expect {
	check_pie()? == {}
}

## Sankey IDs distinguish nodes even when their visible labels are identical.
expect {
	check_sankey()? == {}
}

## Embedded JSON round trips hostile text without creating HTML elements.
expect {
	check_html()? == {}
}

check_text_corpus : () -> Try({}, _)
check_text_corpus = || {
	controls = Str.from_utf8(List.from_iter((0.U8..<32).iter()).append(127))?
	corpus = [
		"",
		controls,
		"é e\u(0301) 😀 日本語 العربية",
		"line\u(2028)paragraph\u(2029)",
		"</script>",
		"</SCRIPT>",
		"</ScRiPt>",
		"</script >",
		"<!-- <script> --> & < > \" ' \\ ",
		"{{CHART_JSON}}{{CHART_TITLE}}",
	]
	for text in corpus {
		check_html_text(text)?
	}
	Ok({})
}

## Every ASCII control and adversarial Unicode/script spelling survives HTML JSON.
expect {
	check_text_corpus()? == {}
}

check_coordinates : () -> Try({}, _)
check_coordinates = || {
	# Literal hooks construct validated scalars at compile time. Runtime values
	# enter explicitly, so a NaN or object cannot reach a trace coordinate.
	number = Coordinate.from_number(2.5)?
	text = Coordinate.from_text(hostile)
	points = Scatter.new({
		data: [
			{ x: "literal", y: 1 },
			{ x: text, y: number },
			{ x: 3.5, y: -4 },
		],
	})
	decoded : { x : (Str, Str, F64), y : List(F64) }
	decoded = Json.parse(points.to_json())?
	expected = { x: ("literal", hostile, 3.5.F64), y: [1.F64, 2.5, -4] }
	if decoded != expected {
		return Err(ContractFailure("coordinate literal or runtime representation"))
	}
	rejected = [F64.infinity, -F64.infinity, F64.nan].map(|invalid| Coordinate.from_number(invalid).is_err())
	if rejected != [True, True, True] {
		return Err(ContractFailure("non-finite runtime coordinate accepted"))
	}
	Ok({})
}

## Coordinate literals and checked runtime values serialize as JSON scalars.
expect {
	check_coordinates()? == {}
}

check_time_series : () -> Try({}, _)
check_time_series = || {
	# A live time series: typed instants, a gap, a step line, an incident
	# shape and the layout settings a redrawing host relies on.
	start = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 12 })?
	later = Time.from_epoch_millis(start.to_epoch_millis() + 90_000)?
	series = Scatter.new({
		data: [
			{ x: Coordinate.from_time(start), y: 1 },
			{ x: Coordinate.from_time(later), y: 2, from_previous: Gap },
		],
		line: Line.new({ shape: StepAfter })?,
		fill: ToZeroY,
		renderer: WebGl,
	})
	layout = Layout.new({
		x_axis: Axis.new({ type: Date, range: TimeBounds({ start, end: later }), tick_format: Pattern("%H:%M") })?,
		size: Size.new({ height: Pixels(240), margin: Pixels({ left: 40, right: 8, top: 8, bottom: 32 }) })?,
		hover_mode: XUnified,
		ui_revision: Preserve(hostile),
		legend_position: Below,
		shapes: [Shape.new({ placement: VerticalLine(Coordinate.from_time(later)), label: hostile })],
	})
	chart = Chart.new({ traces: [Scatter(series)], layout })
	parsed : {
		data : List({ type : Str, x : List(Str), fill : Str, line : { shape : Str } }),
		layout : { xaxis : { range : List(Str), tickformat : Str }, height : U16, margin : { l : U16 }, hovermode : Str, uirevision : Str, legend : { orientation : Str }, shapes : List({ x0 : Str, label : { text : Str } }) },
	}
	parsed = Json.parse(chart.to_json())?
	expected = {
		data: [{ type: "scattergl", x: ["2026-11-11 12:00", "2026-11-11 12:01:30", "2026-11-11 12:01:30"], fill: "tozeroy", line: { shape: "hv" } }],
		layout: { xaxis: { range: ["2026-11-11 12:00", "2026-11-11 12:01:30"], tickformat: "%H:%M" }, height: 240, margin: { l: 40 }, hovermode: "x unified", uirevision: hostile, legend: { orientation: "h" }, shapes: [{ x0: "2026-11-11 12:01:30", label: { text: hostile } }] },
	}
	if parsed != expected or !chart.to_json().contains("\"y\":[1,null,2]") {
		return Err(ContractFailure("time series, gaps or layout settings"))
	}
	if !chart.to_json().starts_with("{\"data\":${chart.data_to_json()},") {
		return Err(ContractFailure("data part differs from the figure's data"))
	}
	Ok({})
}

## Time series keep typed instants, gaps, step lines and update settings.
expect {
	check_time_series()? == {}
}

check_grids : () -> Try({}, _)
check_grids = || {
	grid = Heatmap.new({ x: [Coordinate.from_text(hostile), 2], rows: [{ y: "row", values: [1, -2.5] }], value_range: Bounds({ min: -5, max: 5 }) })?
	spread = Histogram.new({ values: [1, 2, 2], bins: AtMost(4), normalization: Percent })?
	bars = Bar.new({ data: [{ x: 3, y: "task", base: At(Coordinate.from_text("2026-11-11")) }], orientation: Horizontal })?
	parsed : List({ type : Str })
	parsed = Json.parse(Chart.new({ traces: [Heatmap(grid), Histogram(spread), Bar(bars)], layout: Layout.new({ bar_mode: Overlay }) }).data_to_json())?
	decoded_grid : { x : (Str, F64), z : List(List(F64)), zmin : F64, zmax : F64 }
	decoded_grid = Json.parse(grid.to_json())?
	decoded_spread : { nbinsx : U16, histnorm : Str, x : List(F64) }
	decoded_spread = Json.parse(spread.to_json())?
	decoded_bars : { base : Str }
	decoded_bars = Json.parse(bars.to_json())?
	if parsed != [{ type: "heatmap" }, { type: "histogram" }, { type: "bar" }] or decoded_grid != { x: (hostile, 2.F64), z: [[1, -2.5]], zmin: -5, zmax: 5 } or decoded_spread != { nbinsx: 4, histnorm: "percent", x: [1, 2, 2] } or decoded_bars.base != "2026-11-11" {
		return Err(ContractFailure("heatmap, histogram or bar base fields"))
	}
	Ok({})
}

## A ragged heatmap row is rejected with its label and both counts.
expect Heatmap.new({ x: [1, 2], rows: [{ y: Coordinate.from_text(hostile), values: [1] }] }).map_ok(|_| {}) == Err(RowLengthMismatch({ y: Coordinate.from_text(hostile), expected: 2, actual: 1 }))

## Heatmaps, histograms and floating bars decode with their checked fields.
expect {
	check_grids()? == {}
}
