app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart
import plume.Scatter
import plume.Marker
import plume.Line
import plume.Layout
import plume.Font
import plume.Title
import plume.Color exposing [rgba]

main! = \_ ->

    title_font = Title.font [
        Font.family "Ringbearer",
        Font.size? 24,
        Font.style Italic,
    ]

    axis_font = Title.font [
        Font.family "Courier New, monospace",
        Font.size? 18,
    ]

    data : List (Str, F64)
    data = [
        ("Apples", 2.1),
        ("Oranges", 3),
        ("Bananas", 4),
    ]

    scatter =
        Scatter.new data
        |> Scatter.with_name "Fruit"
        |> Scatter.with_mode? "lines+markers"
        |> Scatter.with_marker [
            Marker.size 15.0,
            Marker.symbol? "diamond",
            Marker.color (rgba 124 56 245 255),
        ]
        |> Scatter.with_line [
            Line.width 2.0,
            Line.color (rgba 124 56 245 150),
            Line.dash? "dash",
        ]

    chart =
        Chart.empty
        |> Chart.add_scatter_chart scatter
        |> Chart.with_layout [
            Layout.title [
                Title.text "Fruit Sales",
                title_font,
            ],
            Layout.y_axis [
                Title.text "Qty",
                axis_font,
            ],
        ]

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
