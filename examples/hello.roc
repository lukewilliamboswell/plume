app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart exposing [Chart]
import plume.BarTrace
import plume.ScatterTrace
import plume.Marker
import plume.Line
import plume.Layout
import plume.Font
import plume.Title
import plume.Color exposing [Color]

main! = \_ ->

    fuscia : Color
    fuscia = Color.hex? "#ff00ff"

    purple : Color
    purple = Color.rgba 124 56 245 150

    firebrick : Color
    firebrick = Color.named? "FireBrick"

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.with_title "Snacks vs Fruit"
        |> Chart.add_scatter_trace
            (
                ScatterTrace.new [("Apples", 2.1), ("Oranges", 3), ("Bananas", 4)]
                |> ScatterTrace.with_name "Fruit"
                |> ScatterTrace.with_mode? "lines+markers"
                |> ScatterTrace.with_marker [
                    Marker.size 10.0,
                    Marker.color fuscia,
                ]
                |> ScatterTrace.with_line [
                    Line.width 2.0,
                    Line.color firebrick,
                    Line.dash? "dash",
                ]
            )
        |> Chart.add_bar_trace
            (
                BarTrace.new [("Tuna", 0.3), ("Muesli Bar", 2.5), ("Carrot", 5.5)]
                |> BarTrace.with_color purple
                |> BarTrace.with_name "Snacks"
                |> BarTrace.with_bar_width? 0.9
            )
        |> Chart.with_layout [
            Layout.title [
                Title.text "Snacks verse Fruit",
                Title.font [
                    Font.family "Courier New, monospace",
                    Font.size 24,
                    Font.color fuscia,
                ],
            ],
        ]

    dbg chart

    File.write_utf8! (Chart.to_html chart) "out.html"
