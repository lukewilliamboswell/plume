module [
    Font,
    default,
    new,
    to_str,
]

# https://plotly.com/javascript/reference/layout/

import Color

Style : [Normal, Italic]
TextCase : [Normal, Upper, Lower]
Variant : [Normal, SmallCaps, PetiteCaps, Unicase, AllSmallCaps, AllPetiteCaps]

Font := [
    None,
    Some {
        family : Str,
        size : F32,
        color : Color.Color,
        shadow : [None, Auto],
        style : Style,
        textcase : TextCase,
        variant : Variant,
    },
]
    implements [Inspect]

default : Font
default = @Font None

new :
    {
        family ? Str,
        size ? F32,
        color ? Color.Color,
        shadow ? [None, Auto],
        style ? Style,
        textcase ? TextCase,
        variant ? Variant,
    }
    -> Result Font _
new = \{ family ? "", size ? 12.0, color ? Color.rgb 0 0 0, shadow ? None, style ? Normal, textcase ? Normal, variant ? Normal } ->
    Ok
        (
            @Font
                (
                    Some {
                        family,
                        size: parse_size? size,
                        color,
                        shadow,
                        style,
                        textcase,
                        variant,
                    }
                )
        )

parse_size : F32 -> Result F32 [InvalidSize Str]
parse_size = \f32 ->
    if f32 >= 1.0 then
        Ok f32
    else
        Err (InvalidSize "Font size must be equal to or greater than 1.0")

to_str : Font -> Str
to_str = \@Font maybe_font ->
    when maybe_font is
        None -> ""
        Some inner ->
            fields_str =
                [
                    "\"family\":\"$(inner.family)\"",
                    "\"size\":$(Num.toStr inner.size)",
                    "\"color\":\"$(Color.to_str inner.color)\"",
                    "\"shadow\":\"$(shadow_to_str inner.shadow)\"",
                    "\"style\":\"$(style_to_str inner.style)\"",
                    "\"textcase\":\"$(textcase_to_str inner.textcase)\"",
                    "\"variant\":\"$(variant_to_str inner.variant)\"",
                ]
                |> Str.joinWith ","

            "\"font\":{$(fields_str)}"

shadow_to_str : [None, Auto] -> Str
shadow_to_str = \shadow ->
    when shadow is
        None -> "none"
        Auto -> "auto"

style_to_str : Style -> Str
style_to_str = \style ->
    when style is
        Normal -> "normal"
        Italic -> "italic"

textcase_to_str : TextCase -> Str
textcase_to_str = \textcase ->
    when textcase is
        Normal -> "normal"
        Upper -> "upper"
        Lower -> "lower"

variant_to_str : Variant -> Str
variant_to_str = \variant ->
    when variant is
        Normal -> "normal"
        SmallCaps -> "small-caps"
        PetiteCaps -> "petite-caps"
        Unicase -> "unicase"
        AllSmallCaps -> "all-small-caps"
        AllPetiteCaps -> "all-petite-caps"
