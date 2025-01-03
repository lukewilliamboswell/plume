module [
    Trace,
    new,
    with_name,
    with_bar_width,
    to_str,
]

import Marker

Trace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    name : Str,
    bar_width : F32,
    marker : Marker.Marker,
}
    implements [Inspect]

new :
    {
        data : List (x, y),
        orientation ? [Vertical, Horizontal],
        name ? Str,
        bar_width ? F32,
        #marker : Marker.Marker,
    }
    -> Result (Trace x y) _
new = \{ data, orientation ? Vertical, name ? "", bar_width ? 0.75 } ->
    Ok
        (
            @Trace {
                xy: data,
                orientation,
                name,
                bar_width: check_valid_bar_width? bar_width,
                marker: Marker.default,
            }
        )

with_name : Trace x y, Str -> Trace x y
with_name = \@Trace trace, name ->
    @Trace { trace & name }

with_bar_width : Trace x y, F32 -> Result (Trace x y) [OutOfRange Str]
with_bar_width = \@Trace trace, bar_width ->
    Ok (@Trace { trace & bar_width: check_valid_bar_width? bar_width })

check_valid_bar_width = \bar_width ->
    if bar_width > 1.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else if bar_width < 0.0 then
        Err (OutOfRange "Bar width must be between 0.1 to 1.0, got $(Num.toStr bar_width)")
    else
        Ok bar_width

to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@Trace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ","
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ","

    orientation_str = if data.orientation == Vertical then "\"orientation\":\"v\"" else "\"orientation\":\"h\""

    marker_str : Str
    marker_str = Marker.to_str data.marker

    [
        "\"x\":[$(x_str)]",
        "\"y\":[$(y_str)]",
        marker_str,
        "$(orientation_str)",
        "\"name\":\"$(data.name)\"",
        "\"width\":$(Num.toStr data.bar_width)",
        "\"type\":\"bar\"",
    ]
    |> List.dropIf Str.isEmpty
    |> Str.joinWith ","
    |> \str -> "{$(str)}"
