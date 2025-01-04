app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
}

main! = \_ -> Ok {}

expect

    _ =
        when new_scatter { data : []} is
            Ok asdf -> scatter_to_str asdf
            Err _ -> crash ""

    1 == 2


Trace x y := {
    data : List { x : x, y : y },
    orientation : [Vertical, Horizontal],
    name : Str,
    marker : Marker,
}
    implements [Inspect]

new_scatter :
    {
        data : List { x : x, y : y },
        orientation ? [Vertical, Horizontal],
        name ? Str,
    }
    -> Result (Trace x y) _
new_scatter = \{ data, orientation ? Vertical, name ? ""} ->
    Ok
        (
            @Trace {
                data,
                orientation,
                name,
                marker: new_marker? {},
            }
        )

# CHANING ANYHTING IN HERE SEEMS TO "FIX" IT
scatter_to_str : Trace x y -> Str where x implements Inspect, y implements Inspect
scatter_to_str = \@Trace inner ->

    # NOT USED ... BUT WE CAN"T REMOVE, OR BUG GOES AWAY??
    data2 = List.walk inner.data ([], []) \(xs, ys), { x, y } -> (List.append xs x, List.append ys y)

    # NOT USED ... BUT WE CAN"T REMOVE, OR BUG GOES AWAY??
    orientation_str = if inner.orientation == Vertical then "\"orientation\":\"v\"" else "\"orientation\":\"h\""

    # NOT USED ... BUT WE CAN"T REMOVE, OR BUG GOES AWAY??
    name_str = if Str.isEmpty inner.name then "" else "\"name\":\"$(inner.name)\""

    # NOT USED ... BUT WE CAN"T REMOVE, OR BUG GOES AWAY??
    marker_str = marker_to_str inner.marker

    ""


Marker := {}
    implements [Inspect]

new_marker : {} -> Result Marker _
new_marker = \{} -> Ok (@Marker {})

marker_to_str : Marker -> Str
marker_to_str = \_ -> ""
