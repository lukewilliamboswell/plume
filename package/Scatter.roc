import InternalJson
import Marker
import Line
import Coordinate
import Color

## A validated Plotly scatter, line, text, or bubble trace.
Scatter :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## One point, its marker, and optional display text.
	## `x` and `y` are text or finite numeric [Coordinate] values; use
	## [Coordinate.from_time] for instants on a date axis. `marker`
	## defaults to [Marker.default]. `text` defaults to an empty label and
	## is drawn when the selected [Scatter.Mode] includes text. Points are
	## rendered in list order, which also determines connected line order.
	## `from_previous: Gap` leaves the line unbroken up to the previous
	## point and starts a new segment here, for a missing sample; it has
	## no effect on the first point. The default `Connected` joins them.
	Point := { x : Coordinate, y : Coordinate, marker : Marker ?? Marker.default, text : Str ?? "", from_previous : [Connected, Gap] ?? Connected }

	## Select which parts of each point are drawn.
	## `Lines`, `Markers`, and `Text` select one part. Combined tags such as
	## `LinesMarkers` or `LinesMarkersText` select several. `Hidden` draws
	## none of those parts; it encodes Plotly's `none` mode and does not
	## remove the trace or its hover information.
	Mode : [Lines, Markers, Text, LinesMarkers, LinesText, MarkersText, LinesMarkersText, Hidden]

	## Choose the area to shade beneath or between lines.
	## `Unfilled` shades nothing. `ToZeroY` fills down to y = 0 and
	## `ToZeroX` across to x = 0. `ToNextY` and `ToNextX` fill to the
	## previous trace in the chart, for bands and stacked areas, and
	## `ToSelf` closes the trace's own outline. `ToNext` fills to the
	## previous trace's outline.
	Fill : [Unfilled, ToZeroY, ToZeroX, ToNextY, ToNextX, ToSelf, ToNext]

	## Choose how the browser draws the trace.
	## `Svg` draws each point as a vector element and suits up to a few
	## thousand points. `WebGl` draws with the GPU (Plotly's `scattergl`)
	## for many points or frequent updates; text and line shapes are
	## supported, but the browser must provide WebGL.
	Renderer : [Svg, WebGl]

	## The complete scatter, line, bubble, or text series.
	## - `data` preserves point order and may be empty.
	## - `mode` defaults to `Lines`; use `Markers` for a scatter/bubble plot.
	## - `line` defaults to [Line.default] and applies to connected segments.
	## - `name` is the legend/hover label, and may be empty.
	## - `fill` defaults to `Unfilled`. `fill_color: Auto` uses Plotly's
	##   translucent version of the line color; `Custom(color)` overrides it.
	## - `renderer` defaults to `Svg`.
	## Per-point text, color, size and symbol belong to [Scatter.Point].
	## When every point shares a marker field or its text, the output holds
	## that value once instead of repeating it for each point.
	Props := {
		data : List(Point),
		name : Str ?? "",
		line : Line ?? Line.default,
		mode : Mode ?? Lines,
		fill : Fill ?? Unfilled,
		fill_color : [Auto, Custom(Color)] ?? Auto,
		renderer : Renderer ?? Svg,
	}

	## Construct a scatter trace from already validated points and styles.
	## This function is infallible: runtime numbers must first pass through
	## [Coordinate.from_number], and marker/line constructors validate sizes.
	## Use `Scatter(trace)` to include the result in [Chart.Props].
	##
	## ```roc
	## expect {
	##     points = Scatter.new({ data: [{ x: 1, y: 2 }], mode: Markers })
	##     points.to_json().contains("markers")
	## }
	## ```
	new : Props -> Scatter
	new = |props| {
		# A gap repeats the next point's fields with a null y, which Plotly
		# draws as a break in the line without adding a visible point.
		var $rows = []
		for point in props.data {
			row = {
				x: point.x.to_json_value(),
				y: point.y.to_json_value(),
				color: InternalJson.string(point.marker.get_color().to_css()),
				size: InternalJson.encode(point.marker.get_size()) ?? crash "Scatter.new: opaque Marker accepted a non-finite size",
				symbol: InternalJson.string(point.marker.get_symbol()),
				text: InternalJson.string(point.text),
			}
			$rows = match point.from_previous {
				Gap if !$rows.is_empty() => $rows.append({ ..row, y: InternalJson.null }).append(row)
				_ => $rows.append(row)
			}
		}
		rows = $rows
		marker = InternalJson.object([
			{ name: "color", value: InternalJson.column(rows.map(|row| row.color)) },
			{ name: "size", value: InternalJson.column(rows.map(|row| row.size)) },
			{ name: "symbol", value: InternalJson.column(rows.map(|row| row.symbol)) },
		])
		text_fields = if props.data.all(|point| point.text.is_empty()) {
			[]
		} else {
			[{ name: "text", value: InternalJson.column(rows.map(|row| row.text)) }]
		}
		mode = match props.mode {
			Lines => "lines"
			Markers => "markers"
			Text => "text"
			LinesMarkers => "lines+markers"
			LinesText => "lines+text"
			MarkersText => "markers+text"
			LinesMarkersText => "lines+markers+text"
			Hidden => "none"
		}
		fill_fields = match props.fill {
			Unfilled => []
			ToZeroY => [{ name: "fill", value: InternalJson.string("tozeroy") }]
			ToZeroX => [{ name: "fill", value: InternalJson.string("tozerox") }]
			ToNextY => [{ name: "fill", value: InternalJson.string("tonexty") }]
			ToNextX => [{ name: "fill", value: InternalJson.string("tonextx") }]
			ToSelf => [{ name: "fill", value: InternalJson.string("toself") }]
			ToNext => [{ name: "fill", value: InternalJson.string("tonext") }]
		}
		fill_color_fields = match (props.fill, props.fill_color) {
			(Unfilled, _) | (_, Auto) => []
			(_, Custom(color)) => [{ name: "fillcolor", value: color.to_json_value() }]
		}
		trace_type = match props.renderer {
			Svg => "scatter"
			WebGl => "scattergl"
		}
		Scatter.(
			InternalJson.object(
				[
					{ name: "type", value: InternalJson.string(trace_type) },
					{ name: "x", value: InternalJson.array(rows.map(|row| row.x)) },
					{ name: "y", value: InternalJson.array(rows.map(|row| row.y)) },
					{ name: "marker", value: marker },
				]
					.concat(text_fields)
					.concat([
						{ name: "name", value: InternalJson.string(props.name) },
						{ name: "line", value: props.line.to_json_value() },
						{ name: "mode", value: InternalJson.string(mode) },
					])
					.concat(fill_fields)
					.concat(fill_color_fields),
			),
		)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Scatter.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Scatter -> InternalJson
	to_json_value = |Scatter.(json)| json

	## Serialize the trace as JSON.
	to_json : Scatter -> Str
	to_json = |scatter| scatter.to_json_value().to_json()
}

