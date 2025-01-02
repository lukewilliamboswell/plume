module [
    Attr,
    from_attrs,
    text,
    font,
]

import Font

Attr := [
    Text Str,
    Font (List Font.Attr),
]
    implements [Inspect]

text : Str -> Attr
text = \s -> @Attr (Text s)

font : List Font.Attr -> Attr
font = \font_attrs -> @Attr (Font font_attrs)

from_attrs : List Attr -> Str
from_attrs = \title_attrs ->

    fields_str =
        title_attrs
        |> List.map \@Attr inner ->
            when inner is
                Text s -> "\"text\":\"$(s)\""
                Font font_attrs -> Font.from_attrs font_attrs
        |> Str.joinWith ","

    "\"title\":{$(fields_str)}"
