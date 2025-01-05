module [
    Trace,
    new,
    with_name,
    with_bar_width,
    to_str,
]

import Marker
import Color

Trace x y := {
    data : List { x : x, y : y, marker : Marker.Marker },
    orientation : [Vertical, Horizontal],
    name : Str,
    bar_width : F32,
}
    implements [Inspect]

new :
    {
        data : List { x : x, y : y, marker : Marker.Marker },
        orientation ? [Vertical, Horizontal],
        name ? Str,
        bar_width ? F32,
    }
    -> Result (Trace x y) _
new = \{ data, orientation ? Vertical, name ? "", bar_width ? 0.75 } ->
    Ok
        (
            @Trace {
                data,
                orientation,
                name,
                bar_width: check_valid_bar_width? bar_width,
            }
        )

with_name : Trace x y, Str -> Trace x y
with_name = \@Trace trace, name ->
    @Trace { trace & name }

with_bar_width : Trace x y, F32 -> Result (Trace x y) [OutOfRange Str]
with_bar_width = \@Trace trace, bar_width ->
    Ok (@Trace { trace & bar_width: check_valid_bar_width? bar_width })

check_valid_bar_width = \bar_width ->
    if bar_width > 1.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else if bar_width < 0.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else
        Ok bar_width

to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@Trace inner ->

    data = List.walk inner.data { xs: [], ys: [], ms: [] } \state, { x, y, marker } -> {
        xs: List.append state.xs x,
        ys: List.append state.ys y,
        ms: List.append state.ms marker,
    }

    x_str = data.xs |> List.map Inspect.toStr |> Str.joinWith ","
    y_str = data.ys |> List.map Inspect.toStr |> Str.joinWith ","
    color_str =
        data.ms
        |> List.map \marker ->
            marker
            |> Marker.get_color
            |> Color.to_str
            |> \str -> "\"$(str)\""
        |> Str.joinWith ","
        |> \str -> "\"color\":[$(str)]"

    size_str =
        data.ms
        |> List.map \marker -> Marker.get_size marker |> Num.toStr
        |> Str.joinWith ","
        |> \str -> "\"size\":[$(str)]"

    symbol_str =
        data.ms
        |> List.map \marker -> Marker.get_symbol marker |> Inspect.toStr
        |> Str.joinWith ","
        |> \str -> "\"symbol\":[$(str)]"

    orientation_str = if inner.orientation == Vertical then "\"orientation\":\"v\"" else "\"orientation\":\"h\""

    [
        "\"x\":[$(x_str)]",
        "\"y\":[$(y_str)]",
        "\"marker\":{$(color_str),$(size_str),$(symbol_str)}",
        "$(orientation_str)",
        "\"name\":\"$(inner.name)\"",
        "\"width\":$(Num.toStr inner.bar_width)",
        "\"type\":\"bar\"",
    ]
    |> List.dropIf Str.isEmpty
    |> Str.joinWith ","
    |> \str -> "{$(str)}"
