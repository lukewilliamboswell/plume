import InternalJson

## A validated Plotly pie or donut trace.
Pie :: InternalJson.{
	is_eq : _
	Slice(label) := { label : label, value : F64 }
	Props(label) := { data : List(Slice(label)), hole : F64 ?? 0, name : Str ?? "" }

	## Construct a pie with nonnegative finite values and a hole in [0, 1].
	new : Props(label) -> Try(Pie, [InvalidHole(F64), InvalidPieValue(F64), Infinity, NaN, NegativeInfinity, ..err]) where [label.Json.Encodable([InvalidHole(F64), InvalidPieValue(F64), Infinity, NaN, NegativeInfinity, ..err])]
	new = |props| {
		hole = InternalJson.encode(props.hole)?
		if (props.hole < 0 or props.hole > 1) return Err(InvalidHole(props.hole))
		labels = props.data.map_try(|slice| InternalJson.encode(slice.label))?
		values = props.data.map_try(
			|slice| {
				encoded = InternalJson.encode(slice.value)?
				if (slice.value < 0) Err(InvalidPieValue(slice.value)) else Ok(encoded)
			},
		)?
		Ok(
			Pie.(
				InternalJson.object([
					{ name: "type", value: InternalJson.string("pie") },
					{ name: "labels", value: InternalJson.array(labels) },
					{ name: "values", value: InternalJson.array(values) },
					{ name: "hole", value: hole },
					{ name: "name", value: InternalJson.string(props.name) },
				]),
			),
		)
	}

	## The safe JSON object used when composing a chart.
	to_json_value : Pie -> InternalJson
	to_json_value = |Pie.(json)| json

	## Serialize the trace as JSON.
	to_json : Pie -> Str
	to_json = |pie| pie.to_json_value().to_json()
}

## Pie labels and values preserve their order and escaping.
expect {
	pie = Pie.new({ data: [{ label: "a\"", value: 0 }, { label: "b", value: 2.5 }], hole: 1, name: "pie\n" })?
	decoded : { labels : List(Str), values : List(F64), hole : F64, name : Str }
	decoded = Json.parse(pie.to_json())?
	decoded == { labels: ["a\"", "b"], values: [0, 2.5], hole: 1, name: "pie\n" }
}

## Pie holes outside the closed unit interval fail construction.
expect Pie.new({ data: [{ label: "a", value: 1 }], hole: 1.1 }) == Err(InvalidHole(1.1))

## Negative pie values return a structured error.
expect Pie.new({ data: [{ label: "a", value: -1 }] }) == Err(InvalidPieValue(-1))

## Pie values reject NaN.
expect Pie.new({ data: [{ label: "a", value: F64.nan }] }) == Err(NaN)
