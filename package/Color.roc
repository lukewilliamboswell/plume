import InternalJson

## A validated CSS color. RGB channels and alpha use bytes in the range 0–255.
Color :: Str.{
	is_eq : _
	to_hash : _

	## Construct an opaque RGB color.
	rgb : { red : U8, green : U8, blue : U8 } -> Color
	rgb = |{ red, green, blue }| Color.("rgb(${red.to_str()}, ${green.to_str()}, ${blue.to_str()})")

	## Alpha 0 is transparent and 255 is opaque.
	rgba : { red : U8, green : U8, blue : U8, alpha : U8 } -> Color
	rgba = |{ red, green, blue, alpha }| {
		fraction = alpha.to_dec() / 255
		Color.("rgba(${red.to_str()}, ${green.to_str()}, ${blue.to_str()}, ${fraction.to_str()})")
	}

	## Parse exactly six hexadecimal digits preceded by #.
	hex : Str -> Try(Color, [InvalidHex(Str)])
	hex = |text| match text.to_utf8() {
		['#', a, b, c, d, e, f] =>
			if [a, b, c, d, e, f].all(|byte| (byte >= '0' and byte <= '9') or (byte >= 'a' and byte <= 'f') or (byte >= 'A' and byte <= 'F')) {
				Ok(Color.(text))
			} else {
				Err(InvalidHex(text))
			}
		_ => Err(InvalidHex(text))
	}

	## Parse a CSS named color, independent of ASCII case.
	named : Str -> Try(Color, [UnknownColor(Str)])
	named = |text| {
		lower = text.with_ascii_lowercased()
		if (named_colors.contains(lower)) Ok(Color.(lower)) else Err(UnknownColor(text))
	}

	## Read the CSS value for use in a stylesheet or Plotly field.
	to_css : Color -> Str
	to_css = |Color.(text)| text

	## Encode the CSS color as a JSON string.
	to_json_value : Color -> InternalJson
	to_json_value = |color| InternalJson.string(color.to_css())

	## Serialize this validated value as a complete JSON document.
	to_json : Color -> Str
	to_json = |color| color.to_json_value().to_json()
}

named_colors = ["aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "black", "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "cyan", "darkblue", "darkcyan", "darkgoldenrod", "darkgray", "darkgrey", "darkgreen", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod", "gray", "grey", "green", "greenyellow", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgrey", "lightgreen", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey", "lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "magenta", "maroon", "mediumaquamarine", "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin", "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orange", "orangered", "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum", "powderblue", "purple", "rebeccapurple", "red", "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow", "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen"]

## RGB channels format as CSS.
expect Color.rgb({ red: 124, green: 56, blue: 245 }).to_css() == "rgb(124, 56, 245)"

## Zero alpha is fully transparent.
expect Color.rgba({ red: 1, green: 2, blue: 3, alpha: 0 }).to_css() == "rgba(1, 2, 3, 0.0)"

## Full alpha is opaque.
expect Color.rgba({ red: 1, green: 2, blue: 3, alpha: 255 }).to_css() == "rgba(1, 2, 3, 1.0)"

## Mixed-case six-digit hex colors are accepted.
expect Color.hex("#aB09fF")?.to_css() == "#aB09fF"

## Nonhexadecimal digits are rejected.
expect Color.hex("#ff00fg") == Err(InvalidHex("#ff00fg"))

## Short hex colors are rejected.
expect Color.hex("#fff") == Err(InvalidHex("#fff"))

## Trailing content in a hex color is rejected.
expect Color.hex("#ff00ff\n") == Err(InvalidHex("#ff00ff\n"))

## Named colors ignore ASCII case.
expect Color.named("DEEpskyBlue")?.to_css() == "deepskyblue"

## Unknown named colors preserve the offending input.
expect Color.named("not-a-color") == Err(UnknownColor("not-a-color"))

## Named colors all round-trip through the public CSS representation.
expect {
	var $passed = True
	for name in named_colors {
		color = Color.named(name)?
		decoded : Str
		decoded = Json.parse(color.to_json())?
		$passed = $passed and !(decoded != name)
	}
	$passed
}

## RGB channel endpoints are preserved exactly.
expect Color.rgb({ red: 0, green: 255, blue: 0 }).to_css() == "rgb(0, 255, 0)"

## Intermediate alpha is fractional and round-trips as a CSS string.
expect {
	color = Color.rgba({ red: 0, green: 128, blue: 255, alpha: 128 })
	decoded : Str
	decoded = Json.parse(color.to_json())?
	decoded == color.to_css() and decoded != "rgba(0, 128, 255, 0.0)" and decoded != "rgba(0, 128, 255, 1.0)"
}
