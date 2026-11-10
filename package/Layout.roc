import Title
import Font
import Axis
import InternalJson
import Size
import Shape

## A chart's layout is independent of its trace coordinate types.
Layout :: Props.{

	## Choose how several bar traces share a position.
	## `Group` places them side by side, `Stack` piles them up, `Overlay`
	## draws them over each other (use translucent colors), and `Relative`
	## stacks positive values upwards and negative values downwards.
	BarMode : [Group, Stack, Overlay, Relative]

	## Choose what the pointer reveals.
	## `Auto` keeps Plotly's default, the closest point. `Closest` names it
	## explicitly. `X` and `Y` show every trace's point at the pointer's x or
	## y position in separate labels; `XUnified` and `YUnified` gather them
	## into one label, which suits time series. `Off` disables hover labels.
	HoverMode : [Auto, Closest, X, Y, XUnified, YUnified, Off]

	## Choose where the legend sits when it is shown.
	## `Auto` keeps Plotly's position, to the right of the plotting area.
	## `Above` and `Below` lay the entries out in a row above or below it,
	## which leaves the plotting area its full width. The `Inside` corners
	## place the legend over the plotting area.
	LegendPosition : [Auto, Above, Below, InsideTopLeft, InsideTopRight, InsideBottomLeft, InsideBottomRight]

	## Choose what happens to the viewer's zoom, pan, selections and hidden
	## traces when an application draws an updated figure in the same chart
	## with Plotly's `react`. `ResetOnUpdate` draws exactly the new figure.
	## `Preserve(revision)` keeps the viewer's changes while `revision` stays
	## the same; change the revision to reset them deliberately, such as
	## when the chart switches to a different dataset.
	UiRevision : [ResetOnUpdate, Preserve(Str)]

	## Configure shared chart presentation.
	## `global_font` supplies text styling for the chart; `title` supplies
	## its visible title. `x_axis` and `y_axis` configure Cartesian axes.
	## Their defaults inherit Plotly settings. `legend: Hidden` suppresses
	## the legend by default; use `Shown` to display trace names, and
	## `legend_position` to place it. `size` sets pixel dimensions and
	## margins, defaulting to [Size.default]. `bar_mode` defaults to
	## `Group`, `hover_mode` to `Auto` and `ui_revision` to
	## `ResetOnUpdate`. `shapes` adds reference lines and bands, drawn in
	## list order, and defaults to none.
	Props := {
		global_font : Font ?? Font.default,
		title : Title ?? Title.default,
		x_axis : Axis ?? Axis.default,
		y_axis : Axis ?? Axis.default,
		legend : [Shown, Hidden] ?? Hidden,
		legend_position : LegendPosition ?? Auto,
		size : Size ?? Size.default,
		bar_mode : BarMode ?? Group,
		hover_mode : HoverMode ?? Auto,
		ui_revision : UiRevision ?? ResetOnUpdate,
		shapes : List(Shape) ?? [],
	}

	## Construct a layout from already validated settings.
	## This function is infallible. Combine [Title.new], [Font.new] and
	## [Axis.new] when the corresponding presentation needs an override.
	new : Props -> Layout
	new = |props| Layout.(props)

	## Title for a generated HTML document, with a display fallback when no
	## explicit title exists. This does not add a Plotly chart title.
	get_title : Layout -> Str
	get_title = |Layout.(props)| props.title.get_text() ?? "My Chart"

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Layout.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Layout -> InternalJson
	to_json_value = |Layout.(props)| {
		number = |value| InternalJson.encode(value) ?? crash "Layout.to_json_value: finite constant encoding failed"
		legend_fields = match props.legend_position {
			Auto => []
			Above => [{ name: "legend", value: InternalJson.object([{ name: "orientation", value: InternalJson.string("h") }, { name: "x", value: number(0.F64) }, { name: "xanchor", value: InternalJson.string("left") }, { name: "y", value: number(1.02.F64) }, { name: "yanchor", value: InternalJson.string("bottom") }]) }]
			Below => [{ name: "legend", value: InternalJson.object([{ name: "orientation", value: InternalJson.string("h") }]) }]
			InsideTopLeft => [{ name: "legend", value: InternalJson.object([{ name: "x", value: number(0.01.F64) }, { name: "xanchor", value: InternalJson.string("left") }, { name: "y", value: number(0.99.F64) }, { name: "yanchor", value: InternalJson.string("top") }]) }]
			InsideTopRight => [{ name: "legend", value: InternalJson.object([{ name: "x", value: number(0.99.F64) }, { name: "xanchor", value: InternalJson.string("right") }, { name: "y", value: number(0.99.F64) }, { name: "yanchor", value: InternalJson.string("top") }]) }]
			InsideBottomLeft => [{ name: "legend", value: InternalJson.object([{ name: "x", value: number(0.01.F64) }, { name: "xanchor", value: InternalJson.string("left") }, { name: "y", value: number(0.01.F64) }, { name: "yanchor", value: InternalJson.string("bottom") }]) }]
			InsideBottomRight => [{ name: "legend", value: InternalJson.object([{ name: "x", value: number(0.99.F64) }, { name: "xanchor", value: InternalJson.string("right") }, { name: "y", value: number(0.01.F64) }, { name: "yanchor", value: InternalJson.string("bottom") }]) }]
		}
		bar_mode_fields = match props.bar_mode {
			Group => []
			Stack => [{ name: "barmode", value: InternalJson.string("stack") }]
			Overlay => [{ name: "barmode", value: InternalJson.string("overlay") }]
			Relative => [{ name: "barmode", value: InternalJson.string("relative") }]
		}
		hover_mode_fields = match props.hover_mode {
			Auto => []
			Closest => [{ name: "hovermode", value: InternalJson.string("closest") }]
			X => [{ name: "hovermode", value: InternalJson.string("x") }]
			Y => [{ name: "hovermode", value: InternalJson.string("y") }]
			XUnified => [{ name: "hovermode", value: InternalJson.string("x unified") }]
			YUnified => [{ name: "hovermode", value: InternalJson.string("y unified") }]
			Off => [{ name: "hovermode", value: InternalJson.encode(Bool.False) ?? crash "Layout.to_json_value: Bool encoding failed" }]
		}
		revision_fields = match props.ui_revision {
			ResetOnUpdate => []
			Preserve(revision) => [{ name: "uirevision", value: InternalJson.string(revision) }]
		}
		shape_fields = if (props.shapes.is_empty()) [] else [{ name: "shapes", value: InternalJson.array(props.shapes.map(Shape.to_json_value)) }]
		InternalJson.object(
			[
				{ name: "font", value: props.global_font.to_json_value() },
				{ name: "title", value: props.title.to_json_value() },
				{ name: "xaxis", value: props.x_axis.to_json_value() },
				{ name: "yaxis", value: props.y_axis.to_json_value() },
				{ name: "showlegend", value: InternalJson.encode(props.legend == Shown) ?? crash "Layout.to_json_value: Bool encoding failed" },
			]
				.concat(legend_fields)
				.concat(props.size.to_json_fields())
				.concat(bar_mode_fields)
				.concat(hover_mode_fields)
				.concat(revision_fields)
				.concat(shape_fields),
		)
	}

	## Serialize this validated value as a complete JSON document.
	to_json : Layout -> Str
	to_json = |layout| layout.to_json_value().to_json()
}

