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

main! = \_ ->

    data : List { x : F64, y : F64 }
    data =
        [{ x: 50, y: 7 }, { x: 60, y: 8 }, { x: 70, y: 8 }, { x: 80, y: 9 }, { x: 90, y: 9 }, { x: 100, y: 9 }, { x: 110, y: 10 }, { x: 120, y: 11 }, { x: 130, y: 14 }, { x: 140, y: 14 }, { x: 150, y: 15 }]

    scatter : Scatter.Trace F64 F64
    scatter =
        Scatter.new? {
            data,
            mode: "markers",
        }

    chart : Chart F64 F64
    chart =
        Chart.empty
        |> Chart.add_scatter_chart scatter
        |> Chart.with_layout [
            Layout.title [
                Title.text "House Price vs Size",
            ],
            Layout.x_axis [
                Title.text "Square Meters",
            ],
            Layout.y_axis [
                Title.text "Price in Millions ($USD)",
            ],
        ]

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
