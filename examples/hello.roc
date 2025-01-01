app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart exposing [Chart]
import plume.BarTrace
import plume.ScatterTrace
import plume.Color exposing [Color]

main! = \_ ->

    fuscia : Color
    fuscia = Color.hex? "#ff00ff"

    chart : Chart Str F64
    chart =
        Chart.empty
        |> Chart.with_title "Snacks vs Fruit"
        |> Chart.add_scatter_trace
            (
                ScatterTrace.new [("Apples", 2.1), ("Oranges", 3), ("Bananas", 4)]
                |> ScatterTrace.with_name "Fruit"
                |> ScatterTrace.with_color (Color.named? "FireBrick")
            )
        |> Chart.add_bar_trace
            (
                BarTrace.new [("Tuna", 0.3), ("Muesli Bar", 2.5), ("Carrot", 5.5)]
                |> BarTrace.with_color fuscia
                |> BarTrace.with_name "Snacks"
                |> BarTrace.with_bar_width? 0.9
            )

    File.write_utf8! (Chart.to_html chart) "out.html"
