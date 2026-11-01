import InternalJson
import Color

## A Sankey flow diagram whose endpoints are checked at construction.
Sankey :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## One flow endpoint, with identity separate from its display text.
	## `id` must be unique within the trace; links refer to this exact string.
	## `label` is visible text and may be shared by multiple nodes. `color`
	## defaults to Plotly blue. `hover: Default` preserves Plotly's hover
	## information; `Text(text)` replaces it for this node. Hover text uses
	## Plotly's supported markup rules.
	Node := { id : Str, label : Str, color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }), hover : [Default, Text(Str)] ?? Default }

	## One directed flow between distinct node IDs.
	## `source` and `target` must match existing [Sankey.Node] IDs. `value`
	## is finite and nonnegative; zero is accepted. `hover: Default` keeps
	## Plotly's hover information, while `Text(text)` supplies an override.
	## Cycles through distinct nodes are supported; self-links are rejected.
	Link := { source : Str, target : Str, value : F64, hover : [Default, Text(Str)] ?? Default }

	## Configure a flow diagram.
	## `nodes` defines stable output order; labels need not be unique.
	## `links` resolves IDs against those nodes and retains input order.
	## `orientation` defaults to `Horizontal` for left-to-right flow; use
	## `Vertical` for top-to-bottom flow. `name` is the trace label. Both
	## lists may be empty, but every supplied link needs valid endpoints.
	Props := { nodes : List(Node), links : List(Link), orientation : [Vertical, Horizontal] ?? Horizontal, name : Str ?? "" }

	## Validate identities, endpoints and amounts before constructing a trace.
	## Returns `DuplicateNode(id)` for repeated IDs, `MissingSource(id)` or
	## `MissingTarget(id)` for absent endpoints, and `SelfLink(id)` when a
	## link points back to the same node. Negative amounts return
	## `InvalidLinkValue(value)`; nonfinite amounts return `NaN`, `Infinity`,
	## or `NegativeInfinity`. Rendering a successfully constructed trace
	## performs no further graph validation.
	##
	## ```roc
	## expect {
	##     flow = Sankey.new({
	##         nodes: [{ id: "income", label: "Income" }, { id: "rent", label: "Rent" }],
	##         links: [{ source: "income", target: "rent", value: 1200 }],
	##     })?
	##     flow.to_json().contains("Income")
	## }
	## ```
	new : Props -> Try(Sankey, [DuplicateNode(Str), MissingSource(Str), MissingTarget(Str), SelfLink(Str), InvalidLinkValue(F64), Infinity, NaN, NegativeInfinity])
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
				if (link.value < 0) return Err(InvalidLinkValue(link.value))
				if (link.source == link.target) Err(SelfLink(link.source)) else Ok(encoded)
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

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Sankey.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
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

## Self-links cannot produce valid geometry in the pinned Plotly renderer.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value: 1 }] }) == Err(SelfLink("a"))

## Zero-valued self-links are rejected consistently.
expect Sankey.new({ nodes: [{ id: "a", label: "A" }], links: [{ source: "a", target: "a", value: 0 }] }) == Err(SelfLink("a"))

## Cycles through distinct nodes remain valid flow graphs.
expect {
	sankey = Sankey.new({ nodes: [{ id: "a", label: "A" }, { id: "b", label: "B" }], links: [{ source: "a", target: "b", value: 1 }, { source: "b", target: "a", value: 1 }] })?
	decoded : { link : { source : List(U64), target : List(U64) } }
	decoded = Json.parse(sankey.to_json())?
	decoded == { link: { source: [0, 1], target: [1, 0] } }
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
