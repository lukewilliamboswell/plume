module [
    Attr,
    size,
    color,
    from_attrs,
]

import Color

Attr := [
    Size F32,
    Color Color.Color,
]
    implements [Inspect]

size : F32 -> Attr
size = \f32 -> @Attr (Size f32)

color : Color.Color -> Attr
color = \c -> @Attr (Color c)

from_attrs : List Attr -> Str
from_attrs = \attrs ->

    fields_str =
        attrs
        |> List.map \@Attr inner ->
            when inner is
                Size s -> "\"size\":$(Num.toStr s)"
                Color c -> "\"color\":\"$(Color.to_str c)\""
        |> Str.joinWith ","

    "\"marker\":{$(fields_str)}"