## Scatter text and names round trip through JSON escaping.
expect {
	scatter = Scatter.new({ data: [{ x: "a\"", y: 2, text: "line\n雪" }], mode: LinesMarkersText, name: "x\\y" })
	decoded : { x : List(Str), text : Str, name : Str, mode : Str }
	decoded = Json.parse(scatter.to_json())?
	decoded == { x: ["a\""], text: "line\n雪", name: "x\\y", mode: "lines+markers+text" }
}

## Runtime numeric coordinates are validated before entering a scatter point.
expect {
	coordinate = Coordinate.from_number(2.5)?
	scatter = Scatter.new({ data: [{ x: 1, y: coordinate }] })
	decoded : { y : List(F64) }
	decoded = Json.parse(scatter.to_json())?
	decoded.y == [2.5]
}

## Scatter JSON includes exactly its point arrays and presentation settings.
expect {
	scatter = Scatter.new({ data: [{ x: "x", y: "y" }] })
	scatter.to_json() ==
		\\{"type":"scatter","x":["x"],"y":["y"],"marker":{"color":"rgb(31, 119, 180)","size":6,"symbol":"circle"},"name":"","line":{"width":2,"color":"rgb(31, 119, 180)","dash":"solid"},"mode":"lines"}
}

## Every scatter mode maps to one canonical Plotly flag list.
expect {
	actual = [Lines, Markers, Text, LinesMarkers, LinesText, MarkersText, LinesMarkersText, Hidden].map_try(
		|mode| {
			scatter = Scatter.new({ data: [{ x: 1, y: 2 }], mode })
			decoded : { mode : Str }
			decoded = Json.parse(scatter.to_json())?
			Ok(decoded.mode)
		},
	)?
	actual == ["lines", "markers", "text", "lines+markers", "lines+text", "markers+text", "lines+markers+text", "none"]
}

