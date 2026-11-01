import InternalJson
import Marker
import Line

## A validated Plotly scatter, line, text, or bubble trace.
Scatter :: InternalJson.{
	is_eq : _
	Point(x, y) := { x : x, y : y, marker : Marker ?? Marker.default, text : Str ?? "" }
	Mode : [Lines, Markers, Text, LinesMarkers, LinesText, MarkersText, LinesMarkersText, Hidden]
	Props(x, y) := {
		data : List(Point(x, y)),
		orientation : [Vertical, Horizontal] ?? Vertical,
		name : Str ?? "",
		line : Line ?? Line.default,
		mode : Mode ?? Lines,
	}

	## Encode coordinates once and preserve point order.
	new : Props(x, y) -> Try(Scatter, [Infinity, NaN, NegativeInfinity, ..err]) where [x.Json.Encodable([Infinity, NaN, NegativeInfinity, ..err]), y.Json.Encodable([Infinity, NaN, NegativeInfinity, ..err])]
	new = |props| {
		xs = props.data.map_try(|point| InternalJson.encode(point.x))?
		ys = props.data.map_try(|point| InternalJson.encode(point.y))?
		colors = props.data.map(|point| InternalJson.string(point.marker.get_color().to_css()))
		sizes = props.data.map_try(|point| InternalJson.encode(point.marker.get_size()))?
		symbols = props.data.map(|point| InternalJson.string(point.marker.get_symbol()))
		texts = props.data.map(|point| InternalJson.string(point.text))
		marker = InternalJson.object([
			{ name: "color", value: InternalJson.array(colors) },
			{ name: "size", value: InternalJson.array(sizes) },
			{ name: "symbol", value: InternalJson.array(symbols) },
		])
		orientation = match props.orientation {
			Vertical => "v"
			Horizontal => "h"
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
		Ok(
			Scatter.(
				InternalJson.object([
					{ name: "type", value: InternalJson.string("scatter") },
					{ name: "x", value: InternalJson.array(xs) },
					{ name: "y", value: InternalJson.array(ys) },
					{ name: "marker", value: marker },
					{ name: "text", value: InternalJson.array(texts) },
					{ name: "orientation", value: InternalJson.string(orientation) },
					{ name: "name", value: InternalJson.string(props.name) },
					{ name: "line", value: props.line.to_json_value() },
					{ name: "mode", value: InternalJson.string(mode) },
				]),
			),
		)
	}

	## The safe JSON object used when composing a chart.
	to_json_value : Scatter -> InternalJson
	to_json_value = |Scatter.(json)| json

	## Serialize the trace as JSON.
	to_json : Scatter -> Str
	to_json = |scatter| scatter.to_json_value().to_json()
}

## Scatter text and names round trip through JSON escaping.
expect {
	scatter = Scatter.new({ data: [{ x: "a\"", y: 2, text: "line\n雪" }], mode: LinesMarkersText, name: "x\\y" })?
	decoded : { x : List(Str), text : List(Str), name : Str, mode : Str }
	decoded = Json.parse(scatter.to_json())?
	decoded == { x: ["a\""], text: ["line\n雪"], name: "x\\y", mode: "lines+markers+text" }
}

## Scatter coordinates reject infinity before serialization.
expect Scatter.new({ data: [{ x: 1, y: F64.infinity }] }) == Err(Infinity)

## Scatter JSON includes exactly its point arrays and presentation settings.
expect {
	scatter = Scatter.new({ data: [{ x: "x", y: "y" }] })?
	scatter.to_json() ==
		\\{"type":"scatter","x":["x"],"y":["y"],"marker":{"color":["rgb(31, 119, 180)"],"size":[6],"symbol":["circle"]},"text":[""],"orientation":"v","name":"","line":{"width":2,"color":"rgb(31, 119, 180)","dash":"solid"},"mode":"lines"}
}

## Every scatter mode maps to one canonical Plotly flag list.
expect {
	actual = [Lines, Markers, Text, LinesMarkers, LinesText, MarkersText, LinesMarkersText, Hidden].map_try(
		|mode| {
			scatter = Scatter.new({ data: [{ x: 1, y: 2 }], mode })?
			decoded : { mode : Str }
			decoded = Json.parse(scatter.to_json())?
			Ok(decoded.mode)
		},
	)?
	actual == ["lines", "markers", "text", "lines+markers", "lines+text", "markers+text", "lines+markers+text", "none"]
}

## Negative infinity in an x coordinate fails construction.
expect Scatter.new({ data: [{ x: -F64.infinity, y: 2 }] }) == Err(NegativeInfinity)
