module [
    Trace,
    new,
    to_str,
]

import Marker
import Line
import Color

Trace x y := {
    data : List { x : x, y : y, marker : Marker.Marker },
    orientation : [Vertical, Horizontal],
    name : Str,
    line_attrs : List Line.Attr,
    mode : Str,
}
    implements [Inspect]

new :
    {
        data : List { x : x, y : y, marker : Marker.Marker },
        orientation ? [Vertical, Horizontal],
        name ? Str,
        line ? List Line.Attr,
        mode ? Str,
    }
    -> Result (Trace x y) _
new = \{ data, orientation ? Vertical, name ? "", line ? [], mode ? "lines" } ->
    Ok
        (
            @Trace {
                data,
                orientation,
                name,
                line_attrs: line,
                mode: check_valid_mode? mode,
            }
        )

check_valid_mode = \mode ->
    valid_modes = Set.fromList ["lines", "markers", "text"]
    if mode == "none" then
        Ok mode
    else if Str.splitOn mode "+" |> List.all \m -> Set.contains valid_modes m then
        Ok mode
    else
        Err (InvalidMode "Invalid mode: $(mode), expected one of: $(Inspect.toStr valid_modes)")

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

    line_str = Line.from_attrs inner.line_attrs

    mode_str = "\"mode\":\"$(inner.mode)\""

    name_str = if Str.isEmpty inner.name then "" else "\"name\":\"$(inner.name)\""

    [
        "\"x\":[$(x_str)]",
        "\"y\":[$(y_str)]",
        "\"marker\":{$(color_str),$(size_str),$(symbol_str)}",
        "$(line_str)",
        "$(orientation_str)",
        "$(name_str)",
        "$(mode_str)",
        "\"type\":\"scatter\"",
    ]
    |> List.dropIf Str.isEmpty
    |> Str.joinWith ","
    |> \str -> "{$(str)}"