## A missing title gets the HTML display fallback.
expect Layout.new({}).get_title() == "My Chart"

## Explicit titles are available to the HTML document.
expect Layout.new({ title: Title.new({ text: "Fruit" }) }).get_title() == "Fruit"

## Default layout fields encode as valid JSON values.
expect {
	parsed : { showlegend : Bool, xaxis : {}, yaxis : {}, title : {}, font : {} }
	parsed = Json.parse(Layout.new({}).to_json())?
	parsed == { showlegend: False, xaxis: {}, yaxis: {}, title: {}, font: {} }
}

## Axis bounds and explicit legend settings compose into a layout.
expect {
	axis = Axis.new({ type: Linear, range: Bounds({ min: -2, max: 4 }) })?
	layout = Layout.new({ x_axis: axis, legend: Shown })
	parsed : { showlegend : Bool, xaxis : { type : Str, range : List(F64) } }
	parsed = Json.parse(layout.to_json())?
	parsed == { showlegend: True, xaxis: { type: "linear", range: [-2, 4] } }
}

## An explicit empty title stays empty at the HTML title boundary.
expect Layout.new({ title: Title.new({ text: "" }) }).get_title() == ""

## Default presentation settings add no layout fields.
expect Layout.new({}).to_json() == "{\"font\":{},\"title\":{},\"xaxis\":{},\"yaxis\":{},\"showlegend\":false}"

