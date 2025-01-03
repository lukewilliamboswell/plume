module [
    Trace,
    new,
    to_str,
]

Trace label value := {
    data : List { label : label, value : value },
    hole : F32,
    name : Str,
}
    implements [Inspect]

new :
    {
        data : List { label : label, value : value },
        hole ? F32,
        name ? Str,
    }
    -> Result (Trace label value) _
new = \{ data, name ? "", hole ? 0.0 } ->
    Ok
        (
            @Trace {
                data,
                name,
                hole: check_valid_hole_size? hole,
            }
        )

check_valid_hole_size = \hole_size ->
    if hole_size > 1.0 then
        Err (OutOfRange "Hole size must be between 0.0 to 1.0, got $(Num.toStr hole_size)")
    else if hole_size < 0.0 then
        Err (OutOfRange "Hole size must be between 0.0 to 1.0, got $(Num.toStr hole_size)")
    else
        Ok hole_size

to_str : Trace label value -> Str where label implements Inspect, value implements Inspect
to_str = \@Trace inner ->

    help = \data, (labels, values) ->
        when data is
            [] -> (Str.joinWith labels ", ", Str.joinWith values ", ")
            [{ label, value }, .. as rest] ->
                label_str = Inspect.toStr label
                value_str = Inspect.toStr value
                help rest (List.append labels label_str, List.append values value_str)

    (labels_str, values_str) = help inner.data ([], [])

    hole_str = if inner.hole >= 0.0 then "\"hole\": $(Num.toStr inner.hole)," else ""

    """
    {
        "labels": [$(labels_str)],
        "values": [$(values_str)],
        "type": "pie",
        $(hole_str)
        "name": \"$(inner.name)\"
    }
    """
