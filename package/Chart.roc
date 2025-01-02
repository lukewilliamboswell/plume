module [
    Chart,
    empty,
    with_title,
    with_layout,
    add_bar_trace,
    add_scatter_trace,
    add_sankey,
    to_html,
]

import "static/template.html" as template : Str
import BarTrace exposing [BarTrace]
import ScatterTrace exposing [ScatterTrace]
import Sankey
import Layout

Chart x y := {
    title : Str,
    traces : List (Trace x y),
    layout_attrs : List Layout.Attr,
}
    implements [Inspect]

Trace x y : [
    Bar (BarTrace x y),
    Scatter (ScatterTrace x y),
    Sankey (Sankey.Trace x y),
]

empty : Chart x y
empty = @Chart {
    traces: [],
    title: "",
    layout_attrs: [],
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
                Sankey inner -> Sankey.to_str inner
        |> Str.joinWith ",\n"

    layout_str = Layout.from_attrs chart.layout_attrs

    "{\"data\":[$(traces_str)],$(layout_str)}"

to_html : Chart x y -> Str where x implements Inspect, y implements Inspect
to_html = \@Chart inner ->
    template
    |> Str.replaceFirst "{{CHART_JSON}}" (to_json (@Chart inner))
    |> Str.replaceFirst "{{CHART_TITLE}}" inner.title

add_bar_trace : Chart x y, BarTrace x y -> Chart x y
add_bar_trace = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Bar trace) }

add_scatter_trace : Chart x y, ScatterTrace x y -> Chart x y
add_scatter_trace = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Scatter trace) }

add_sankey : Chart x y, Sankey.Trace x y -> Chart x y
add_sankey = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Sankey trace) }

with_layout : Chart x y, List Layout.Attr -> Chart x y
with_layout = \@Chart inner, layout_attrs ->
    @Chart { inner & layout_attrs }
