module [
    Chart,
    empty,
    with_layout,
    to_html,
]

import Scatter
import Layout

Chart x y := {
    traces : List (Trace x y),
    layout : [None, Some Layout.Layout],
}
    implements [Inspect]

Trace x y : [
    Scatter (Scatter.Trace x y),
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
                Scatter inner -> Scatter.to_str inner
        |> Str.joinWith ",\n"

    layout_str =
        when chart.layout is
            None -> ""
            Some inner -> Layout.to_str inner

    ""

to_html : Chart x y -> Str where x implements Inspect, y implements Inspect
to_html = \@Chart inner ->

    title = ""
        #default_title = "My Chart"
        #when inner.layout is
        #    None -> default_title
        #    Some layout -> ""

    "template"
    |> Str.replaceFirst "{{CHART_JSON}}" (to_json (@Chart inner))
    |> Str.replaceFirst "{{CHART_TITLE}}" title

with_layout : Chart x y, Layout.Layout -> Chart x y
with_layout = \@Chart inner, layout ->
    @Chart { inner & layout: Some layout }
