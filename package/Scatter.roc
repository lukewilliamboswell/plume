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
    line : Line.Line,
    mode : Str,
}
    implements [Inspect]

new :
    {
        data : List { x : x, y : y, marker : Marker.Marker },
        orientation ?? [Vertical, Horizontal],
        name ?? Str,
        line ?? Line.Line,
        mode ?? Str,
    }
    -> Result (Trace x y) _
new = |{ data, orientation ?? Vertical, name ?? "", line ?? Line.new({}), mode ?? "lines" }|
    Ok(
        @Trace(
            {
                data,
                orientation,
                name,
                line,
                mode: check_valid_mode(mode)?,
            },
        ),
    )

check_valid_mode = |mode|
    valid_modes = Set.from_list(["lines", "markers", "text"])
    if mode == "none" then
        Ok(mode)
    else if Str.split_on(mode, "+") |> List.all(|m| Set.contains(valid_modes, m)) then
        Ok(mode)
    else
        Err(InvalidMode("Invalid mode: ${mode}, expected one of: ${Inspect.to_str(valid_modes)}"))

to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = |@Trace(inner)|

    data = List.walk(
        inner.data,
        { xs: [], ys: [], ms: [] },
        |state, { x, y, marker }| {
            xs: List.append(state.xs, x),
            ys: List.append(state.ys, y),
            ms: List.append(state.ms, marker),
        },
    )

    x_str = data.xs |> List.map(Inspect.to_str) |> Str.join_with(",")
    y_str = data.ys |> List.map(Inspect.to_str) |> Str.join_with(",")
    color_str =
        data.ms
        |> List.map(
            |marker|
                marker
                |> Marker.get_color
                |> Color.to_str
                |> |str| "\"${str}\"",
        )
        |> Str.join_with(",")
        |> |str| "\"color\":[${str}]"

    size_str =
        data.ms
        |> List.map(|marker| Marker.get_size(marker) |> Num.to_str)
        |> Str.join_with(",")
        |> |str| "\"size\":[${str}]"

    symbol_str =
        data.ms
        |> List.map(|marker| Marker.get_symbol(marker) |> Inspect.to_str)
        |> Str.join_with(",")
        |> |str| "\"symbol\":[${str}]"

    orientation_str = if inner.orientation == Vertical then "\"orientation\":\"v\"" else "\"orientation\":\"h\""

    line_str = Line.to_str(inner.line)

    mode_str = "\"mode\":\"${inner.mode}\""

    name_str = if Str.is_empty(inner.name) then "" else "\"name\":\"${inner.name}\""

    [
        "\"x\":[${x_str}]",
        "\"y\":[${y_str}]",
        "\"marker\":{${color_str},${size_str},${symbol_str}}",
        "${line_str}",
        "${orientation_str}",
        "${name_str}",
        "${mode_str}",
        "\"type\":\"scatter\"",
    ]
    |> List.drop_if(Str.is_empty)
    |> Str.join_with(",")
    |> |str| "{${str}}"
