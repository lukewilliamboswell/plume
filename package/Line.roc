import Color
import InternalJson

## A finite, nonnegative line width and its CSS style.
Line :: Props.{

	## Choose a connected line's dash pattern.
	## `Solid` draws a continuous line. The other tags select dots, short
	## or long dashes, and their combinations in Plotly's canonical order.
	Type : [Solid, Dot, Dash, LongDash, DashDot, LongDashDot]

	## Style the connected segments of a scatter trace.
	## `width` is measured in pixels, must be finite and nonnegative, and
	## defaults to two. Zero hides the stroke. `color` defaults to Plotly
	## blue and `dash` defaults to `Solid`.
	Props := {
		width : F64 ?? 2,
		color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }),
		dash : Type ?? Solid,
	}

	## A solid, two-pixel-wide line in Plotly blue.
	default : Line
	default = Line.({})

	## Validate a line width and construct its style.
	## A negative or nonfinite width returns `InvalidLineWidth(width)`.
	## Zero is accepted for a hidden stroke.
	new : Props -> Try(Line, [InvalidLineWidth(F64)])
	new = |props| if (props.width.is_finite() and props.width >= 0) Ok(Line.(props)) else Err(InvalidLineWidth(props.width))

	## Return the canonical Plotly dash name, such as "longdashdot".
	## Use tags in props; this conversion is useful when inspecting a style.
	dash_to_str : Type -> Str
	dash_to_str = |dash| match dash {
		Solid => "solid"
		Dot => "dot"
		Dash => "dash"
		LongDash => "longdash"
		DashDot => "dashdot"
		LongDashDot => "longdashdot"
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Line.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Line -> InternalJson
	to_json_value = |Line.(props)| InternalJson.object([
		{ name: "width", value: InternalJson.encode(props.width) ?? crash "Line.to_json_value: non-finite width passed constructor" },
		{ name: "color", value: props.color.to_json_value() },
		{ name: "dash", value: InternalJson.string(dash_to_str(props.dash)) },
	])

	## Serialize this validated value as a complete JSON document.
	to_json : Line -> Str
	to_json = |line| line.to_json_value().to_json()
}

## Zero line width is accepted.
expect Line.new({ width: 0 }).is_ok()

## Negative line width is rejected.
expect Line.new({ width: -1 }).is_err()

## NaN line width is rejected.
expect Line.new({ width: F64.nan }).is_err()

## Negative infinite line width is rejected.
expect Line.new({ width: -F64.infinity }).is_err()

## Line width and dash settings survive JSON encoding.
expect {
	line = Line.new({ width: 3, dash: LongDashDot })?
	parsed : { width : F64, dash : Str }
	parsed = Json.parse(line.to_json())?
	parsed == { width: 3, dash: "longdashdot" }
}

## Positive infinity cannot enter a Line.
expect Line.new({ width: F64.infinity }).is_err()

## A zero-width line remains exactly zero in JSON.
expect {
	line = Line.new({ width: 0 })?
	decoded : { width : F64 }
	decoded = Json.parse(line.to_json())?
	decoded.width == 0
}

## All dash styles serialize to their canonical Plotly spellings.
expect {
	var $passed = True
	for row in [
		{ dash: Solid, name: "solid" },
		{ dash: Dot, name: "dot" },
		{ dash: Dash, name: "dash" },
		{ dash: LongDash, name: "longdash" },
		{ dash: DashDot, name: "dashdot" },
		{ dash: LongDashDot, name: "longdashdot" },
	] {
		line = Line.new({ dash: row.dash })?
		decoded : { dash : Str }
		decoded = Json.parse(line.to_json())?
		$passed = $passed and !(decoded.dash != row.name or Line.dash_to_str(row.dash) != row.name)
	}
	$passed
}
