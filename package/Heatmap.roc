import InternalJson
import Coordinate

## A validated Plotly heatmap: a grid of finite values drawn as colors.
Heatmap :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## One row of the grid: its y position and one value per x position.
	## `values` must have exactly as many entries as [Heatmap.Props]'s `x`,
	## and each value must be finite.
	Row := { y : Coordinate, values : List(F64) }

	## Plotly's named color scales. `Viridis` and `Cividis` are perceptually
	## uniform and remain readable for most color-vision deficiencies.
	## Plotly defines a few sequential scales, including `YlOrRd`, `YlGnBu`
	## and `Greys`, from dark to light; use `direction: Reversed` when low
	## values should be light.
	ColorScale : [Blackbody, Bluered, Blues, Cividis, Earth, Electric, Greens, Greys, Hot, Jet, Picnic, Portland, Rainbow, RdBu, Reds, Viridis, YlGnBu, YlOrRd]

	## Configure a heatmap.
	## - `x` lists the column positions, and `rows` the rows from bottom to
	##   top; both may be empty. Use [Coordinate.from_time] for instants.
	## - `name` is the legend/hover label, and may be empty.
	## - `color_scale` defaults to `Viridis`; `direction: Reversed` maps
	##   the highest value to the scale's first color instead.
	## - `value_range: Auto` stretches the scale over the data. `Bounds({
	##   min, max })` fixes it, so colors keep their meaning when the data
	##   changes; values beyond the bounds take the end colors.
	## - `color_bar` defaults to `Shown`, drawing the scale beside the grid.
	## - `cell_gap` separates cells by this many pixels, defaulting to zero.
	Props := {
		x : List(Coordinate),
		rows : List(Row),
		name : Str ?? "",
		color_scale : ColorScale ?? Viridis,
		direction : [Normal, Reversed] ?? Normal,
		value_range : [Auto, Bounds({ min : F64, max : F64 })] ?? Auto,
		color_bar : [Shown, Hidden] ?? Shown,
		cell_gap : U8 ?? 0,
	}

	## Validate the grid and construct a heatmap trace.
	## Returns `RowLengthMismatch({ y, expected, actual })` for a row whose
	## value count differs from the number of x positions, `NaN`,
	## `Infinity` or `NegativeInfinity` for a nonfinite value, and
	## `InvalidValueRange({ min, max })` for bounds that are nonfinite or
	## where `min` is not below `max`.
	##
	## ```roc
	## expect {
	##     grid = Heatmap.new({ x: ["09:00", "09:01"], rows: [{ y: "error", values: [3, 0] }] })?
	##     grid.to_json().contains("heatmap")
	## }
	## ```
	new : Props -> Try(Heatmap, [RowLengthMismatch({ y : Coordinate, expected : U64, actual : U64 }), InvalidValueRange({ min : F64, max : F64 }), Infinity, NaN, NegativeInfinity])
	new = |props| {
		columns = props.x.len()
		z = props.rows.map_try(
			|row| {
				if row.values.len() != columns {
					return Err(RowLengthMismatch({ y: row.y, expected: columns, actual: row.values.len() }))
				}
				cells = row.values.map_try(InternalJson.encode)?
				Ok(InternalJson.array(cells))
			},
		)?
		range_fields = match props.value_range {
			Auto => []
			Bounds(bounds) =>
				if bounds.min.is_finite() and bounds.max.is_finite() and bounds.min < bounds.max {
					[
						{ name: "zmin", value: InternalJson.encode(bounds.min)? },
						{ name: "zmax", value: InternalJson.encode(bounds.max)? },
					]
				} else {
					return Err(InvalidValueRange(bounds))
				}
		}
		scale = match props.color_scale {
			Blackbody => "Blackbody"
			Bluered => "Bluered"
			Blues => "Blues"
			Cividis => "Cividis"
			Earth => "Earth"
			Electric => "Electric"
			Greens => "Greens"
			Greys => "Greys"
			Hot => "Hot"
			Jet => "Jet"
			Picnic => "Picnic"
			Portland => "Portland"
			Rainbow => "Rainbow"
			RdBu => "RdBu"
			Reds => "Reds"
			Viridis => "Viridis"
			YlGnBu => "YlGnBu"
			YlOrRd => "YlOrRd"
		}
		direction_fields = match props.direction {
			Normal => []
			Reversed => [{ name: "reversescale", value: InternalJson.encode(Bool.True)? }]
		}
		color_bar_fields = match props.color_bar {
			Shown => []
			Hidden => [{ name: "showscale", value: InternalJson.encode(Bool.False)? }]
		}
		gap_fields = if props.cell_gap == 0 {
			[]
		} else {
			gap = InternalJson.encode(props.cell_gap)?
			[{ name: "xgap", value: gap }, { name: "ygap", value: gap }]
		}
		Ok(
			Heatmap.(
				InternalJson.object(
					[
						{ name: "type", value: InternalJson.string("heatmap") },
						{ name: "x", value: InternalJson.array(props.x.map(Coordinate.to_json_value)) },
						{ name: "y", value: InternalJson.array(props.rows.map(|row| row.y.to_json_value())) },
						{ name: "z", value: InternalJson.array(z) },
						{ name: "name", value: InternalJson.string(props.name) },
						{ name: "colorscale", value: InternalJson.string(scale) },
					]
						.concat(direction_fields)
						.concat(range_fields)
						.concat(color_bar_fields)
						.concat(gap_fields),
				),
			),
		)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Heatmap.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Heatmap -> InternalJson
	to_json_value = |Heatmap.(json)| json

	## Serialize the trace as JSON.
	to_json : Heatmap -> Str
	to_json = |heatmap| heatmap.to_json_value().to_json()
}

