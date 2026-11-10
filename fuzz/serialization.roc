app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.6.0/6uc3YKGydgEnS2nrCimSYWDNfT6drYcgU52VAwqrb6DS.tar.zst",
	plume: "../package/main.roc",
}

import fuzz.Fuzz
import plume.Axis
import plume.Bar
import plume.Chart
import plume.Coordinate
import plume.Font
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

## Text, floating-point boundaries and graph defects travel together in each
## replayable input. The binary codec preserves NaN and infinity witnesses.
Input := { text : Str, number : F64, graph_case : U8 }.{
	parser_for : _
	encoder_for : _
}

## Validate arbitrary numeric settings and graph endpoints, then render a
## populated chart using valid finite values. Only Chart.to_html is inside
## chart-html; constructor checks and round-trip decoding remain outside it.
test! : Input => Fuzz.Outcome
test! = |input| {
	if !is_numeric_policy_correct(input.number) {
		crash "serialization.test!: constructors accepted invalid numbers or rejected valid numbers: ${Str.inspect(input.number)}"
	}
	if !is_time_policy_correct(input.number) {
		crash "serialization.test!: Time range or calendar round trip disagreed with the reference: ${Str.inspect(input.number)}"
	}
	if !is_graph_policy_correct(input.graph_case) {
		crash "serialization.test!: Sankey endpoint validation disagreed with the generated graph case"
	}
	built = populated_chart(input)
	chart = match built {
		Ok(value) => value
		Err(error) => crash "serialization.test!: valid chart construction failed: ${Str.inspect(error)}"
	}
	measured = Fuzz.measure!("chart-html", || chart.to_html())
	if !is_round_trip({ input, html: measured.value }) {
		crash "serialization.test!: populated chart data did not survive safe HTML embedding"
	}
	Fuzz.keep
}

is_numeric_policy_correct : F64 -> Bool
is_numeric_policy_correct = |number| {
	finite = number.is_finite()
	nonnegative = finite and number >= 0
	actual = {
		coordinate: Coordinate.from_number(number).is_ok(),
		bar_width: Bar.new({ data: [{ x: "x", y: 0 }], width: number }).is_ok(),
		pie_value: Pie.new({ data: [{ label: "slice", value: number }] }).is_ok(),
		pie_hole: Pie.new({ data: [{ label: "slice", value: 0 }], hole: number }).is_ok(),
		sankey_value: Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "b", label: "B" }], links: [{ source: "a", target: "b", value: number }] }).is_ok(),
		marker_size: Marker.new({ size: number }).is_ok(),
		line_width: Line.new({ width: number }).is_ok(),
		font_size: Font.new({ size: number }).is_ok(),
		axis_bounds: Axis.new({ range: Bounds({ min: number, max: 0 }) }).is_ok(),
		heatmap_value: Heatmap.new({ x: [1], rows: [{ y: 1, values: [number] }] }).is_ok(),
		heatmap_range: Heatmap.new({ x: [], rows: [], value_range: Bounds({ min: number, max: 0 }) }).is_ok(),
		histogram_bins: Histogram.new({ values: [], bins: Fixed({ start: 0, end: 10, size: number }) }).is_ok(),
	}
	expected = {
		coordinate: finite,
		bar_width: nonnegative,
		pie_value: nonnegative,
		pie_hole: nonnegative and number <= 1,
		sankey_value: nonnegative,
		marker_size: nonnegative,
		line_width: nonnegative,
		font_size: finite and number >= 1,
		axis_bounds: finite,
		heatmap_value: finite,
		heatmap_range: finite and number < 0,
		histogram_bins: finite and number > 0,
	}
	actual == expected
}

## Time accepts exactly 0001-01-01 through 9999-12-31 and every accepted
## instant survives a round trip through its calendar fields. The number's
## bits choose milliseconds on both sides of each supported endpoint.
is_time_policy_correct : F64 -> Bool
is_time_policy_correct = |number| {
	millis = (number.to_bits() % 1_125_899_906_842_624).to_i64_wrap() - 562_949_953_421_312
	in_range = millis >= -62_135_596_800_000 and millis <= 253_402_300_799_999
	match Time.from_epoch_millis(millis) {
		Ok(time) => in_range and Time.from_calendar(time.to_calendar()) == Ok(time) and time.to_epoch_millis() == millis
		Err(_) => !in_range
	}
}

