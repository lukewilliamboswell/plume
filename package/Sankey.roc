import InternalJson
import Color

## A Sankey flow diagram whose endpoints are checked at construction.
Sankey :: InternalJson.{
	is_eq : _
	Node := { id : Str, label : Str, color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }), hover : [Default, Text(Str)] ?? Default }
	Link := { source : Str, target : Str, value : F64, hover : [Default, Text(Str)] ?? Default }
	Props := { nodes : List(Node), links : List(Link), orientation : [Vertical, Horizontal] ?? Horizontal, name : Str ?? "" }

	## Node identities are distinct from display labels, which may repeat.
	new : Props -> Try(Sankey, [DuplicateNode(Str), MissingSource(Str), MissingTarget(Str), InvalidLinkValue(F64), Infinity, NaN, NegativeInfinity])
	new = |props| {
		var $indexes = Dict.empty()
		initial_index : U64
		initial_index = 0
		var $node_index = initial_index
		for node in props.nodes {
			if $indexes.contains(node.id) {
				return Err(DuplicateNode(node.id))
			}
			$indexes = $indexes.insert(node.id, $node_index)
			$node_index = $node_index + 1
		}
		indexes = $indexes
		sources = props.links.map_try(
			|link| {
				source = indexes.get(link.source) ? |_| MissingSource(link.source)
				InternalJson.encode(source)
			},
		)?
		target_indices = props.links.map_try(
			|link| {
				target = indexes.get(link.target) ? |_| MissingTarget(link.target)
				InternalJson.encode(target)
			},
		)?
		values = props.links.map_try(
			|link| {
				encoded = InternalJson.encode(link.value)?
				if (link.value < 0) Err(InvalidLinkValue(link.value)) else Ok(encoded)
			},
		)?
		nodes = InternalJson.object(
			[
				{ name: "label", value: InternalJson.array(props.nodes.map(|node| InternalJson.string(node.label))) },
				{ name: "color", value: InternalJson.array(props.nodes.map(|node| node.color.to_json_value())) },
			].concat(hover_fields(props.nodes.map(|node| node.hover))),
		)
		links = InternalJson.object(
			[
				{ name: "source", value: InternalJson.array(sources) },
				{ name: "target", value: InternalJson.array(target_indices) },
				{ name: "value", value: InternalJson.array(values) },
			].concat(hover_fields(props.links.map(|link| link.hover))),
		)
		orientation = match props.orientation {
			Horizontal => "h"
			Vertical => "v"
		}
		Ok(
			Sankey.(
				InternalJson.object([
					{ name: "type", value: InternalJson.string("sankey") },
					{ name: "node", value: nodes },
					{ name: "link", value: links },
					{ name: "orientation", value: InternalJson.string(orientation) },
					{ name: "arrangement", value: InternalJson.string("snap") },
					{ name: "name", value: InternalJson.string(props.name) },
				]),
			),
		)
	}

	## The safe JSON object used when composing a chart.
	to_json_value : Sankey -> InternalJson
	to_json_value = |Sankey.(json)| json

	## Serialize the trace as JSON.
	to_json : Sankey -> Str
	to_json = |sankey| sankey.to_json_value().to_json()
}

## Sankey endpoints resolve identities, preserving repeated display labels.
expect {
	sankey = Sankey.new({
		nodes: [{ id: "b", label: "same" }, { id: "a", label: "same" }],
		links: [{ source: "a", target: "b", value: 2.5, hover: Text("quote\"\n") }],
		orientation: Vertical,
	})?
	decoded : { node : { label : List(Str) }, link : { source : List(U64), target : List(U64), value : List(F64), customdata : List(Str) }, orientation : Str }
	decoded = Json.parse(sankey.to_json())?
	decoded == { node: { label: ["same", "same"] }, link: { source: [1], target: [0], value: [2.5], customdata: ["quote\"\n"] }, orientation: "v" }
}

## Duplicate identities fail construction instead of crashing during rendering.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "a", label: "B" }], links: [] }) == Err(DuplicateNode("a"))

## Unknown link sources return a structured error.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "missing", target: "a", value: 1 }] }) == Err(MissingSource("missing"))

## Unknown link targets return a structured error.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "missing", value: 1 }] }) == Err(MissingTarget("missing"))

## Negative flows fail construction.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value: -1 }] }) == Err(InvalidLinkValue(-1))

## Infinite flows fail construction.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value: F64.infinity }] }) == Err(Infinity)

## Sankey JSON preserves source order and validates numeric values once.
expect {
	sankey = Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "b", label: "B" }], links: [{ source: "a", target: "b", value: 0 }] })?
	sankey.to_json() ==
		\\{"type":"sankey","node":{"label":["A","B"],"color":["rgb(31, 119, 180)","rgb(31, 119, 180)"]},"link":{"source":[0],"target":[1],"value":[0]},"orientation":"h","arrangement":"snap","name":""}
}

## An empty Sankey remains a valid complete trace.
expect {
	sankey = Sankey.new({ nodes: [], links: [] })?
	decoded : { node : { label : List(Str) }, link : { source : List(U64), target : List(U64), value : List(F64) } }
	decoded = Json.parse(sankey.to_json())?
	decoded == { node: { label: [] }, link: { source: [], target: [], value: [] } }
}

## NaN and negative-infinite flows cannot become JSON numbers.
expect {
	actual = [F64.nan, -F64.infinity].map(|value| Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value }] }).is_err())
	actual == [True, True]
}

hover_fields : List([Default, Text(Str)]) -> List({ name : Str, value : InternalJson })
hover_fields = |hovers| {
	has_text = hovers.any(
		|hover| match hover {
			Default => False
			Text(_) => True
		},
	)
	if !has_text {
		return []
	}
	texts = hovers.map(
		|hover| match hover {
			Default => InternalJson.string("")
			Text(text) => InternalJson.string(text)
		},
	)
	templates = hovers.map(
		|hover| match hover {
			Default => InternalJson.string("")
			Text(_) => InternalJson.string("%{customdata}<extra></extra>")
		},
	)
	[
		{ name: "customdata", value: InternalJson.array(texts) },
		{ name: "hovertemplate", value: InternalJson.array(templates) },
	]
}

## Hover text overrides only explicitly configured nodes and links.
expect {
	sankey = Sankey.new({
		nodes: [{ id: "a", label: "A", hover: Text("quoted \"text\"") }, { id: "b", label: "B" }],
		links: [{ source: "a", target: "b", value: 1 }],
	})?
	decoded : { node : { customdata : List(Str), hovertemplate : List(Str) }, link : { source : List(U64), target : List(U64), value : List(F64) } }
	decoded = Json.parse(sankey.to_json())?
	decoded == {
		node: { customdata: ["quoted \"text\"", ""], hovertemplate: ["%{customdata}<extra></extra>", ""] },
		link: { source: [0], target: [1], value: [1] },
	}
}
