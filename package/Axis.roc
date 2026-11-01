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

	to_json_value : Axis -> InternalJson
	to_json_value = |axis| match axis {
		Automatic => InternalJson.object([])
		Explicit(props) => {
			range_fields = match props.range {
				Auto => [{ name: "autorange", value: InternalJson.encode(True) ?? crash "Axis.to_json_value: Bool encoding failed" }]
				Fixed => [{ name: "fixedrange", value: InternalJson.encode(True) ?? crash "Axis.to_json_value: Bool encoding failed" }]
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
	to_json : Axis -> Str
	to_json = |axis| axis.to_json_value().to_json()
}

expect Axis.default.to_json() == "{}"
expect Axis.new({ range: Bounds({ min: 0, max: 10 }) }).is_ok()
expect Axis.new({ range: Bounds({ min: 10, max: 0 }) }).is_ok()
expect Axis.new({ range: Bounds({ min: F64.nan, max: 10 }) }).is_err()
expect Axis.new({ range: Bounds({ min: 0, max: F64.infinity }) }).is_err()
expect {
	axis = Axis.new({ type: Date, range: DateBounds({ start: "2026-01-01", end: "2026-12-31" }) })?
	parsed : Try({ type : Str, range : List(Str) }, _)
	parsed = Json.parse(axis.to_json())
	parsed == Ok({ type: "date", range: ["2026-01-01", "2026-12-31"] })
}
expect {
	axis = Axis.new({ range: Reversed })?
	parsed : Try({ autorange : Str }, _)
	parsed = Json.parse(axis.to_json())
	parsed == Ok({ autorange: "reversed" })
}
