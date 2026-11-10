import Title
import Color
import InternalJson
import Time

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
	## `TimeBounds({ start, end })` supplies validated [Time] endpoints for
	## a date axis. `FromZero` chooses bounds automatically but always
	## includes zero, which suits counts and other nonnegative measures.
	RangeSpec : [Auto, Fixed, Reversed, FromZero, Bounds({ min : F64, max : F64 }), DateBounds({ start : Str, end : Str }), TimeBounds({ start : Time, end : Time })]

	## Choose whether grid lines are drawn at the axis ticks.
	## `Auto` keeps Plotly's choice, which draws them on Cartesian axes.
	Grid : [Auto, Shown, Hidden]

	## Override one axis's scale, range, title, color and tick labels.
	## `type: Auto` omits an explicit scale. `range: Auto` selects automatic
	## bounds. `title` defaults to [Title.default], and `color` defaults to
	## dark gray. Use [Axis.default] to leave the whole axis to Plotly.
	## `tick_format: Pattern(pattern)` formats tick labels with a d3 number
	## pattern such as `".1%"` or `"~s"`, or a d3 time pattern such as
	## `"%H:%M"` on a date axis; Plotly interprets the pattern and Plume
	## does not validate it. `Auto` keeps Plotly's labels. `tick_suffix` is
	## appended to every label, such as `" ms"`, and defaults to none.
	## `grid` selects grid lines.
	Props := {
		title : Title ?? Title.default,
		type : Type ?? Auto,
		range : RangeSpec ?? Auto,
		color : Color ?? Color.rgb({ red: 68, green: 68, blue: 68 }),
		tick_format : [Auto, Pattern(Str)] ?? Auto,
		tick_suffix : Str ?? "",
		grid : Grid ?? Auto,
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
				FromZero => [
					{ name: "autorange", value: InternalJson.encode(Bool.True) ?? crash "Axis.to_json_value: Bool encoding failed" },
					{ name: "rangemode", value: InternalJson.string("tozero") },
				]
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
				TimeBounds(bounds) => [{ name: "range", value: InternalJson.array([InternalJson.string(bounds.start.to_str()), InternalJson.string(bounds.end.to_str())]) }]
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
			tick_fields = match props.tick_format {
				Auto => []
				Pattern(pattern) => [{ name: "tickformat", value: InternalJson.string(pattern) }]
			}
			suffix_fields = if (props.tick_suffix.is_empty()) [] else [{ name: "ticksuffix", value: InternalJson.string(props.tick_suffix) }]
			grid_fields = match props.grid {
				Auto => []
				Shown => [{ name: "showgrid", value: InternalJson.encode(Bool.True) ?? crash "Axis.to_json_value: Bool encoding failed" }]
				Hidden => [{ name: "showgrid", value: InternalJson.encode(Bool.False) ?? crash "Axis.to_json_value: Bool encoding failed" }]
			}
			InternalJson.object(
				range_fields
					.concat(type_fields)
					.concat([
						{ name: "title", value: props.title.to_json_value() },
						{ name: "color", value: props.color.to_json_value() },
					])
					.concat(tick_fields)
					.concat(suffix_fields)
					.concat(grid_fields),
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

## Validated times bound a date axis by their Plotly date text.
expect {
	start = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 9 })?
	end = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 17, minute: 30 })?
	axis = Axis.new({ type: Date, range: TimeBounds({ start, end }) })?
	decoded : { type : Str, range : List(Str) }
	decoded = Json.parse(axis.to_json())?
	decoded == { type: "date", range: ["2026-11-11 09:00", "2026-11-11 17:30"] }
}

## Ranges from zero keep autorange and add Plotly's tozero mode.
expect {
	axis = Axis.new({ range: FromZero })?
	decoded : { autorange : Bool, rangemode : Str }
	decoded = Json.parse(axis.to_json())?
	decoded == { autorange: True, rangemode: "tozero" }
}

## Tick patterns, suffixes and grid choices appear only when set.
expect {
	plain = Axis.new({})?
	styled = Axis.new({ tick_format: Pattern("%H:%M"), tick_suffix: " ms", grid: Hidden })?
	shown = Axis.new({ grid: Shown })?
	decoded : { tickformat : Str, ticksuffix : Str, showgrid : Bool }
	decoded = Json.parse(styled.to_json())?
	actual = [
		Str.inspect(plain.to_json().contains("tick") or plain.to_json().contains("showgrid")),
		Str.inspect(decoded == { tickformat: "%H:%M", ticksuffix: " ms", showgrid: False }),
		Str.inspect(shown.to_json().contains("\"showgrid\":true")),
	]
	actual == ["False", "True", "True"]
}
