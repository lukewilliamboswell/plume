module [
    Trace,
    new,
    to_str,
]

import Marker
import Line

Trace x y := {
    data : List { x : x, y : y },
    orientation : [Vertical, Horizontal],
    name : Str,
    marker_attrs : List Marker.Attr,
    line_attrs : List Line.Attr,
    mode : Str,
}
    implements [Inspect]

new :
    {
        data : List { x : x, y : y },
        orientation ? [Vertical, Horizontal],
        name ? Str,
        marker ? List Marker.Attr,
        line ? List Line.Attr,
        mode ? Str,
    }
    -> Result (Trace x y) _
new = \{ data, orientation ? Vertical, name ? "", marker ? [], line ? [], mode ? "lines" } ->
    Ok
        (
            @Trace {
                data,
                orientation,
                name,
                marker_attrs: marker,
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

    data2 = List.walk inner.data ([], []) \(xs, ys), { x, y } -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    orientation_str = if inner.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    marker_str = Marker.from_attrs inner.marker_attrs

    line_str = Line.from_attrs inner.line_attrs

    name_str = if Str.isEmpty inner.name then "" else "\"name\": \"$(inner.name)\","

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        $(marker_str)
        $(line_str)
        $(orientation_str)
        $(name_str)
        "type": "scatter"
    }
    """
