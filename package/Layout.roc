import Title
import Font
import Axis
import InternalJson

## A chart's layout is independent of its trace coordinate types.
Layout :: Props.{

	## Configure shared chart presentation.
	## `global_font` supplies text styling for the chart; `title` supplies
	## its visible title. `x_axis` and `y_axis` configure Cartesian axes.
	## Their defaults inherit Plotly settings. `legend: Hidden` suppresses
	## the legend by default; use `Shown` to display trace names.
	Props := {
		global_font : Font ?? Font.default,
		title : Title ?? Title.default,
		x_axis : Axis ?? Axis.default,
		y_axis : Axis ?? Axis.default,
		legend : [Shown, Hidden] ?? Hidden,
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
	to_json_value = |Layout.(props)| InternalJson.object([
		{ name: "font", value: props.global_font.to_json_value() },
		{ name: "title", value: props.title.to_json_value() },
		{ name: "xaxis", value: props.x_axis.to_json_value() },
		{ name: "yaxis", value: props.y_axis.to_json_value() },
		{ name: "showlegend", value: InternalJson.encode(props.legend == Shown) ?? crash "Layout.to_json_value: Bool encoding failed" },
	])

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
