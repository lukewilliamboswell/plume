app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart exposing [Chart]
import plume.Font
import plume.Layout
import plume.Title
import plume.Color exposing [Color]
import plume.Sankey

main! = \_ ->

    fuscia : Color
    fuscia = Color.hex? "#ff00ff"

    purple : Color
    purple = Color.rgba 124 56 245 150

    default_font = [
        Font.family "'Comic Sans MS', 'Chalkboard SE', 'Comic Neue', sans-serif;",
        Font.style Italic,
    ]

    sankey_chart : Sankey.Trace Str F64
    sankey_chart =
        Sankey.new {
            nodes: [
                { label: "A", color: fuscia },
                { label: "B", color: fuscia },
                { label: "C", color: purple },
                { label: "D", color: purple },
                { label: "E", color: fuscia },
            ],
            links: [
                { source: "A", target: "C", value: 8 },
                { source: "B", target: "D", value: 4 },
                { source: "A", target: "D", value: 2 },
                { source: "C", target: "E", value: 8 },
                { source: "D", target: "E", value: 4 },
                { source: "D", target: "E", value: 2 },
            ],
        }

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.add_sankey_chart sankey_chart
        |> Chart.with_layout [
            Layout.title [
                Title.text "Example Sankey Chart",
            ],
            Layout.global_font default_font,
        ]

    dbg chart

    File.write_utf8! (Chart.to_html chart) "out.html"