## Size, bar mode, hover mode, revision and shapes use Plotly's names.
expect {
	size = Size.new({ height: Pixels(300), margin: Pixels({ left: 40, right: 10, top: 10, bottom: 30 }) })?
	layout = Layout.new({
		size,
		bar_mode: Stack,
		hover_mode: XUnified,
		ui_revision: Preserve("orders"),
		shapes: [Shape.new({ placement: VerticalLine(3) })],
	})
	decoded : { height : U16, margin : { l : U16, r : U16, t : U16, b : U16 }, barmode : Str, hovermode : Str, uirevision : Str, shapes : List({ type : Str, x0 : F64 }) }
	decoded = Json.parse(layout.to_json())?
	decoded == { height: 300, margin: { l: 40, r: 10, t: 10, b: 30 }, barmode: "stack", hovermode: "x unified", uirevision: "orders", shapes: [{ type: "line", x0: 3 }] }
}

## Every bar mode and hover mode has its Plotly spelling.
expect {
	bar_modes = [Group, Stack, Overlay, Relative].map(|bar_mode| Layout.new({ bar_mode: bar_mode }).to_json())
	hover_modes = [Auto, Closest, X, Y, XUnified, YUnified, Off].map(|hover_mode| Layout.new({ hover_mode: hover_mode }).to_json())
	actual = {
		bar: bar_modes.map(|json| json.contains("barmode")),
		stack: bar_modes.map(|json| json.contains("\"barmode\":\"stack\"")),
		overlay: bar_modes.map(|json| json.contains("\"barmode\":\"overlay\"")),
		relative: bar_modes.map(|json| json.contains("\"barmode\":\"relative\"")),
		hover: hover_modes.map(|json| json.contains("hovermode")),
		spelled: [
			hover_modes.get(1) == Ok("{\"font\":{},\"title\":{},\"xaxis\":{},\"yaxis\":{},\"showlegend\":false,\"hovermode\":\"closest\"}"),
			hover_modes.get(2).map_ok(|json| json.contains("\"hovermode\":\"x\"")) == Ok(True),
			hover_modes.get(3).map_ok(|json| json.contains("\"hovermode\":\"y\"")) == Ok(True),
			hover_modes.get(5).map_ok(|json| json.contains("\"hovermode\":\"y unified\"")) == Ok(True),
			hover_modes.get(6).map_ok(|json| json.contains("\"hovermode\":false")) == Ok(True),
		],
	}
	actual == {
		bar: [False, True, True, True],
		stack: [False, True, False, False],
		overlay: [False, False, True, False],
		relative: [False, False, False, True],
		hover: [False, True, True, True, True, True, True],
		spelled: [True, True, True, True, True],
	}
}

## Legend positions place a horizontal or inside legend by its anchors.
expect {
	positions = [Auto, Above, Below, InsideTopLeft, InsideTopRight, InsideBottomLeft, InsideBottomRight].map(|legend_position| Layout.new({ legend: Shown, legend_position }).to_json())
	actual = positions.map(|json| json.contains("\"legend\":"))
	above : { legend : { orientation : Str, y : F64, yanchor : Str } }
	above = Json.parse(positions.get(1)?)?
	inside : { legend : { x : F64, xanchor : Str, y : F64, yanchor : Str } }
	inside = Json.parse(positions.get(6)?)?
	actual == [False, True, True, True, True, True, True] and above.legend == { orientation: "h", y: 1.02, yanchor: "bottom" } and inside.legend == { x: 0.99, xanchor: "right", y: 0.01, yanchor: "bottom" }
}
