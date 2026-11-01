import Title
import Color
import InternalJson

## Plotly axis settings. Numeric and date bounds are explicit closed cases;
## arbitrary JSON fragments are never accepted as bounds.
Axis :: [Automatic, Explicit(Props)].{
	Type : [Auto, Linear, Log, Date, Category, MultiCategory]
	RangeSpec : [Auto, Fixed, Reversed, Bounds({ min : F64, max : F64 }), DateBounds({ start : Str, end : Str })]
	Props := {
		title : Title ?? Title.default,
		type : Type ?? Auto,
		range : RangeSpec ?? Auto,
		color : Color ?? Color.rgb({ red: 68, green: 68, blue: 68 }),
	}

	default : Axis
	default = Automatic

	## Numeric bounds must be finite. Their order may reverse the axis.
	## Log bounds use Plotly's base-10 exponent convention. Date bounds are
	## ISO date strings interpreted by Plotly.
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

	## Encode an object for composition without accepting raw JSON.
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
								MultiCategory => "multicategory"
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
		{ type: MultiCategory, name: "multicategory" },
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
