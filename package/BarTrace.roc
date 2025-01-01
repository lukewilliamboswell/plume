module [
    BarTrace,
    new,
    with_color,
    with_name,
    with_bar_width,
    to_str,
]

import Color exposing [Color]

BarTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    color : Color,
    name : Str,
    bar_width: F32,
}

new : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @BarTrace {
        xy,
        orientation: Vertical,
        color: RGB 124 56 245,
        name : "",
        bar_width: 0.5,
    }

with_color : BarTrace x y, Color -> BarTrace x y
with_color = \@BarTrace trace, color ->
    @BarTrace { trace & color }

with_name : BarTrace x y, Str -> BarTrace x y
with_name = \@BarTrace trace, name ->
    @BarTrace { trace & name }

with_bar_width : BarTrace x y, F32 -> BarTrace x y
with_bar_width = \@BarTrace trace, bar_width ->
    @BarTrace { trace & bar_width }

to_str : BarTrace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@BarTrace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        "showlegend": true,
        "type": "bar",
        "marker": {
            "color": "$(Color.to_str data.color)"
        },
        "opacity": 1,
        $(orientation_str)
        "name": \"$(data.name)\",
        "width": $(Num.toStr data.bar_width)
    }
    """
