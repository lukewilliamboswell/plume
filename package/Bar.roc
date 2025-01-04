module [
    Trace,
    new,
    to_str,
]

import Marker

Trace x y := {
    xy : List (x, y),
    marker : Marker.Marker,
}
    implements [Inspect]

new :
    {
        data : List (x, y),
    }
    -> Result (Trace x y) _
new = \{ data} ->
    Ok
        (
            @Trace {
                xy: data,
                marker: Marker.default,
            }
        )

to_str : Trace x y -> Str
to_str = \_ -> ""
