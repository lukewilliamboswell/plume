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

	## Encode an object for composition without accepting raw JSON.
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

	## Serialize this validated value as a complete JSON document.
	to_json : Font -> Str
	to_json = |font| font.to_json_value().to_json()
}

## Inherited fonts serialize as an empty object.
expect Font.default.to_json() == "{}"

## The minimum font size is accepted.
expect Font.new({ size: 1 }).is_ok()

## Sizes below one pixel are rejected.
expect Font.new({ size: 0.999 }).is_err()

## NaN font sizes are rejected.
expect Font.new({ size: F64.nan }).is_err()

## Infinite font sizes are rejected.
expect Font.new({ size: F64.infinity }).is_err()

## Font text and options survive JSON encoding.
expect {
	font = Font.new({ family: "Courier \"New\"\n雪", size: 18, style: Italic, shadow: AutoShadow, textcase: Upper, variant: SmallCaps })?
	parsed : { family : Str, size : F64, style : Str, shadow : Str, textcase : Str, variant : Str }
	parsed = Json.parse(font.to_json())?
	parsed == { family: "Courier \"New\"\n雪", size: 18, style: "italic", shadow: "auto", textcase: "upper", variant: "small-caps" }
}

## Zero and negative font sizes are invalid.
expect Font.new({ size: 0 }).is_err() and Font.new({ size: -1 }).is_err()

## Negative infinity cannot enter a Font.
expect Font.new({ size: -F64.infinity }).is_err()

## The minimum font size is serialized without alteration.
expect {
	font = Font.new({ size: 1 })?
	decoded : { size : F64 }
	decoded = Json.parse(font.to_json())?
	decoded.size == 1
}

## Every supported style, shadow, case and variant maps to Plotly's spelling.
expect {
	var $passed = True
	for row in [{ style: Normal, name: "normal" }, { style: Italic, name: "italic" }] {
		font = Font.new({ style: row.style })?
		decoded : { style : Str }
		decoded = Json.parse(font.to_json())?
		$passed = $passed and !(decoded.style != row.name)
	}
	for row in [{ shadow: NoShadow, name: "none" }, { shadow: AutoShadow, name: "auto" }] {
		font = Font.new({ shadow: row.shadow })?
		decoded : { shadow : Str }
		decoded = Json.parse(font.to_json())?
		$passed = $passed and !(decoded.shadow != row.name)
	}
	for row in [{ textcase: Normal, name: "normal" }, { textcase: Upper, name: "upper" }, { textcase: Lower, name: "lower" }] {
		font = Font.new({ textcase: row.textcase })?
		decoded : { textcase : Str }
		decoded = Json.parse(font.to_json())?
		$passed = $passed and !(decoded.textcase != row.name)
	}
	for row in [
		{ variant: Normal, name: "normal" },
		{ variant: SmallCaps, name: "small-caps" },
		{ variant: PetiteCaps, name: "petite-caps" },
		{ variant: Unicase, name: "unicase" },
		{ variant: AllSmallCaps, name: "all-small-caps" },
		{ variant: AllPetiteCaps, name: "all-petite-caps" },
	] {
		font = Font.new({ variant: row.variant })?
		decoded : { variant : Str }
		decoded = Json.parse(font.to_json())?
		$passed = $passed and !(decoded.variant != row.name)
	}
	$passed
}
