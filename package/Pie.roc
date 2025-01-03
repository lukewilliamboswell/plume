module [
    Trace,
    new,
    to_str,
]

Trace label value := {
    data : List { label : label, value : value },
    name : Str,
}
    implements [Inspect]

new :
    {
        data : List { label : label, value : value },
        name ? Str,
    }
    -> Result (Trace label value) []
new = \{ data, name ? "" } ->
    Ok (@Trace { data, name })

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

    """
    {
        "labels": [$(labels_str)],
        "values": [$(values_str)],
        "type": "pie",
        "name": \"$(inner.name)\"
    }
    """