## Empty scatter data needs no generic coordinate annotation.
expect Scatter.new({ data: [] }).to_json().contains("\"x\":[]")

## One point collection can hold numeric and text coordinates explicitly.
expect {
	scatter = Scatter.new({ data: [{ x: 1, y: "one" }, { x: "two", y: 2 }] })
	scatter.to_json().contains("\"x\":[1,\"two\"]") and scatter.to_json().contains("\"y\":[\"one\",2]")
}

## Shared marker fields are written once; differing fields stay per point.
expect {
	big = Marker.new({ size: 12 })?
	scatter = Scatter.new({ data: [{ x: 1, y: 1, text: "a" }, { x: 2, y: 2, marker: big, text: "a" }], mode: Markers })
	decoded : { marker : { color : Str, size : List(F64), symbol : Str }, text : Str }
	decoded = Json.parse(scatter.to_json())?
	decoded == { marker: { color: "rgb(31, 119, 180)", size: [6, 12], symbol: "circle" }, text: "a" }
}

## Points without text omit the text field; differing text stays per point.
expect {
	plain = Scatter.new({ data: [{ x: 1, y: 1 }, { x: 2, y: 2 }] })
	labelled = Scatter.new({ data: [{ x: 1, y: 1, text: "a" }, { x: 2, y: 2 }] })
	decoded : { text : List(Str) }
	decoded = Json.parse(labelled.to_json())?
	!plain.to_json().contains("\"text\"") and decoded.text == ["a", ""]
}

## A gap inserts one null y before its point, repeating that point's x.
expect {
	scatter = Scatter.new({ data: [{ x: 1, y: 1, from_previous: Gap }, { x: 2, y: 2 }, { x: 4, y: 4, from_previous: Gap }] })
	json = scatter.to_json()
	json.contains("\"x\":[1,2,4,4],\"y\":[1,2,null,4]")
}

## Gaps keep per-point marker columns aligned with the coordinates.
expect {
	red = Marker.new({ color: Color.named("red")? })?
	scatter = Scatter.new({ data: [{ x: 1, y: 1 }, { x: 2, y: 2, marker: red, from_previous: Gap }], mode: LinesMarkers })
	decoded : { x : List(F64), marker : { color : List(Str) } }
	decoded = Json.parse(scatter.to_json())?
	decoded == { x: [1, 2, 2], marker: { color: ["rgb(31, 119, 180)", "red", "red"] } }
}

## Fills, fill colors and the WebGL renderer use Plotly's names.
expect {
	filled = Scatter.new({ data: [], fill: ToZeroY, fill_color: Custom(Color.named("navy")?), renderer: WebGl })
	unfilled = Scatter.new({ data: [], fill_color: Custom(Color.named("navy")?) })
	decoded : { type : Str, fill : Str, fillcolor : Str }
	decoded = Json.parse(filled.to_json())?
	decoded == { type: "scattergl", fill: "tozeroy", fillcolor: "navy" } and !unfilled.to_json().contains("fill")
}

## Every fill has its Plotly spelling.
expect {
	actual = [ToZeroY, ToZeroX, ToNextY, ToNextX, ToSelf, ToNext].map_try(
		|fill| {
			decoded : { fill : Str }
			decoded = Json.parse(Scatter.new({ data: [], fill: fill }).to_json())?
			Ok(decoded.fill)
		},
	)?
	actual == ["tozeroy", "tozerox", "tonexty", "tonextx", "toself", "tonext"]
}

## Step shapes reach the trace's line.
expect {
	scatter = Scatter.new({ data: [], line: Line.new({ shape: StepAfter })? })
	decoded : { line : { shape : Str } }
	decoded = Json.parse(scatter.to_json())?
	decoded.line.shape == "hv"
}
