app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Bar
import plume.Marker
import plume.Layout
import plume.Title
import plume.Color

main! = \_ ->

    blue = Color.rgb 0 0 255

    data : List (Str, F64)
    data = [
        ("Italy", 55),
        ("France", 49),
        ("Spain", 44),
        ("USA", 24),
        ("Australia", 15),
    ]

    bar : Bar.Trace Str F64
    bar =
        Bar.new? {
            data,
            #marker: Marker.new? { color: blue },
        }

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.add_bar_chart bar
        |> Chart.with_layout (Layout.new { title: Title.new { text: "Roc Programmers by Country" } })

    File.write_utf8!? (Chart.to_html chart) "out.html"

    # Cmd.exec! "open" ["out.html"]

    dbg chart

    Ok {}
