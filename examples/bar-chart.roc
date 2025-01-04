app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import plume.Chart exposing [Chart]

main! = \_ ->

    chart : Chart Str F64
    chart = Chart.empty

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Ok {}
