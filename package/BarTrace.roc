module [
    BarTrace,
    new_trace,
    with_color,
    to_str,
]

import Color exposing [Color]

BarTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    color : Color,
}

new_trace : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new_trace = \xy -> @BarTrace {
        xy,
        orientation: Vertical,
        color: RGB 124 56 245,
    }

with_color : BarTrace x y, Color -> BarTrace x y
with_color = \@BarTrace trace, color ->
    @BarTrace { trace & color }

to_str : BarTrace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@BarTrace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

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
        $(if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\",")
        "name": "Fruits"
    }
    """
