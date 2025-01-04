module [
    Trace,
    new,
    to_str,
]

import Marker

Trace x y := {
    data : List { x : x, y : y },
    orientation : [Vertical, Horizontal],
    name : Str,
    marker : Marker.Marker,
}
    implements [Inspect]

new :
    {
        data : List { x : x, y : y },
        orientation ? [Vertical, Horizontal],
        name ? Str,
    }
    -> Result (Trace x y) _
new = \{ data, orientation ? Vertical, name ? ""} ->
    Ok
        (
            @Trace {
                data,
                orientation,
                name,
                marker: Marker.new? {},
            }
        )

# CHANING ANYHTING IN HERE SEEMS TO "FIX" IT
to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
to_str = \@Trace inner ->

    # NOT USED ... BUT WE CAN"T REMOVE??
    data2 = List.walk inner.data ([], []) \(xs, ys), { x, y } -> (List.append xs x, List.append ys y)

    x_str = ""
    y_str = ""

    orientation_str = if inner.orientation == Vertical then "\"orientation\":\"v\"" else "\"orientation\":\"h\""

    name_str = if Str.isEmpty inner.name then "" else "\"name\":\"$(inner.name)\""

    marker_str = Marker.to_str inner.marker

    [
        "\"x\":[$(x_str)]",
        "\"y\":[$(y_str)]",
        marker_str,
        "$(orientation_str)",
        "$(name_str)",
        "\"type\":\"scatter\"",
    ]
    |> Str.joinWith ","
