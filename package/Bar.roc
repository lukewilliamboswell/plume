module [
    Trace,
    new,
    with_name,
    with_bar_width,
    with_marker,
    to_str,
]

import Marker

Trace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    name : Str,
    bar_width : F32,
    marker_attrs : List Marker.Attr,
}
    implements [Inspect]

new : List (x, y) -> Trace x y where x implements Inspect, y implements Inspect
new = \xy -> @Trace {
        xy,
        orientation: Vertical,
        name: "",
        bar_width: 0.5,
        marker_attrs: [],
    }

with_name : Trace x y, Str -> Trace x y
with_name = \@Trace trace, name ->
    @Trace { trace & name }

with_bar_width : Trace x y, F32 -> Result (Trace x y) [OutOfRange Str]
with_bar_width = \@Trace trace, bar_width ->
    if bar_width > 1.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else if bar_width < 0.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else
        Ok (@Trace { trace & bar_width })

with_marker : Trace x y, List Marker.Attr -> Trace x y
with_marker = \@Trace trace, marker_attrs ->
    @Trace { trace & marker_attrs }

to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@Trace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    marker_str = Marker.from_attrs data.marker_attrs

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        "type": "bar",
        $(marker_str),
        $(orientation_str)
        "name": \"$(data.name)\",
        "width": $(Num.toStr data.bar_width)
    }
    """