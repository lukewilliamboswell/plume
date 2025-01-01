module [
    ScatterTrace,
    new,
    with_color,
    with_name,
    to_str,
]

import Color exposing [Color]

ScatterTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    color : Color,
    name : Str,
}

new : List (x, y) -> ScatterTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @ScatterTrace {
        xy,
        orientation: Vertical,
        color: Color.rgb 124 56 245,
        name: "",
    }

with_color : ScatterTrace x y, Color -> ScatterTrace x y
with_color = \@ScatterTrace trace, color ->
    @ScatterTrace { trace & color }

with_name : ScatterTrace x y, Str -> ScatterTrace x y
with_name = \@ScatterTrace trace, name ->
    @ScatterTrace { trace & name }

to_str : ScatterTrace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@ScatterTrace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        "showlegend": true,
        "type": "scatter",
        "marker": {
            "color": "$(Color.to_str data.color)"
        },
        "opacity": 1,
        $(orientation_str)
        "name": \"$(data.name)\"
    }
    """
