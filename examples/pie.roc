app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Pie
import plume.Layout
import plume.Title

main! = \_ ->

    pie : Pie.Trace Str F64
    pie = Pie.new? {
        data: [
            { label: "Italy", value: 55 },
            { label: "France", value: 49 },
            { label: "Spain", value: 44 },
            { label: "USA", value: 24 },
            { label: "Australia", value: 15 },
        ],
    }

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.add_pie_chart pie
        |> Chart.with_layout [
            Layout.title [
                Title.text "Roc Programmers by Country",
            ],
        ]

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
