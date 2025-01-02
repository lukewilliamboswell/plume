module [
    Attr,
    from_attrs,
    family,
    size,
    color,
]

import Color

Attr := [
    Family Str,
    Size F32,
    Color Color.Color,
]
    implements [Inspect]

family : Str -> Attr
family = \s -> @Attr (Family s)

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
                Family s -> "\"family\":\"$(s)\""
                Size s -> "\"size\":$(Num.toStr s)"
                Color c -> "\"color\":\"$(Color.to_str c)\""
        |> Str.joinWith ","

    "\"font\":{$(fields_str)}"
