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
import plume.Marker

main! = \_ ->

    marker = Marker.new? {}

    data : List { x : F64, y : F64, marker : _ }
    data =
        List.range { start: At 0, end: Before 10, step: 0.1 }
        |> List.map \x -> { x, y: Num.sin x, marker }

    scatter : Scatter.Trace F64 F64
    scatter =
        Scatter.new? {
            data,
        }

    chart : Chart F64 F64
    chart =
        Chart.empty
        |> Chart.add_scatter_chart scatter
        |> Chart.with_layout (Layout.new { title: Title.new { text: "y = Math.sin(x)" } })

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
