import Color
import InternalJson

## Font overrides. The default inherits Plotly's font settings.
Font :: [Inherit, Explicit(Props)].{
	Props := {
		family : Str ?? "Arial, sans-serif",
		size : F64 ?? 12,
		color : Color ?? Color.rgb({ red: 0, green: 0, blue: 0 }),
		shadow : [NoShadow, AutoShadow] ?? NoShadow,
		style : [Normal, Italic] ?? Normal,
		textcase : [Normal, Upper, Lower] ?? Normal,
		variant : [Normal, SmallCaps, PetiteCaps, Unicase, AllSmallCaps, AllPetiteCaps] ?? Normal,
	}

	default : Font
	default = Inherit

	## Font size must be finite and at least one pixel.
	new : Props -> Try(Font, [InvalidFontSize(F64)])
	new = |props| if (props.size.is_finite() and props.size >= 1) Ok(Explicit(props)) else Err(InvalidFontSize(props.size))

	to_json_value : Font -> InternalJson
	to_json_value = |font| match font {
		Inherit => InternalJson.object([])
		Explicit(props) => InternalJson.object([
			{ name: "family", value: InternalJson.string(props.family) },
			{ name: "size", value: InternalJson.encode(props.size) ?? crash "Font.to_json_value: non-finite size passed constructor" },
			{ name: "color", value: props.color.to_json_value() },
			{
				name: "shadow",
				value: InternalJson.string(
					match props.shadow {
						NoShadow => "none"
						AutoShadow => "auto"
					},
				),
			},
			{
				name: "style",
				value: InternalJson.string(
					match props.style {
						Normal => "normal"
						Italic => "italic"
					},
				),
			},
			{
				name: "textcase",
				value: InternalJson.string(
					match props.textcase {
						Normal => "normal"
						Upper => "upper"
						Lower => "lower"
					},
				),
			},
			{
				name: "variant",
				value: InternalJson.string(
					match props.variant {
						Normal => "normal"
						SmallCaps => "small-caps"
						PetiteCaps => "petite-caps"
						Unicase => "unicase"
						AllSmallCaps => "all-small-caps"
						AllPetiteCaps => "all-petite-caps"
					},
				),
			},
		])
	}

	to_json : Font -> Str
	to_json = |font| font.to_json_value().to_json()
}

expect Font.default.to_json() == "{}"
expect Font.new({ size: 1 }).is_ok()
expect Font.new({ size: 0.999 }).is_err()
expect Font.new({ size: F64.nan }).is_err()
expect Font.new({ size: F64.infinity }).is_err()
expect {
	font = Font.new({ family: "Courier \"New\"\n雪", size: 18, style: Italic, shadow: AutoShadow, textcase: Upper, variant: SmallCaps })?
	parsed : Try({ family : Str, size : F64, style : Str, shadow : Str, textcase : Str, variant : Str }, _)
	parsed = Json.parse(font.to_json())
	parsed == Ok({ family: "Courier \"New\"\n雪", size: 18, style: "italic", shadow: "auto", textcase: "upper", variant: "small-caps" })
}
