app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Scatter
import plume.Layout
import plume.Title
import plume.Axis
import plume.Marker
import plume.Color

main! = \_ ->

    up = Marker.new? {
        size: 20,
        color: Color.named? "Green",
        symbol: "triangle-up",
    }

    down = Marker.new? {
        size: 20,
        color: Color.named? "Red",
        symbol: "triangle-down",
    }

    scatter : Scatter.Trace F64 F64
    scatter =
        Scatter.new? {
            data: [
                { x: 50, y: 7, marker: up },
                { x: 60, y: 8, marker: up },
                { x: 70, y: 8, marker: up },
                { x: 80, y: 9, marker: up },
                { x: 90, y: 9, marker: up },
                { x: 100, y: 9, marker: up },
                { x: 110, y: 10, marker: down },
                { x: 120, y: 11, marker: down },
                { x: 130, y: 14, marker: down },
                { x: 140, y: 14, marker: down },
                { x: 150, y: 15, marker: down },
            ],
            mode: "markers",
        }

    chart : Chart F64 F64
    chart =
        Chart.empty
        |> Chart.add_scatter_chart scatter
        |> Chart.with_layout
            (
                Layout.new {
                    title: Title.new { text: "House Price vs Size" },
                    x_axis: Axis.new {
                        title: Title.new { text: "Square Meters" },
                        range: Set { min: 40, max: 160 },
                    },
                    y_axis: Axis.new {
                        title: Title.new { text: "Price in Millions ($USD)" },
                        range: Set { min: 5, max: 16 },
                    },
                }
            )

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
