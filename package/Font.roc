module [
    Attr,
    from_attrs,
    family,
    size,
    color,
    shadow,
    style,
    textcase,
    variant,
]

# https://plotly.com/javascript/reference/layout/

import Color

Attr := [
    Family Str,
    Size F32,
    Color Color.Color,
    Shadow [None, Auto],
    Style [Normal, Italic],
    TextCase [Normal, Upper, Lower],
    Variant [Normal, SmallCaps, PetiteCaps, Unicase, AllSmallCaps, AllPetiteCaps],
]
    implements [Inspect]

## HTML font family - the typeface that will be applied by the web browser
family : Str -> Attr
family = \s -> @Attr (Family s)

## Font size
size : F32 -> Result Attr [InvalidSize Str]
size = \f32 ->
    if f32 >= 1.0 then
        Ok (@Attr (Size f32))
    else
        Err (InvalidSize "Font size must be equal to or greater than 1.0")

color : Color.Color -> Attr
color = \c -> @Attr (Color c)

## Sets the shape and color of the shadow behind text.
## `Auto` places minimal shadow and applies contrast text font color.
## See https://developer.mozilla.org/en-US/docs/Web/CSS/text-shadow for additional options.
## Default `None`
shadow : [None, Auto] -> Attr
shadow = \s -> @Attr (Shadow s)

## Sets whether a font should be styled with a normal or italic face from its family.
## Default `Normal`
style : [Normal, Italic] -> Attr
style = \s -> @Attr (Style s)

## Sets capitalization of text. It can be used to make text appear in all-uppercase or all-lowercase.
## Default `Normal`
textcase : [Normal, Upper, Lower] -> Attr
textcase = \s -> @Attr (TextCase s)

## Sets the variant of the font.
## Default `Normal`
variant : [Normal, SmallCaps, PetiteCaps, Unicase, AllSmallCaps, AllPetiteCaps] -> Attr
variant = \s -> @Attr (Variant s)

# internal use
from_attrs : List Attr -> Str
from_attrs = \attrs ->
    if List.isEmpty attrs then
        ""
    else
        fields_str =
            attrs
            |> List.map \@Attr inner ->
                when inner is
                    Family s -> "\"family\":\"$(s)\""
                    Size s -> "\"size\":$(Num.toStr s)"
                    Color c -> "\"color\":\"$(Color.to_str c)\""
                    Shadow s ->
                        when s is
                            None -> "\"shadow\":\"none\""
                            Auto -> "\"shadow\":\"auto\""

                    Style s ->
                        when s is
                            Normal -> "\"style\":\"normal\""
                            Italic -> "\"style\":\"italic\""

                    TextCase s ->
                        when s is
                            Normal -> "\"textcase\":\"normal\""
                            Upper -> "\"textcase\":\"upper\""
                            Lower -> "\"textcase\":\"lower\""

                    Variant s ->
                        when s is
                            Normal -> "\"variant\":\"normal\""
                            SmallCaps -> "\"variant\":\"small-caps\""
                            PetiteCaps -> "\"variant\":\"petite-caps\""
                            Unicase -> "\"variant\":\"unicase\""
                            AllSmallCaps -> "\"variant\":\"all-small-caps\""
                            AllPetiteCaps -> "\"variant\":\"all-petite-caps\""

            |> Str.joinWith ","

        "\"font\":{$(fields_str)}"
