module [
    BarTrace,
    new,
    with_color,
    with_name,
    to_str,
]

import Color exposing [Color]

BarTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    color : Color,
    name : Str,
}

new : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @BarTrace {
        xy,
        orientation: Vertical,
        color: RGB 124 56 245,
        name : "",
    }

with_color : BarTrace x y, Color -> BarTrace x y
with_color = \@BarTrace trace, color ->
    @BarTrace { trace & color }

with_name : BarTrace x y, Str -> BarTrace x y
with_name = \@BarTrace trace, name ->
    @BarTrace { trace & name }

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
        "name": \"$(data.name)\"
    }
    """
