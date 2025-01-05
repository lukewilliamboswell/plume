module [
    Line,
    Type,
    new,
    dash_to_str,
    to_str,
]

import Color

Type : [Solid, Dot, Dash, LongDash, DashDot, LongDashDot]

dash_to_str : Type -> Str
dash_to_str = \dash ->
    when dash is
        Solid -> "solid"
        Dot -> "dot"
        Dash -> "dash"
        LongDash -> "longdash"
        DashDot -> "dashdot"
        LongDashDot -> "longdashdot"

Line := {
    width : F32,
    color : Color.Color,
    dash : Type,
}
    implements [Inspect]

new :
    {
        width ? F32,
        color ? Color.Color,
        dash ? Type,
    }
    -> Line
new = \{ width ? 2.0, color ? Color.rgb 31 119 180, dash ? Solid } ->
    @Line { width, color, dash }

to_str : Line -> Str
to_str = \@Line inner ->
    [
        "\"width\":$(Num.toStr inner.width)",
        "\"color\":\"$(Color.to_str inner.color)\"",
        "\"dash\":\"$(dash_to_str inner.dash)\"",
    ]
    |> List.dropIf Str.isEmpty
    |> Str.joinWith ","
    |> \str -> "\"line\":{$(str)}"
