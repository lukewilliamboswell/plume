module [
    Color,
    to_str,
    rgb,
    rgba,
    hex,
    named,
]

Color := [
    RGB U8 U8 U8,
    RGBA U8 U8 U8 Dec,
    Named Str,
    Hex Str,
]
    implements [Inspect]

rgb : U8, U8, U8 -> Color
rgb = |r, g, b| @Color(RGB(r, g, b))

rgba : U8, U8, U8, U8 -> Color
rgba = |r, g, b, a|
    rounded = Num.to_frac(a) / 255.0
    @Color(RGBA(r, g, b, rounded))

hex : Str -> Result Color [InvalidHex Str]
hex = |str|

    bytes = Str.to_utf8(str)
    is_char_in_hex_range = |b| (b >= '0' and b <= '9') or (b >= 'a' and b <= 'f') or (b >= 'A' and b <= 'F')

    when bytes is
        ['#', a, b, c, d, e, f] ->
            is_valid =
                is_char_in_hex_range(a)
                and is_char_in_hex_range(b)
                and is_char_in_hex_range(c)
                and is_char_in_hex_range(d)
                and is_char_in_hex_range(e)
                and is_char_in_hex_range(f)

            if is_valid then
                Ok(@Color(Hex(str)))
            else
                Err(InvalidHex("Expected Hex to be in the range 0-9, a-f, A-F, got ${str}"))

        _ -> Err(InvalidHex("Expected Hex must start with # and be 7 characters long, got ${str}"))

to_str : Color -> Str
to_str = |@Color(color)|
    when color is
        RGB(r, g, b) -> "rgb(${Num.to_str(r)}, ${Num.to_str(g)}, ${Num.to_str(b)})"
        RGBA(r, g, b, a) -> "rgba(${Num.to_str(r)}, ${Num.to_str(g)}, ${Num.to_str(b)}, ${Num.to_str(a)})"
        Named(inner) -> inner
        Hex(inner) -> inner

expect to_str(rgb(124, 56, 245)) == "rgb(124, 56, 245)"
expect to_str(rgba(124, 56, 245, 255)) == "rgba(124, 56, 245, 1.0)"
expect hex("#ff00ff") |> Result.map_ok(to_str) == Ok("#ff00ff")

named : Str -> Result Color [UnknownColor Str]
named = |str|
    if is_named_color(str) then
        Ok(@Color(Named(str)))
    else
        Err(UnknownColor("Unknown color ${str}"))

is_named_color = |str|
    colors = Set.from_list(["AliceBlue", "AntiqueWhite", "Aqua", "Aquamarine", "Azure", "Beige", "Bisque", "Black", "BlanchedAlmond", "Blue", "BlueViolet", "Brown", "BurlyWood", "CadetBlue", "Chartreuse", "Chocolate", "Coral", "CornflowerBlue", "Cornsilk", "Crimson", "Cyan", "DarkBlue", "DarkCyan", "DarkGoldenRod", "DarkGray", "DarkGrey", "DarkGreen", "DarkKhaki", "DarkMagenta", "DarkOliveGreen", "DarkOrange", "DarkOrchid", "DarkRed", "DarkSalmon", "DarkSeaGreen", "DarkSlateBlue", "DarkSlateGray", "DarkSlateGrey", "DarkTurquoise", "DarkViolet", "DeepPink", "DeepSkyBlue", "DimGray", "DimGrey", "DodgerBlue", "FireBrick", "FloralWhite", "ForestGreen", "Fuchsia", "Gainsboro", "GhostWhite", "Gold", "GoldenRod", "Gray", "Grey", "Green", "GreenYellow", "HoneyDew", "HotPink", "IndianRed", "Indigo", "Ivory", "Khaki", "Lavender", "LavenderBlush", "LawnGreen", "LemonChiffon", "LightBlue", "LightCoral", "LightCyan", "LightGoldenRodYellow", "LightGray", "LightGrey", "LightGreen", "LightPink", "LightSalmon", "LightSeaGreen", "LightSkyBlue", "LightSlateGray", "LightSlateGrey", "LightSteelBlue", "LightYellow", "Lime", "LimeGreen", "Linen", "Magenta", "Maroon", "MediumAquaMarine", "MediumBlue", "MediumOrchid", "MediumPurple", "MediumSeaGreen", "MediumSlateBlue", "MediumSpringGreen", "MediumTurquoise", "MediumVioletRed", "MidnightBlue", "MintCream", "MistyRose", "Moccasin", "NavajoWhite", "Navy", "OldLace", "Olive", "OliveDrab", "Orange", "OrangeRed", "Orchid", "PaleGoldenRod", "PaleGreen", "PaleTurquoise", "PaleVioletRed", "PapayaWhip", "PeachPuff", "Peru", "Pink", "Plum", "PowderBlue", "Purple", "RebeccaPurple", "Red", "RosyBrown", "RoyalBlue", "SaddleBrown", "Salmon", "SandyBrown", "SeaGreen", "SeaShell", "Sienna", "Silver", "SkyBlue", "SlateBlue", "SlateGray", "SlateGrey", "Snow", "SpringGreen", "SteelBlue", "Tan", "Teal", "Thistle", "Tomato", "Turquoise", "Violet", "Wheat", "White", "WhiteSmoke", "Yellow", "YellowGreen"])

    Set.contains(colors, str)
