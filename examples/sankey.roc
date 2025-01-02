app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart exposing [Chart]
import plume.Font
import plume.Layout
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

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.with_title "Snacks vs Fruit"
        |> Chart.add_sankey
            (
                Sankey.new {
                    name: "TEST",
                    nodes: [
                        { label: "A", color: purple },
                        { label: "B", color: purple },
                        { label: "C", color: fuscia },
                        { label: "D", color: fuscia },
                        { label: "E", color: purple },
                    ],
                    links: [
                        { source: "A", target: "B", value: 20 },
                        { source: "A", target: "C", value: 10 },
                        { source: "B", target: "D", value: 15 },
                        { source: "C", target: "D", value: 10 },
                        { source: "B", target: "C", value: 5 },
                        { source: "D", target: "E", value: 5 },
                    ],
                }
            )
        |> Chart.with_layout [Layout.global_font default_font]

    dbg chart

    File.write_utf8! (Chart.to_html chart) "out.html"
