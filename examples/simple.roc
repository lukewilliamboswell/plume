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
import plume.Axis
import plume.Color exposing [rgba]

main! = \_ ->

    title_font = Font.new? {
        family: "Ringbearer",
        size: 24,
        style: Italic,
    }

    axis_font = Font.new? {
        family: "Courier New, monospace",
        size: 18,
    }

    marker = Marker.new? {
        size: 15.0,
        symbol: "diamond",
        color: rgba 124 56 245 255,
    }

    scatter : Scatter.Trace Str F64
    scatter =
        Scatter.new? {
            data: [
                { x: "Apples", y: 2.1, marker },
                { x: "Oranges", y: 3, marker },
                { x: "Bananas", y: 4, marker },
            ],
            mode: "lines+markers",
            line: Line.new {
                width: 2.0,
                color: rgba 124 56 245 150,
                dash: Dash,
            },
        }

    chart =
        Chart.empty
        |> Chart.add_scatter_chart scatter
        |> Chart.with_layout
            (
                Layout.new {
                    title: Title.new { text: "Fruit Sales", font: title_font },
                    y_axis: Axis.new { title: Title.new { text: "Qty", font: axis_font } },
                }
            )

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
