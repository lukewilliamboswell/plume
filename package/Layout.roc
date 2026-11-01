import Title
import Font
import Axis
import InternalJson

## A chart's layout is independent of its trace coordinate types.
Layout :: Props.{
	Props := {
		global_font : Font ?? Font.default,
		title : Title ?? Title.default,
		x_axis : Axis ?? Axis.default,
		y_axis : Axis ?? Axis.default,
		legend : [Shown, Hidden] ?? Hidden,
	}

	new : Props -> Layout
	new = |props| Layout.(props)

	## Title for a generated HTML document, with a display fallback when no
	## explicit title exists. This does not add a Plotly chart title.
	get_title : Layout -> Str
	get_title = |Layout.(props)| props.title.get_text() ?? "My Chart"

	to_json_value : Layout -> InternalJson
	to_json_value = |Layout.(props)| InternalJson.object([
		{ name: "font", value: props.global_font.to_json_value() },
		{ name: "title", value: props.title.to_json_value() },
		{ name: "xaxis", value: props.x_axis.to_json_value() },
		{ name: "yaxis", value: props.y_axis.to_json_value() },
		{ name: "showlegend", value: InternalJson.encode(props.legend == Shown) ?? crash "Layout.to_json_value: Bool encoding failed" },
	])
	to_json : Layout -> Str
	to_json = |layout| layout.to_json_value().to_json()
}

expect Layout.new({}).get_title() == "My Chart"
expect Layout.new({ title: Title.new({ text: "Fruit" }) }).get_title() == "Fruit"
expect {
	parsed : Try({ showlegend : Bool, xaxis : {}, yaxis : {}, title : {}, font : {} }, _)
	parsed = Json.parse(Layout.new({}).to_json())
	parsed == Ok({ showlegend: False, xaxis: {}, yaxis: {}, title: {}, font: {} })
}
expect {
	axis = Axis.new({ type: Linear, range: Bounds({ min: -2, max: 4 }) })?
	layout = Layout.new({ x_axis: axis, legend: Shown })
	parsed : Try({ showlegend : Bool, xaxis : { type : Str, range : List(F64) } }, _)
	parsed = Json.parse(layout.to_json())
	parsed == Ok({ showlegend: True, xaxis: { type: "linear", range: [-2, 4] } })
}