## A heatmap encodes its columns, row labels and grid in row order.
expect {
	grid = Heatmap.new({ x: [1, 2], rows: [{ y: "low", values: [0, 1.5] }, { y: "high", values: [2, -3] }] })?
	grid.to_json() ==
		\\{"type":"heatmap","x":[1,2],"y":["low","high"],"z":[[0,1.5],[2,-3]],"name":"","colorscale":"Viridis"}
}

## Optional styling uses Plotly's field names only when set.
expect {
	grid = Heatmap.new({ x: ["a"], rows: [{ y: "b", values: [1] }], color_scale: YlOrRd, direction: Reversed, value_range: Bounds({ min: 0, max: 10 }), color_bar: Hidden, cell_gap: 1 })?
	decoded : { colorscale : Str, reversescale : Bool, zmin : F64, zmax : F64, showscale : Bool, xgap : U8, ygap : U8 }
	decoded = Json.parse(grid.to_json())?
	decoded == { colorscale: "YlOrRd", reversescale: True, zmin: 0, zmax: 10, showscale: False, xgap: 1, ygap: 1 }
}

## A row with the wrong number of values names its row and both counts.
expect {
	result = Heatmap.new({ x: [1, 2, 3], rows: [{ y: "ok", values: [1, 2, 3] }, { y: "short", values: [1] }] })
	result.map_ok(|_| {}) == Err(RowLengthMismatch({ y: "short", expected: 3, actual: 1 }))
}

## Nonfinite cells are rejected.
expect {
	actual = [F64.nan, F64.infinity, -F64.infinity].map(|value| Heatmap.new({ x: [1], rows: [{ y: 1, values: [value] }] }).is_err())
	actual == [True, True, True]
}

## Value ranges must be finite and increasing.
expect {
	ordered = [{ min: 1, max: 1 }, { min: 2, max: 1 }].map(|bounds| Heatmap.new({ x: [], rows: [], value_range: Bounds(bounds) }).map_ok(|_| {}) == Err(InvalidValueRange(bounds)))
	nonfinite = [{ min: F64.nan, max: 1 }, { min: 0, max: F64.infinity }].map(|bounds| Heatmap.new({ x: [], rows: [], value_range: Bounds(bounds) }).is_err())
	ordered == [True, True] and nonfinite == [True, True]
}

## Empty grids are valid.
expect Heatmap.new({ x: [], rows: [] })?.to_json().contains("\"z\":[]")
