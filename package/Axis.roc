import Title
import Color
import InternalJson

## Plotly axis settings. Numeric and date bounds are explicit closed cases;
## arbitrary JSON fragments are never accepted as bounds.
Axis :: [Automatic, Explicit(Props)].{

	## Choose how Plotly interprets coordinates on one axis.
	## `Auto` lets Plotly infer the scale. `Linear` and `Log` use numeric
	## coordinates; `Date` interprets date strings. `Category` uses category
	## labels represented by text coordinates.
	Type : [Auto, Linear, Log, Date, Category]

	## Choose automatic range behavior or explicit bounds.
	## `Auto` lets Plotly choose bounds. `Fixed` disables interactive range
	## changes without selecting bounds. `Reversed` automatically orders
	## bounds in reverse. `Bounds({ min, max })` supplies finite numeric
	## endpoints, whose order may reverse the axis. For a `Log` axis these
	## are base-10 exponents, so 0 to 2 shows values from 1 to 100.
	## `DateBounds({ start, end })` supplies date strings interpreted by
	## Plotly; Plume does not parse or validate their date syntax.
	RangeSpec : [Auto, Fixed, Reversed, Bounds({ min : F64, max : F64 }), DateBounds({ start : Str, end : Str })]

	## Override one axis's scale, range, title and color.
	## `type: Auto` omits an explicit scale. `range: Auto` selects automatic
	## bounds. `title` defaults to [Title.default], and `color` defaults to
	## dark gray. Use [Axis.default] to leave the whole axis to Plotly.
	Props := {
		title : Title ?? Title.default,
		type : Type ?? Auto,
		range : RangeSpec ?? Auto,
		color : Color ?? Color.rgb({ red: 68, green: 68, blue: 68 }),
	}

	## Leave the entire axis at Plotly defaults, encoding an empty object.
	## Unlike [Axis.new] with default props, this adds no range or color
	## overrides.
	default : Axis
	default = Automatic

	## Validate numeric bounds and construct an axis override.
	## Returns `InvalidAxisBounds({ min, max })` if either numeric endpoint
	## is nonfinite. Either endpoint order is accepted. Date bounds remain
	## strings for Plotly to interpret and are not parsed here.
	##
	## ```roc
	## expect {
	##     axis = Axis.new({ type: Log, range: Bounds({ min: 0, max: 2 }) })?
	##     axis.to_json().contains("log")
	## }
	## ```
	new : Props -> Try(Axis, [InvalidAxisBounds({ min : F64, max : F64 })])
	new = |props| match props.range {
		Bounds(bounds) =>
			if bounds.min.is_finite() and bounds.max.is_finite() {
				Ok(Explicit(props))
			} else {
				Err(InvalidAxisBounds(bounds))
			}
		_ => Ok(Explicit(props))
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Axis.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Axis -> InternalJson
	to_json_value = |axis| match axis {
		Automatic => InternalJson.object([])
		Explicit(props) => {
			range_fields = match props.range {
				Auto => [{ name: "autorange", value: InternalJson.encode(Bool.True) ?? crash "Axis.to_json_value: Bool encoding failed" }]
				Fixed => [{ name: "fixedrange", value: InternalJson.encode(Bool.True) ?? crash "Axis.to_json_value: Bool encoding failed" }]
				Reversed => [{ name: "autorange", value: InternalJson.string("reversed") }]
				Bounds(bounds) => [
					{
						name: "range",
						value: InternalJson.array([
							InternalJson.encode(bounds.min) ?? crash "Axis.to_json_value: non-finite minimum passed constructor",
							InternalJson.encode(bounds.max) ?? crash "Axis.to_json_value: non-finite maximum passed constructor",
						]),
					},
				]
				DateBounds(bounds) => [{ name: "range", value: InternalJson.array([InternalJson.string(bounds.start), InternalJson.string(bounds.end)]) }]
			}
			type_fields = match props.type {
				Auto => []
				_ => [
					{
						name: "type",
						value: InternalJson.string(
							match props.type {
								Auto => crash "Axis.to_json_value: Auto type was already handled"
								Linear => "linear"
								Log => "log"
								Date => "date"
								Category => "category"
							},
						),
					},
				]
			}
			InternalJson.object(
				range_fields.concat(type_fields).concat([
					{ name: "title", value: props.title.to_json_value() },
					{ name: "color", value: props.color.to_json_value() },
				]),
			)
		}
	}

	## Serialize this validated value as a complete JSON document.
	to_json : Axis -> Str
	to_json = |axis| axis.to_json_value().to_json()
}

## Automatic axes serialize as an empty object.
expect Axis.default.to_json() == "{}"

## Finite numeric ranges are accepted.
expect Axis.new({ range: Bounds({ min: 0, max: 10 }) }).is_ok()

## Reversed numeric ranges are accepted.
expect Axis.new({ range: Bounds({ min: 10, max: 0 }) }).is_ok()

## NaN numeric bounds are rejected.
expect Axis.new({ range: Bounds({ min: F64.nan, max: 10 }) }).is_err()

## Infinite numeric bounds are rejected.
expect Axis.new({ range: Bounds({ min: 0, max: F64.infinity }) }).is_err()

## Date ranges retain their endpoint strings.
expect {
	axis = Axis.new({ type: Date, range: DateBounds({ start: "2026-01-01", end: "2026-12-31" }) })?
	parsed : { type : Str, range : List(Str) }
	parsed = Json.parse(axis.to_json())?
	parsed == { type: "date", range: ["2026-01-01", "2026-12-31"] }
}

## A reversed automatic range uses Plotly autorange.
expect {
	axis = Axis.new({ range: Reversed })?
	parsed : { autorange : Str }
	parsed = Json.parse(axis.to_json())?
	parsed == { autorange: "reversed" }
}

## Negative infinity in either numeric endpoint is invalid.
expect Axis.new({ range: Bounds({ min: -F64.infinity, max: 0 }) }).is_err() and Axis.new({ range: Bounds({ min: 0, max: -F64.infinity }) }).is_err()

## Every explicit axis type has the corresponding Plotly spelling.
expect {
	var $passed = True
	for row in [
		{ type: Linear, name: "linear" },
		{ type: Log, name: "log" },
		{ type: Date, name: "date" },
		{ type: Category, name: "category" },
	] {
		axis = Axis.new({ type: row.type })?
		decoded : { type : Str }
		decoded = Json.parse(axis.to_json())?
		$passed = $passed and !(decoded.type != row.name)
	}
	$passed
}

## Automatic axis type defers to Plotly without a type field.
expect {
	axis = Axis.new({})?
	axis.to_json() == "{\"autorange\":true,\"title\":{},\"color\":\"rgb(68, 68, 68)\"}"
}

## Fixed ranges set fixedrange without inventing numeric bounds.
expect {
	axis = Axis.new({ range: Fixed })?
	decoded : { fixedrange : Bool }
	decoded = Json.parse(axis.to_json())?
	decoded.fixedrange
}

## Reversed numeric bounds and a zero-width range are preserved exactly.
expect {
	var $passed = True
	for bounds in [{ min: 10, max: 0 }, { min: 0, max: 0 }] {
		axis = Axis.new({ range: Bounds(bounds) })?
		decoded : { range : List(F64) }
		decoded = Json.parse(axis.to_json())?
		$passed = $passed and !(decoded.range != [bounds.min, bounds.max])
	}
	$passed
}
