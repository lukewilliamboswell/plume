app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart
import plume.BarTrace

main! = \_ ->

    fuscia = Hex "#ff00ff"

    chart =
        Chart.empty
        |> Chart.add_trace
            (
                BarTrace.new_trace [("Apples", 2), ("Oranges", 3), ("Bananas", 4)]
            )
        |> Chart.add_trace
            (
                BarTrace.new_trace [("Apples", 3), ("Oranges", 1), ("Bananas", 5)]
                |> BarTrace.with_color fuscia
            )

    File.write_utf8! (Chart.to_html chart) "out.html"
