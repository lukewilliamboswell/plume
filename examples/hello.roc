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
                BarTrace.new [("Apples", 2), ("Oranges", 3), ("Bananas", 4)]
                |> BarTrace.with_name "Fruit"
            )
        |> Chart.add_trace
            (
                BarTrace.new [("Tuna", 3), ("Musli Bar", 1), ("Carrot", 5)]
                |> BarTrace.with_color fuscia
                |> BarTrace.with_name "Snacks"
            )

    File.write_utf8! (Chart.to_html chart) "out.html"
