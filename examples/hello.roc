app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Bar
import plume.Scatter
import plume.Marker
import plume.Line
import plume.Layout
import plume.Font
import plume.Axis
import plume.Title
import plume.Color exposing [Color]

main! = \_ ->

    fuscia : Color
    fuscia = Color.hex? "#ff00ff"

    purple : Color
    purple = Color.rgba 124 56 245 150

    firebrick : Color
    firebrick = Color.named? "FireBrick"

    title_font : Title.Attr
    title_font = Title.font [
        Font.family "Courier New, monospace",
        Font.size? 24,
        Font.textcase Upper,
        Font.style Normal,
        Font.color fuscia,
    ]

    axis_font = Title.font [
        Font.family "Ringbearer",
        Font.size? 18,
        Font.color fuscia,
    ]

    default_font = [
        Font.family "'Comic Sans MS', 'Chalkboard SE', 'Comic Neue', sans-serif;",
        Font.style Italic,
    ]

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.add_scatter_chart
            (
                Scatter.new? {
                    data: [
                        { x: "Apples", y: 2.1 },
                        { x: "Oranges", y: 3 },
                        { x: "Bananas", y: 4 },
                    ],
                    mode: "lines+markers",
                    marker: [
                        Marker.size 15.0,
                        Marker.symbol? "diamond",
                    ],
                    line: [
                        Line.width 2.0,
                        Line.color firebrick,
                        Line.dash? "dash",
                    ],
                }

            )
        |> Chart.add_bar_chart
            (
                Bar.new? {
                    data: [("Tuna", 0.3), ("Muesli Bar", 2.5), ("Carrot", 5.5)],
                    bar_width: 0.9,
                    marker: [
                        Marker.color purple,
                    ],
                }
            )
        |> Chart.with_layout
            (
                Layout.new {
                    show_legend: Bool.true,
                    global_font: default_font,
                    title: [
                        Title.text "snack verse FRUIT",
                        title_font,
                    ],
                    x_axis: Axis.new {
                        title: [
                            Title.text "Fruit",
                            axis_font,
                        ],
                    },
                    y_axis: Axis.new {
                        title: [
                            Title.text "Snacks",
                            axis_font,
                        ],
                    },
                }
            )

    # we can inspect a Chart using `dbg` to
    # help with debugging
    dbg chart

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
