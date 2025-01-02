module [
    Attr,
    width,
    color,
    dash,
    from_attrs,
]

import Color

Attr := [
    Width F32,
    Color Color.Color,
    Dash Str,
]
    implements [Inspect]

width : F32 -> Attr
width = \f32 -> @Attr (Width f32)

color : Color.Color -> Attr
color = \c -> @Attr (Color c)

dash : Str -> Result Attr [InvalidDash Str]
dash = \str ->
    valid = Set.fromList ["solid", "dot", "dash", "longdash", "dashdot", "longdashdot"]

    if Set.contains valid str then
        Ok (@Attr (Dash str))
    else
        Err (InvalidDash "Invalid dash style $(str), expected one of: $(Inspect.toStr valid)")

from_attrs : List Attr -> Str
from_attrs = \attrs ->

    fields_str =
        attrs
        |> List.map \@Attr inner ->
            when inner is
                Width s -> "\"width\":$(Num.toStr s)"
                Dash s -> "\"dash\":\"$(s)\""
                Color c -> "\"color\":\"$(Color.to_str c)\""
        |> Str.joinWith ","

    "\"line\":{$(fields_str)}"
