import InternalJson
import Color
import Coordinate

## A validated Plotly bar trace.
Bar :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## One bar's axis coordinates and fill color.
	## `x` and `y` accept text or finite numeric [Coordinate] values. For
	## `Vertical`, x locates the bar and y gives its height; `Horizontal`
	## uses x for its length and y for its position. `color` sets this bar's
	## fill and defaults to Plotly blue. Point order is preserved.
	## `base: Origin` starts the bar at zero on its value axis. `At(start)`
	## starts it at `start` instead, so the bar spans from `start` to
	## `start` plus its length: a floating bar, or a timeline entry when
	## `start` comes from [Coordinate.from_time] and the length is a
	## duration in milliseconds on a date axis.
	Point := { x : Coordinate, y : Coordinate, color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }), base : [Origin, At(Coordinate)] ?? Origin }

	## The complete bar series.
	## - `data` contains bars in display order; an empty list is valid.
	## - `orientation` defaults to `Vertical`; `Horizontal` swaps axis roles.
	## - `name` is the legend/hover label, and may be empty.
	## - `width` is measured in position-axis units, defaults to 0.75, and
	##   may exceed one. It must be finite and nonnegative; zero hides bars.
	## When every bar shares a color or base, the output holds that value
	## once instead of repeating it for each bar. Use [Layout.Props]'s
	## `bar_mode` to group, stack or overlay several bar traces.
	Props := {
		data : List(Point),
		orientation : [Vertical, Horizontal] ?? Vertical,
		name : Str ?? "",
		width : F64 ?? 0.75,
	}

	## Validate the width and construct one bar trace.
	## Returns `InvalidBarWidth(width)` for a negative width, or `NaN`,
	## `Infinity`, or `NegativeInfinity` for a nonfinite width. Coordinates
	## are already checked by their opaque type; values and colors retain
	## input order. Use `Bar(trace)` to include the result in [Chart.Props].
	##
	## ```roc
	## expect {
	##     bars = Bar.new({ data: [{ x: "Apples", y: 3 }], name: "Sales" })?
	##     Chart.new({ traces: [Bar(bars)] }).to_json().contains("Sales")
	## }
	## ```
	new : Props -> Try(Bar, [InvalidBarWidth(F64), Infinity, NaN, NegativeInfinity])
	new = |props| {
		width = InternalJson.encode(props.width)?
		if (props.width < 0) return Err(InvalidBarWidth(props.width))
		xs = props.data.map(|point| point.x.to_json_value())
		ys = props.data.map(|point| point.y.to_json_value())
		colors = props.data.map(|point| point.color.to_json_value())
		marker = InternalJson.object([{ name: "color", value: InternalJson.column(colors) }])
		base_fields = if props.data.all(|point| point.base == Origin) {
			[]
		} else {
			bases = props.data.map(
				|point| match point.base {
					Origin => InternalJson.null
					At(start) => start.to_json_value()
				},
			)
			[{ name: "base", value: InternalJson.column(bases) }]
		}
		orientation = match props.orientation {
			Vertical => "v"
			Horizontal => "h"
		}
		Ok(
			Bar.(
				InternalJson.object(
					[
						{ name: "type", value: InternalJson.string("bar") },
						{ name: "x", value: InternalJson.array(xs) },
						{ name: "y", value: InternalJson.array(ys) },
						{ name: "marker", value: marker },
					]
						.concat(base_fields)
						.concat([
							{ name: "orientation", value: InternalJson.string(orientation) },
							{ name: "name", value: InternalJson.string(props.name) },
							{ name: "width", value: width },
						]),
				),
			),
		)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Bar.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
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

## Runtime coordinates pass through the validated Coordinate constructor.
expect {
	coordinate = Coordinate.from_number(2.5)?
	bar = Bar.new({ data: [{ x: "a", y: coordinate }] })?
	decoded : { y : List(F64) }
	decoded = Json.parse(bar.to_json())?
	decoded.y == [2.5]
}

## Bar JSON contains exactly the supported bar properties.
expect {
	bar = Bar.new({ data: [{ x: "x", y: "y" }], orientation: Horizontal, width: 0 })?
	bar.to_json() ==
		\\{"type":"bar","x":["x"],"y":["y"],"marker":{"color":"rgb(31, 119, 180)"},"orientation":"h","name":"","width":0}
}

## Empty typed bar data serializes as empty coordinate and color arrays.
expect {
	points : List(Bar.Point)
	points = []
	bar = Bar.new({ data: points })?
	bar.to_json() ==
		\\{"type":"bar","x":[],"y":[],"marker":{"color":[]},"orientation":"v","name":"","width":0.75}
}

## Bar widths reject both positive and negative infinity.
expect {
	actual = [F64.infinity, -F64.infinity].map(|width| Bar.new({ data: [{ x: "x", y: 0 }], width }).is_err())
	actual == [True, True]
}

## NaN bar widths fail before any trace can be rendered.
expect Bar.new({ data: [{ x: "x", y: 0 }], width: F64.nan }) == Err(NaN)

## Empty bars need no generic coordinate annotation.
expect Bar.new({ data: [] })?.to_json().contains("\"x\":[]")

## Distinct bar colors stay per bar; a shared color is written once.
expect {
	red = Color.named("red")?
	mixed = Bar.new({ data: [{ x: "a", y: 1, color: red }, { x: "b", y: 2 }] })?
	shared = Bar.new({ data: [{ x: "a", y: 1, color: red }, { x: "b", y: 2, color: red }] })?
	mixed_marker : { marker : { color : List(Str) } }
	mixed_marker = Json.parse(mixed.to_json())?
	shared_marker : { marker : { color : Str } }
	shared_marker = Json.parse(shared.to_json())?
	mixed_marker.marker.color == ["red", "rgb(31, 119, 180)"] and shared_marker.marker.color == "red"
}

## Bars from the origin omit base; mixed bases keep null for origin bars.
expect {
	origin = Bar.new({ data: [{ x: 2, y: "a" }], orientation: Horizontal })?
	mixed = Bar.new({ data: [{ x: 2, y: "a", base: At(5) }, { x: 3, y: "b" }], orientation: Horizontal })?
	shared = Bar.new({ data: [{ x: 2, y: "a", base: At("2026-11-11") }, { x: 3, y: "b", base: At("2026-11-11") }], orientation: Horizontal })?
	actual = [origin.to_json().contains("base"), mixed.to_json().contains("\"base\":[5,null]"), shared.to_json().contains("\"base\":\"2026-11-11\"")]
	actual == [False, True, True]
}
