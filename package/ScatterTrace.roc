module [
    ScatterTrace,
    new,
    with_name,
    with_marker,
    with_line,
    to_str,
]

import Marker
import Line

ScatterTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    name : Str,
    marker_attrs : List Marker.Attr,
    line_attrs : List Line.Attr,
}
    implements [Inspect]

new : List (x, y) -> ScatterTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @ScatterTrace {
        xy,
        orientation: Vertical,
        name: "",
        marker_attrs: [],
        line_attrs: [],
    }

with_marker : ScatterTrace x y, List Marker.Attr -> ScatterTrace x y
with_marker = \@ScatterTrace trace, marker_attrs ->
    @ScatterTrace { trace & marker_attrs }

with_line : ScatterTrace x y, List Line.Attr -> ScatterTrace x y
with_line = \@ScatterTrace trace, line_attrs ->
    @ScatterTrace { trace & line_attrs }

with_name : ScatterTrace x y, Str -> ScatterTrace x y
with_name = \@ScatterTrace trace, name ->
    @ScatterTrace { trace & name }

to_str : ScatterTrace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@ScatterTrace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    marker_str = Marker.from_attrs data.marker_attrs
    line_str = Line.from_attrs data.line_attrs

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        "showlegend": true,
        "type": "scatter",
        $(marker_str),
        $(line_str),
        "opacity": 1,
        $(orientation_str)
        "name": \"$(data.name)\"
    }
    """
