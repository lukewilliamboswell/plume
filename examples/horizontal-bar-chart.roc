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

## Original example inspired by the [w3 schools Plotly.js tutorial](https://www.w3schools.com/js/js_graphics_plotly.asp)
## Thank you https://www.w3schools.com
main! = \_ ->

    light_red = Color.rgba 255 0 0 153

    data : List (F64, Str)
    data = [
        (55, "Italy"),
        (49, "France"),
        (44, "Spain"),
        (24, "USA"),
        (15, "Australia"),
    ]

    bar : Bar.Trace F64 Str
    bar =
        Bar.new? {
            data,
            orientation: Horizontal,
            marker: [
                Marker.color light_red,
            ],
        }

    chart : Chart F64 Str
    chart =
        Chart.empty
        |> Chart.add_bar_chart bar
        |> Chart.with_layout [
            Layout.title [
                Title.text "World Wide Wine Production",
            ],
        ]

    File.write_utf8!? (Chart.to_html chart) "out.html"

    Cmd.exec! "open" ["out.html"]
