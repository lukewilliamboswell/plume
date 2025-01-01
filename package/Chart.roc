module [
    Chart,
    empty,
    with_title,
    add_bar_trace,
    add_scatter_trace,
    to_html,
]

import "static/template.html" as template : Str
import BarTrace exposing [BarTrace]
import ScatterTrace exposing [ScatterTrace]

Chart x y := {
    title : Str,
    traces : List (Trace x y),
}

Trace x y: [
    Bar (BarTrace x y),
    Scatter (ScatterTrace x y),
]

empty : Chart x y
empty = @Chart {
    traces: [],
    title: "",
}

with_title : Chart x y, Str -> Chart x y
with_title = \@Chart chart, title -> @Chart { chart & title }

to_json : Chart x y -> Str where x implements Inspect, y implements Inspect
to_json = \@Chart chart ->

    traces_str =
        chart.traces
        |> List.map \trace ->
            when trace is
                Bar inner -> BarTrace.to_str inner
                Scatter inner -> ScatterTrace.to_str inner
        |> Str.joinWith ",\n"

    "{ \"data\": [$(traces_str)] }"

to_html : Chart x y -> Str where x implements Inspect, y implements Inspect
to_html = \@Chart chart ->

    template
    |> Str.replaceFirst "{{CHART_JSON}}" (to_json (@Chart chart))
    |> Str.replaceFirst "{{CHART_TITLE}}" chart.title

add_bar_trace : Chart x y, BarTrace x y -> Chart x y
add_bar_trace = \@Chart chart, trace ->
    @Chart { chart & traces: List.append chart.traces (Bar trace) }

add_scatter_trace : Chart x y, ScatterTrace x y -> Chart x y
add_scatter_trace = \@Chart chart, trace ->
    @Chart { chart & traces: List.append chart.traces (Scatter trace) }
