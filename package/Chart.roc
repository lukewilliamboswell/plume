module [
    Chart,
    empty,
    add_trace,
    to_html,
]

import "static/template.html" as template : Str
import BarTrace exposing [BarTrace]

Chart := {
    title : Str,
    traces : List (BarTrace Str U64),
}

empty : Chart
empty = @Chart {
    traces: [],
    title: "",
}

to_html : Chart -> Str
to_html = \@Chart chart ->

    traces_str =
        chart.traces
        |> List.map BarTrace.to_str
        |> Str.joinWith ",\n"

    Str.replaceFirst
        template
        "{{REPLACE_ME}}"
        "{ \"data\": [$(traces_str)] }"

add_trace : Chart, BarTrace Str U64 -> Chart
add_trace = \@Chart chart, trace ->
    @Chart { chart & traces: List.append chart.traces trace }
