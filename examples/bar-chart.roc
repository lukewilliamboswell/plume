app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/bi5zubJ-_Hva9vxxPq4kNx4WHX6oFs8OP6Ad0tCYlrY.tar.br",
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

main! = |_|

    blue = Color.rgb(0, 0, 255)

    marker = Marker.new({ color: blue })?

    bar : Bar.Trace Str F64
    bar =
        Bar.new(
            {
                data: [
                    { x: "Italy", y: 55, marker },
                    { x: "France", y: 49, marker },
                    { x: "Spain", y: 44, marker },
                    { x: "USA", y: 24, marker },
                    { x: "Australia", y: 15, marker },
                ],
            },
        )?

    chart : Chart Str F64
    chart =
        Chart.empty({})
        |> Chart.add_bar_chart(bar)
        |> Chart.with_layout(Layout.new({ title: Title.new({ text: "Roc Programmers by Country" }) }))

    File.write_utf8!(Chart.to_html(chart), "out.html")?

    Cmd.exec!("open", ["out.html"])?

    Ok({})
