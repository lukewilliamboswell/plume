import InternalJson

## A validated Plotly pie or donut trace.
Pie :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## A displayed label and its nonnegative numeric contribution.
	## `label` is text. `value` must be a finite F64 at least zero; [Pie.new]
	## checks it before constructing the trace. Slice order is preserved.
	Slice := { label : Str, value : F64 }

	## Configure a pie or donut series.
	## `data` contains ordered slices and may be empty. `hole` defaults to
	## zero for a pie; a value strictly between zero and one makes a donut,
	## and one leaves no filled area. `name` is the legend/hover label.
	Props := { data : List(Slice), hole : F64 ?? 0, name : Str ?? "" }

	## Validate every slice and construct a pie or donut trace.
	## `hole` must be finite and in the closed interval [0, 1]. Each slice
	## value must be finite and nonnegative. Negative values return
	## `InvalidPieValue(value)`; an out-of-range hole returns
	## `InvalidHole(hole)`. Nonfinite inputs return `NaN`, `Infinity`, or
	## `NegativeInfinity`. Zero-valued slices and empty data are accepted.
	##
	## ```roc
	## expect {
	##     donut = Pie.new({ data: [{ label: "Rent", value: 1200 }], hole: 0.4 })?
	##     donut.to_json().contains("Rent")
	## }
	## ```
	new : Props -> Try(Pie, [InvalidHole(F64), InvalidPieValue(F64), Infinity, NaN, NegativeInfinity])
	new = |props| {
		hole = InternalJson.encode(props.hole)?
		if (props.hole < 0 or props.hole > 1) return Err(InvalidHole(props.hole))
		labels = props.data.map(|slice| InternalJson.string(slice.label))
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

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Pie.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
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

## Pie JSON is a complete object with aligned label and value arrays.
expect {
	pie = Pie.new({ data: [{ label: "slice", value: 2 }] })?
	pie.to_json() ==
		\\{"type":"pie","labels":["slice"],"values":[2],"hole":0,"name":""}
}

## The lower hole boundary is accepted and negative holes are rejected.
expect Pie.new({ data: [{ label: "a", value: 0 }], hole: -0.1 }) == Err(InvalidHole(-0.1))

## Pie hole settings reject every non-finite value.
expect {
	actual = [F64.nan, F64.infinity, -F64.infinity].map(|hole| Pie.new({ data: [{ label: "a", value: 0 }], hole }).is_err())
	actual == [True, True, True]
}

## Empty typed pies produce valid empty arrays.
expect {
	slices : List(Pie.Slice)
	slices = []
	pie = Pie.new({ data: slices })?
	pie.to_json() ==
		\\{"type":"pie","labels":[],"values":[],"hole":0,"name":""}
}

## Empty pies need no generic label annotation.
expect Pie.new({ data: [] })?.to_json().contains("\"labels\":[]")
