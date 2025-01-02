module [
    BarTrace,
    new,
    with_name,
    with_bar_width,
    with_marker,
    to_str,
]

import Marker

BarTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    name : Str,
    bar_width : F32,
    marker_attrs : List Marker.Attr,
}
    implements [Inspect]

new : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @BarTrace {
        xy,
        orientation: Vertical,
        name: "",
        bar_width: 0.5,
        marker_attrs: [],
    }

with_name : BarTrace x y, Str -> BarTrace x y
with_name = \@BarTrace trace, name ->
    @BarTrace { trace & name }

with_bar_width : BarTrace x y, F32 -> Result (BarTrace x y) [OutOfRange Str]
with_bar_width = \@BarTrace trace, bar_width ->
    if bar_width > 1.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else if bar_width < 0.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else
        Ok (@BarTrace { trace & bar_width })

with_marker : BarTrace x y, List Marker.Attr -> BarTrace x y
with_marker = \@BarTrace trace, marker_attrs ->
    @BarTrace { trace & marker_attrs }

to_str : BarTrace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@BarTrace data ->

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
