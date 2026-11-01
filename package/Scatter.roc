import InternalJson
import Marker
import Line
import Coordinate

## A validated Plotly scatter, line, text, or bubble trace.
Scatter :: InternalJson.{
	is_eq : _
	Point := { x : Coordinate, y : Coordinate, marker : Marker ?? Marker.default, text : Str ?? "" }
	Mode : [Lines, Markers, Text, LinesMarkers, LinesText, MarkersText, LinesMarkersText, Hidden]
	Props := {
		data : List(Point),
		name : Str ?? "",
		line : Line ?? Line.default,
		mode : Mode ?? Lines,
	}

	## Encode coordinates once and preserve point order.
	new : Props -> Scatter
	new = |props| {
		xs = props.data.map(|point| point.x.to_json_value())
		ys = props.data.map(|point| point.y.to_json_value())
		colors = props.data.map(|point| InternalJson.string(point.marker.get_color().to_css()))
		sizes = props.data.map(|point| InternalJson.encode(point.marker.get_size()) ?? crash "Scatter.new: opaque Marker accepted a non-finite size")
		symbols = props.data.map(|point| InternalJson.string(point.marker.get_symbol()))
		texts = props.data.map(|point| InternalJson.string(point.text))
		marker = InternalJson.object([
			{ name: "color", value: InternalJson.array(colors) },
			{ name: "size", value: InternalJson.array(sizes) },
			{ name: "symbol", value: InternalJson.array(symbols) },
		])
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
		Scatter.(
			InternalJson.object([
				{ name: "type", value: InternalJson.string("scatter") },
				{ name: "x", value: InternalJson.array(xs) },
				{ name: "y", value: InternalJson.array(ys) },
				{ name: "marker", value: marker },
				{ name: "text", value: InternalJson.array(texts) },
				{ name: "name", value: InternalJson.string(props.name) },
				{ name: "line", value: props.line.to_json_value() },
				{ name: "mode", value: InternalJson.string(mode) },
			]),
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
	scatter = Scatter.new({ data: [{ x: "a\"", y: 2, text: "line\n雪" }], mode: LinesMarkersText, name: "x\\y" })
	decoded : { x : List(Str), text : List(Str), name : Str, mode : Str }
	decoded = Json.parse(scatter.to_json())?
	decoded == { x: ["a\""], text: ["line\n雪"], name: "x\\y", mode: "lines+markers+text" }
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
		\\{"type":"scatter","x":["x"],"y":["y"],"marker":{"color":["rgb(31, 119, 180)"],"size":[6],"symbol":["circle"]},"text":[""],"name":"","line":{"width":2,"color":"rgb(31, 119, 180)","dash":"solid"},"mode":"lines"}
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
