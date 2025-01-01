module [
    Chart,
    empty,
    with_title,
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

with_title : Chart, Str -> Chart
with_title = \@Chart chart, title -> @Chart { chart & title }

to_json : Chart -> Str
to_json = \@Chart chart ->

    traces_str =
        chart.traces
        |> List.map BarTrace.to_str
        |> Str.joinWith ",\n"

    "{ \"data\": [$(traces_str)] }"

to_html : Chart -> Str
to_html = \@Chart chart ->

    template
    |> Str.replaceFirst "{{CHART_JSON}}" (to_json (@Chart chart))
    |> Str.replaceFirst "{{CHART_TITLE}}" chart.title

add_trace : Chart, BarTrace Str U64 -> Chart
add_trace = \@Chart chart, trace ->
    @Chart { chart & traces: List.append chart.traces trace }
