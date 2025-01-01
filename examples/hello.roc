app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.Stdout
import plume.Plotly

main! = \_ ->

    data : Plotly.BarTrace Str U64
    data =
        Plotly.new [
            ("Apples", 2),
            ("Organes", 3),
            ("Bananas", 4),
        ]
        |> Plotly.with_color (Hex "#ff00ff")

    html = Plotly.to_html data

    Stdout.line! html
