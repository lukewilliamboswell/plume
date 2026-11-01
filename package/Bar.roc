import InternalJson
import Marker

## A validated Plotly bar trace.
Bar :: InternalJson.{
	is_eq : _
	Point(x, y) := { x : x, y : y, marker : Marker ?? Marker.default }
	Props(x, y) := {
		data : List(Point(x, y)),
		orientation : [Vertical, Horizontal] ?? Vertical,
		name : Str ?? "",
		width : F64 ?? 0.75,
	}

	## Construct bars, with width measured in position-axis units.
	new : Props(x, y) -> Try(Bar, [InvalidBarWidth(F64), Infinity, NaN, NegativeInfinity, ..err]) where [x.Json.Encodable([InvalidBarWidth(F64), Infinity, NaN, NegativeInfinity, ..err]), y.Json.Encodable([InvalidBarWidth(F64), Infinity, NaN, NegativeInfinity, ..err])]
	new = |props| {
		width = InternalJson.encode(props.width)?
		if (props.width < 0) return Err(InvalidBarWidth(props.width))
		xs = props.data.map_try(|point| InternalJson.encode(point.x))?
		ys = props.data.map_try(|point| InternalJson.encode(point.y))?
		colors = props.data.map(|point| InternalJson.string(point.marker.get_color().to_css()))
		marker = InternalJson.object([{ name: "color", value: InternalJson.array(colors) }])
		orientation = match props.orientation {
			Vertical => "v"
			Horizontal => "h"
		}
		Ok(
			Bar.(
				InternalJson.object([
					{ name: "type", value: InternalJson.string("bar") },
					{ name: "x", value: InternalJson.array(xs) },
					{ name: "y", value: InternalJson.array(ys) },
					{ name: "marker", value: marker },
					{ name: "orientation", value: InternalJson.string(orientation) },
					{ name: "name", value: InternalJson.string(props.name) },
					{ name: "width", value: width },
				]),
			),
		)
	}

	## The safe JSON object used when composing a chart.
	to_json_value : Bar -> InternalJson
	to_json_value = |Bar.(json)| json

	## Serialize the trace as JSON.
	to_json : Bar -> Str
	to_json = |bar| bar.to_json_value().to_json()
}

## Bar widths use axis units and may exceed one.
expect {
	bar = Bar.new({ data: [{ x: "a", y: 3 }], width: 2 })?
	decoded : { width : F64, x : List(Str), y : List(F64) }
	decoded = Json.parse(bar.to_json())?
	decoded == { width: 2, x: ["a"], y: [3] }
}

## Negative bar widths return a structured error.
expect Bar.new({ data: [{ x: "a", y: 3 }], width: -1 }) == Err(InvalidBarWidth(-1))

## Bar coordinates reject non-finite numbers during construction.
expect Bar.new({ data: [{ x: "a", y: F64.nan }] }) == Err(NaN)
