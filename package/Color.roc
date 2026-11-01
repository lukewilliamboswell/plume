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

	to_json : Color -> Str
	to_json = |color| color.to_json_value().to_json()
}

named_colors = ["aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "black", "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "cyan", "darkblue", "darkcyan", "darkgoldenrod", "darkgray", "darkgrey", "darkgreen", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod", "gray", "grey", "green", "greenyellow", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgrey", "lightgreen", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey", "lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "magenta", "maroon", "mediumaquamarine", "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin", "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orange", "orangered", "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum", "powderblue", "purple", "rebeccapurple", "red", "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow", "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen"]

expect Color.rgb({ red: 124, green: 56, blue: 245 }).to_css() == "rgb(124, 56, 245)"
expect Color.rgba({ red: 1, green: 2, blue: 3, alpha: 0 }).to_css() == "rgba(1, 2, 3, 0.0)"
expect Color.rgba({ red: 1, green: 2, blue: 3, alpha: 255 }).to_css() == "rgba(1, 2, 3, 1.0)"
expect Color.hex("#aB09fF").map_ok(Color.to_css) == Ok("#aB09fF")
expect Color.hex("#ff00fg") == Err(InvalidHex("#ff00fg"))
expect Color.hex("#fff") == Err(InvalidHex("#fff"))
expect Color.hex("#ff00ff\n") == Err(InvalidHex("#ff00ff\n"))
expect Color.named("DEEpskyBlue").map_ok(Color.to_css) == Ok("deepskyblue")
expect Color.named("not-a-color") == Err(UnknownColor("not-a-color"))
