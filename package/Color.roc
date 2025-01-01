module [
    Color,
    to_str,
]

Color : [
    RGB U8 U8 U8,
    Named Str,
    Hex Str,
]

to_str : Color -> Str
to_str = \color ->
    when color is
        RGB r g b -> "rgb($(Num.toStr r), $(Num.toStr g), $(Num.toStr b))"
        Named name -> name
        Hex hex -> hex

expect to_str (RGB 124 56 245) == "rgb(124, 56, 245)"
