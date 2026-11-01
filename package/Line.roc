import Color
import InternalJson

## A finite, nonnegative line width and its CSS style.
Line :: Props.{
	Type : [Solid, Dot, Dash, LongDash, DashDot, LongDashDot]
	Props := {
		width : F64 ?? 2,
		color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }),
		dash : Type ?? Solid,
	}

	default : Line
	default = Line.({})

	## Zero hides the line. Negative and non-finite widths are rejected.
	new : Props -> Try(Line, [InvalidLineWidth(F64)])
	new = |props| if (props.width.is_finite() and props.width >= 0) Ok(Line.(props)) else Err(InvalidLineWidth(props.width))

	dash_to_str : Type -> Str
	dash_to_str = |dash| match dash {
		Solid => "solid"
		Dot => "dot"
		Dash => "dash"
		LongDash => "longdash"
		DashDot => "dashdot"
		LongDashDot => "longdashdot"
	}

	to_json_value : Line -> InternalJson
	to_json_value = |Line.(props)| InternalJson.object([
		{ name: "width", value: InternalJson.encode(props.width) ?? crash "Line.to_json_value: non-finite width passed constructor" },
		{ name: "color", value: props.color.to_json_value() },
		{ name: "dash", value: InternalJson.string(dash_to_str(props.dash)) },
	])
	to_json : Line -> Str
	to_json = |line| line.to_json_value().to_json()
}

expect Line.new({ width: 0 }).is_ok()
expect Line.new({ width: -1 }).is_err()
expect Line.new({ width: F64.nan }).is_err()
expect Line.new({ width: -F64.infinity }).is_err()
expect {
	line = Line.new({ width: 3, dash: LongDashDot })?
	parsed : Try({ width : F64, dash : Str }, _)
	parsed = Json.parse(line.to_json())
	parsed == Ok({ width: 3, dash: "longdashdot" })
}
