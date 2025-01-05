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
import plume.Color

main! = \_ ->

    fuscia = Color.hex? "#ff00ff"
    purple = Color.rgba 124 56 245 150
    firebrick = Color.named? "FireBrick"

    title_font = Font.new? {
        family: "Courier New, monospace",
        size: 24,
        textcase: Upper,
        style: Normal,
        color: fuscia,
    }

    axis_font = Font.new? {
        family: "Ringbearer",
        size: 18,
        color: fuscia,
    }

    global_font = Font.new? {
        family: "'Comic Sans MS', 'Chalkboard SE', 'Comic Neue', sans-serif;",
        style: Italic,
    }

    marker = Marker.new? {
        size: 15.0,
        symbol: "diamond",
    }

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.add_scatter_chart
            (
                Scatter.new? {
                    data: [
                        { x: "Apples", y: 2.1, marker },
                        { x: "Oranges", y: 3, marker },
                        { x: "Bananas", y: 4, marker },
                    ],
                    mode: "lines+markers",
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
                }
            )
        |> Chart.with_layout
            (
                Layout.new {
                    show_legend: Bool.true,
                    global_font,
                    title: Title.new {
                        text: "snack verse FRUIT",
                        font: title_font,
                    },
                    x_axis: Axis.new {
                        title: Title.new {
                            text: "Fruit",
                            font: axis_font,
                        },
                    },
                    y_axis: Axis.new {
                        title: Title.new {
                            text: "Snacks",
                            font: axis_font,
                        },
                    },
                }
            )

    # we can inspect a Chart using `dbg` to
    # help with debugging
    dbg chart

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