is_graph_policy_correct : U8 -> Bool
is_graph_policy_correct = |graph_case| match graph_case {
	0 => Sankey.new({ nodes: [{ id: "a", label: "same" }, { id: "b", label: "same" }], links: [{ source: "a", target: "b", value: 0 }] }).is_ok()
	1 => Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "a", label: "B" }], links: [] }) == Err(DuplicateNode("a"))
	2 => Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "missing", target: "a", value: 1 }] }) == Err(MissingSource("missing"))
	3 => Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "missing", value: 1 }] }) == Err(MissingTarget("missing"))
	4 => Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value: 0 }] }) == Err(SelfLink("a"))
	_ => Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "b", label: "B" }], links: [{ source: "a", target: "b", value: 1 }, { source: "b", target: "a", value: 1 }] }).is_ok()
}

populated_chart : Input -> Try(Chart, _)
populated_chart = |input| {
	finite_number = if (input.number.is_finite()) input.number else 0
	magnitude = if (finite_number < 0) -finite_number else finite_number
	text_coordinate = Coordinate.from_text(input.text)
	number_coordinate = Coordinate.from_number(finite_number)?
	bar = Bar.new({ data: [{ x: text_coordinate, y: number_coordinate }], name: input.text })?
	scatter = Scatter.new({ data: [{ x: number_coordinate, y: number_coordinate, text: input.text }], mode: MarkersText, name: input.text })
	pie = Pie.new({ data: [{ label: input.text, value: magnitude }], name: input.text })?
	sankey = Sankey.new({
		nodes: [{ id: "a", label: input.text, hover: Text(input.text) }, { id: "b", label: input.text }],
		links: [{ source: "a", target: "b", value: magnitude, hover: Text(input.text) }],
		name: input.text,
	})?
	heatmap = Heatmap.new({ x: [text_coordinate], rows: [{ y: text_coordinate, values: [finite_number] }], name: input.text })?
	histogram = Histogram.new({ values: [text_coordinate, number_coordinate], name: input.text })?
	Ok(
		Chart.new({
			traces: [Bar(bar), Scatter(scatter), Pie(pie), Sankey(sankey), Heatmap(heatmap), Histogram(histogram)],
			layout: Layout.new({
				title: Title.new({ text: input.text }),
				size: Size.new({ height: Pixels(320) })?,
				ui_revision: Preserve(input.text),
				# A shape omits an empty label, so prefix it to keep one to decode.
				shapes: [Shape.new({ placement: VerticalLine(text_coordinate), label: "Label: ${input.text}" })],
			}),
		}),
	)
}

is_round_trip : { input : Input, html : Str } -> Bool
is_round_trip = |{ input, html }| {
	payload = match html.split_on("id=\"chartData\">") {
		[_, tail] => match tail.split_on("</script>") {
			[json, ..] => json
			_ => crash "serialization.is_round_trip: document has no closing script element"
		}
		_ => crash "serialization.is_round_trip: document has no unique chartData element"
	}
	decoded : Try({ data : List({ type : Str, name : Str }), layout : { title : { text : Str }, uirevision : Str, shapes : List({ x0 : Str, label : { text : Str } }) } }, _)
	decoded = Json.parse(payload)
	match decoded {
		Ok(figure) =>
			figure.data.map(|trace| trace.type) == ["bar", "scatter", "pie", "sankey", "heatmap", "histogram"]
				and figure.data.all(|trace| trace.name == input.text)
				and figure.layout.title.text == input.text
				and figure.layout.uirevision == input.text
				and figure.layout.shapes == [{ x0: input.text, label: { text: "Label: ${input.text}" } }]
				and !payload.contains("<")
				and is_trace_round_trip(input)
		Err(_) => False
	}
}

is_trace_round_trip : Input -> Bool
is_trace_round_trip = |input| {
	finite_number = if (input.number.is_finite()) input.number else 0
	magnitude = if (finite_number < 0) -finite_number else finite_number
	number_coordinate = match Coordinate.from_number(finite_number) {
		Ok(coordinate) => coordinate
		Err(_) => return False
	}
	bar = Bar.new({ data: [{ x: Coordinate.from_text(input.text), y: number_coordinate }] })
	pie = Pie.new({ data: [{ label: input.text, value: magnitude }] })
	match (bar, pie) {
		(Ok(bars), Ok(slices)) => {
			decoded_bars : Try({ x : List(Str), y : List(F64) }, _)
			decoded_bars = Json.parse(bars.to_json())
			decoded_slices : Try({ labels : List(Str), values : List(F64) }, _)
			decoded_slices = Json.parse(slices.to_json())
			match (decoded_bars, decoded_slices) {
				(Ok(points), Ok(values)) => points == { x: [input.text], y: [finite_number] } and values == { labels: [input.text], values: [magnitude] }
				_ => False
			}
		}
		_ => False
	}
}

