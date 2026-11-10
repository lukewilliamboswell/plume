import InternalJson
import Color
import Coordinate
import Line

## A reference line or shaded band drawn across the plotting area, such as
## an incident on a timeline or a target value. Add shapes to a chart with
## [Layout.Props]'s `shapes`.
Shape :: InternalJson.{

	## Compare the encoded shape, including all style settings.
	is_eq : _

	## Where the shape lies, in the coordinates of the x or y axis.
	## `VerticalLine(x)` crosses the full height of the plotting area at
	## `x`, and `HorizontalLine(y)` crosses its full width at `y`.
	## `VerticalBand({ start, end })` shades the full height between two x
	## positions, and `HorizontalBand({ start, end })` the full width
	## between two y positions. Use [Coordinate.from_time] for instants.
	Placement : [
		VerticalLine(Coordinate),
		HorizontalLine(Coordinate),
		VerticalBand({ start : Coordinate, end : Coordinate }),
		HorizontalBand({ start : Coordinate, end : Coordinate }),
	]

	## Choose whether the shape is drawn over or under the traces.
	Layer : [Above, Below]

	## Configure one shape.
	## - `placement` is required.
	## - `line` styles a line placement and defaults to [Line.default]. A
	##   line's `shape` setting does not apply to a straight reference line.
	##   Bands are drawn without an outline.
	## - `fill` colors a band and defaults to translucent gray.
	## - `label` is text written beside the shape, and defaults to none:
	##   to the right of a vertical line's top, above a horizontal line's
	##   right end and inside a band's top-left corner. Plotly interprets its
	##   supported text markup.
	## - `layer` defaults to `Above` for lines and is usually `Below` for
	##   bands, so that the shading does not cover the data.
	Props := {
		placement : Placement,
		line : Line ?? Line.default,
		fill : Color ?? Color.rgba({ red: 128, green: 128, blue: 128, alpha: 51 }),
		label : Str ?? "",
		layer : Layer ?? Above,
	}

	## Construct a shape from already validated coordinates and styles.
	## This function is infallible.
	##
	## ```roc
	## expect {
	##     incident = Shape.new({ placement: VerticalLine("2026-11-11 12:05"), label: "Deploy" })
	##     incident.to_json().contains("Deploy")
	## }
	## ```
	new : Props -> Shape
	new = |props| {
		paper_start = InternalJson.encode(0.U8) ?? crash "Shape.new: U8 encoding failed"
		paper_end = InternalJson.encode(1.U8) ?? crash "Shape.new: U8 encoding failed"
		no_outline = InternalJson.object([{ name: "width", value: paper_start }])
		geometry = match props.placement {
			VerticalLine(x) => { kind: "line", x_ref: "x", y_ref: "paper", x0: x.to_json_value(), x1: x.to_json_value(), y0: paper_start, y1: paper_end, style: [{ name: "line", value: props.line.to_json_value() }], label_style: [{ name: "textposition", value: InternalJson.string("end") }, { name: "textangle", value: paper_start }, { name: "xanchor", value: InternalJson.string("left") }] }
			HorizontalLine(y) => { kind: "line", x_ref: "paper", y_ref: "y", x0: paper_start, x1: paper_end, y0: y.to_json_value(), y1: y.to_json_value(), style: [{ name: "line", value: props.line.to_json_value() }], label_style: [{ name: "textposition", value: InternalJson.string("end") }] }
			VerticalBand({ start, end }) => { kind: "rect", x_ref: "x", y_ref: "paper", x0: start.to_json_value(), x1: end.to_json_value(), y0: paper_start, y1: paper_end, style: [{ name: "line", value: no_outline }, { name: "fillcolor", value: props.fill.to_json_value() }], label_style: [{ name: "textposition", value: InternalJson.string("top left") }] }
			HorizontalBand({ start, end }) => { kind: "rect", x_ref: "paper", y_ref: "y", x0: paper_start, x1: paper_end, y0: start.to_json_value(), y1: end.to_json_value(), style: [{ name: "line", value: no_outline }, { name: "fillcolor", value: props.fill.to_json_value() }], label_style: [{ name: "textposition", value: InternalJson.string("top left") }] }
		}
		label_fields = if props.label.is_empty() {
			[]
		} else {
			[{ name: "label", value: InternalJson.object([{ name: "text", value: InternalJson.string(props.label) }].concat(geometry.label_style)) }]
		}
		layer = match props.layer {
			Above => "above"
			Below => "below"
		}
		Shape.(
			InternalJson.object(
				[
					{ name: "type", value: InternalJson.string(geometry.kind) },
					{ name: "xref", value: InternalJson.string(geometry.x_ref) },
					{ name: "yref", value: InternalJson.string(geometry.y_ref) },
					{ name: "x0", value: geometry.x0 },
					{ name: "x1", value: geometry.x1 },
					{ name: "y0", value: geometry.y0 },
					{ name: "y1", value: geometry.y1 },
					{ name: "layer", value: InternalJson.string(layer) },
				]
					.concat(geometry.style)
					.concat(label_fields),
			),
		)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Shape.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Shape -> InternalJson
	to_json_value = |Shape.(json)| json

	## Serialize the shape as JSON.
	to_json : Shape -> Str
	to_json = |shape| shape.to_json_value().to_json()
}

## A vertical line spans the plotting area's height at one x position.
expect {
	shape = Shape.new({ placement: VerticalLine(5) })
	shape.to_json() ==
		\\{"type":"line","xref":"x","yref":"paper","x0":5,"x1":5,"y0":0,"y1":1,"layer":"above","line":{"width":2,"color":"rgb(31, 119, 180)","dash":"solid"}}
}

## A horizontal band shades between two y positions without an outline.
expect {
	shape = Shape.new({ placement: HorizontalBand({ start: 90, end: 100 }), layer: Below, label: "Target" })
	shape.to_json() ==
		\\{"type":"rect","xref":"paper","yref":"y","x0":0,"x1":1,"y0":90,"y1":100,"layer":"below","line":{"width":0},"fillcolor":"rgba(128, 128, 128, 0.2)","label":{"text":"Target","textposition":"top left"}}
}

## Horizontal lines and vertical bands use the matching axis references.
expect {
	line : { xref : Str, yref : Str, y0 : F64, y1 : F64 }
	line = Json.parse(Shape.new({ placement: HorizontalLine(2.5) }).to_json())?
	band : { xref : Str, yref : Str, x0 : Str, x1 : Str, type : Str }
	band = Json.parse(Shape.new({ placement: VerticalBand({ start: "2026-11-11 12:00", end: "2026-11-11 12:30" }) }).to_json())?
	line == { xref: "paper", yref: "y", y0: 2.5, y1: 2.5 } and band == { xref: "x", yref: "paper", x0: "2026-11-11 12:00", x1: "2026-11-11 12:30", type: "rect" }
}

## Labels survive JSON escaping.
expect {
	decoded : { label : { text : Str } }
	decoded = Json.parse(Shape.new({ placement: VerticalLine("a"), label: "</script>\"雪" }).to_json())?
	decoded.label.text == "</script>\"雪"
}

## Vertical line labels read horizontally to the right of the line's top.
expect {
	decoded : { label : { text : Str, textposition : Str, textangle : F64, xanchor : Str } }
	decoded = Json.parse(Shape.new({ placement: VerticalLine(1), label: "Deploy" }).to_json())?
	decoded.label == { text: "Deploy", textposition: "end", textangle: 0, xanchor: "left" }
}
