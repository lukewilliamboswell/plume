module [
    Chart,
    empty,
    with_layout,
    add_bar_chart,
    add_scatter_chart,
    add_sankey_chart,
    add_pie_chart,
    to_html,
]

import "static/template.html" as template : Str
import Bar
import Scatter
import Sankey
import Layout
import Pie

Chart x y := {
    traces : List (Trace x y),
    layout : [None, Some (Layout.Layout x y)],
}
    implements [Inspect]

Trace x y : [
    Bar (Bar.Trace x y),
    Scatter (Scatter.Trace x y),
    Sankey (Sankey.Trace x y),
    Pie (Pie.Trace x y),
]

empty : Chart x y
empty = @Chart {
    traces: [],
    layout: None,
}

to_json : Chart x y -> Str where x implements Inspect, y implements Inspect
to_json = \@Chart chart ->

    traces_str =
        chart.traces
        |> List.map \trace ->
            when trace is
                Bar inner -> Bar.to_str inner
                Scatter inner -> Scatter.to_str inner
                Sankey inner -> Sankey.to_str inner
                Pie inner -> Pie.to_str inner
        |> Str.joinWith ",\n"

    layout_str =
        when chart.layout is
            None -> ""
            Some inner -> Layout.to_str inner

    "{\"data\":[$(traces_str)],\"layout\":$(layout_str)}"

to_html : Chart x y -> Str where x implements Inspect, y implements Inspect
to_html = \@Chart inner ->

    title =
        default_title = "My Chart"
        when inner.layout is
            None -> default_title
            Some layout -> Layout.get_title layout |> Result.withDefault default_title

    template
    |> Str.replaceFirst "{{CHART_JSON}}" (to_json (@Chart inner))
    |> Str.replaceFirst "{{CHART_TITLE}}" title

add_bar_chart : Chart x y, Bar.Trace x y -> Chart x y
add_bar_chart = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Bar trace) }

add_scatter_chart : Chart x y, Scatter.Trace x y -> Chart x y
add_scatter_chart = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Scatter trace) }

add_sankey_chart : Chart x y, Sankey.Trace x y -> Chart x y
add_sankey_chart = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Sankey trace) }

add_pie_chart : Chart x y, Pie.Trace x y -> Chart x y
add_pie_chart = \@Chart inner, trace ->
    @Chart { inner & traces: List.append inner.traces (Pie trace) }

with_layout : Chart x y, Layout.Layout x y -> Chart x y
with_layout = \@Chart inner, layout ->
    @Chart { inner & layout: Some layout }