target = Fuzz.target_with!({
	name: "plume-serialization",
	examples: [
		Fuzz.example({ name: "empty", revision: "2", make: || Input.({ text: "", number: 0, graph_case: 0 }) }),
		Fuzz.example({ name: "controls", revision: "2", make: || Input.({ text: "\u(0)\n\t\r\"\\", number: 1, graph_case: 0 }) }),
		Fuzz.example({ name: "script", revision: "2", make: || Input.({ text: "</ScRiPt><script>alert(1)</script>{{CHART_TITLE}}", number: -1, graph_case: 0 }) }),
		Fuzz.example({ name: "unicode", revision: "2", make: || Input.({ text: "雪🌻e\u(301)\u(2028)\u(2029)", number: 0.5, graph_case: 0 }) }),
		Fuzz.example({ name: "nan", revision: "1", make: || Input.({ text: "NaN", number: F64.nan, graph_case: 0 }) }),
		Fuzz.example({ name: "positive-infinity", revision: "1", make: || Input.({ text: "infinity", number: F64.infinity, graph_case: 0 }) }),
		Fuzz.example({ name: "negative-infinity", revision: "1", make: || Input.({ text: "negative infinity", number: -F64.infinity, graph_case: 0 }) }),
		Fuzz.example({ name: "tiny-finite", revision: "1", make: || Input.({ text: "subnormal", number: F64.from_bits(1), graph_case: 0 }) }),
		Fuzz.example({ name: "large-finite", revision: "1", make: || Input.({ text: "large finite", number: F64.highest, graph_case: 0 }) }),
		Fuzz.example({ name: "duplicate-node", revision: "1", make: || Input.({ text: "duplicate", number: 2, graph_case: 1 }) }),
		Fuzz.example({ name: "missing-source", revision: "1", make: || Input.({ text: "missing source", number: 2, graph_case: 2 }) }),
		Fuzz.example({ name: "missing-target", revision: "1", make: || Input.({ text: "missing target", number: 2, graph_case: 3 }) }),
		Fuzz.example({ name: "self-link", revision: "1", make: || Input.({ text: "self link", number: 0, graph_case: 4 }) }),
		Fuzz.example({ name: "two-node-cycle", revision: "1", make: || Input.({ text: "cycle", number: 1, graph_case: 5 }) }),
	],
	generator: Fuzz.map({ text: Fuzz.str, number: Fuzz.f64, graph_case: Fuzz.u8_in(0, 5) }.Fuzz, |fields| Input.(fields)),
	test!,
	show: Str.inspect,
})

## Script terminators and HTML-looking text remain inert in populated charts.
expect {
	input = Input.({ text: "</ScRiPt><script>alert(1)</script>\"\\\n\t\u(0)雪{{CHART_TITLE}}", number: 0.5, graph_case: 0 })
	chart = populated_chart(input)?
	is_round_trip({ input, html: chart.to_html() })
}

## Time endpoints, both neighbours and ordinary instants follow the range rule.
expect [F64.from_bits(0), F64.from_bits(562_949_953_421_312), F64.from_bits(562_949_953_421_312 - 62_135_596_800_000), F64.from_bits(562_949_953_421_312 - 62_135_596_800_001), F64.from_bits(562_949_953_421_312 + 253_402_300_799_999), F64.from_bits(562_949_953_421_312 + 253_402_300_800_000), 0.5, F64.nan].all(is_time_policy_correct)

## Every explicitly named graph defect returns its own structured error.
expect [0, 1, 2, 3, 4, 5].all(is_graph_policy_correct)

## Numeric constructors reject NaN, infinity and negatives according to their domain.
expect [F64.nan, F64.infinity, -F64.infinity, -1, 0, 0.5, 1, 2].all(is_numeric_policy_correct)
