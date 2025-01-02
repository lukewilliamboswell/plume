module [
    Trace,
    new,
    with_name,
    with_marker,
    with_line,
    with_mode,
    to_str,
]

import Marker
import Line

Trace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    name : Str,
    marker_attrs : List Marker.Attr,
    line_attrs : List Line.Attr,
    mode : Str,
}
    implements [Inspect]

new : List (x, y) -> Trace x y where x implements Inspect, y implements Inspect
new = \xy -> @Trace {
        xy,
        orientation: Vertical,
        name: "",
        marker_attrs: [],
        line_attrs: [],
        mode: "lines",
    }

with_marker : Trace x y, List Marker.Attr -> Trace x y
with_marker = \@Trace trace, marker_attrs ->
    @Trace { trace & marker_attrs }

with_line : Trace x y, List Line.Attr -> Trace x y
with_line = \@Trace trace, line_attrs ->
    @Trace { trace & line_attrs }

with_name : Trace x y, Str -> Trace x y
with_name = \@Trace trace, name ->
    @Trace { trace & name }

with_mode : Trace x y, Str -> Result (Trace x y) [InvalidMode Str]
with_mode = \@Trace inner, mode ->

    valid_modes = Set.fromList ["lines", "markers", "text"]

    if mode == "none" then
        Ok (@Trace { inner & mode })
    else if Str.splitOn mode "+" |> List.all \m -> Set.contains valid_modes m then
        Ok (@Trace { inner & mode })
    else
        Err (InvalidMode "Invalid mode: $(mode), expected one of: $(Inspect.toStr valid_modes)")

to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@Trace data ->

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
        "type": "scatter",
        $(marker_str),
        $(line_str),
        $(orientation_str)
        "name": \"$(data.name)\"
    }
    """
