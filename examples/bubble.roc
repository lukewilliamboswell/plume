app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/bi5zubJ-_Hva9vxxPq4kNx4WHX6oFs8OP6Ad0tCYlrY.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Scatter
import plume.Layout
import plume.Title
import plume.Marker
import plume.Color

main! = |_|

    scatter_shapes : Scatter.Trace F64 F64
    scatter_shapes =
        Scatter.new(
            {
                data: [
                    { x: 1, y: 15, marker: Marker.new({ size: 20, symbol: "circle" })? },
                    { x: 2, y: 30, marker: Marker.new({ size: 20, symbol: "square" })? },
                    { x: 3, y: 45, marker: Marker.new({ size: 20, symbol: "diamond" })? },
                    { x: 4, y: 60, marker: Marker.new({ size: 20, symbol: "cross" })? },
                ],
                mode: "markers",
            },
        )?

    scatter_colors : Scatter.Trace F64 F64
    scatter_colors =
        Scatter.new(
            {
                data: [
                    { x: 1, y: 10, marker: Marker.new({ size: 20, color: Color.named("Red")? })? },
                    { x: 2, y: 20, marker: Marker.new({ size: 30, color: Color.named("Green")? })? },
                    { x: 3, y: 30, marker: Marker.new({ size: 40, color: Color.named("Blue")? })? },
                    { x: 4, y: 40, marker: Marker.new({ size: 50, color: Color.named("Orange")? })? },
                ],
                mode: "markers",
            },
        )?

    chart : Chart F64 F64
    chart =
        Chart.empty({})
        |> Chart.add_scatter_chart(scatter_shapes)
        |> Chart.add_scatter_chart(scatter_colors)
        |> Chart.with_layout(
            Layout.new(
                {
                    title: Title.new({ text: "Plotting Bubbles" }),
                },
            ),
        )

    File.write_utf8!(Chart.to_html(chart), "out.html")?

    Cmd.exec!("open", ["out.html"])?

    Ok({})
