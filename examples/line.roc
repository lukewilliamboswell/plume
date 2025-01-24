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
import plume.Axis
import plume.Marker

main! = |_|

    marker = Marker.new({})?

    scatter : Scatter.Trace F64 F64
    scatter =
        Scatter.new(
            {
                data: [
                    { x: 50, y: 7, marker },
                    { x: 60, y: 8, marker },
                    { x: 70, y: 8, marker },
                    { x: 80, y: 9, marker },
                    { x: 90, y: 9, marker },
                    { x: 100, y: 9, marker },
                    { x: 110, y: 10, marker },
                    { x: 120, y: 11, marker },
                    { x: 130, y: 14, marker },
                    { x: 140, y: 14, marker },
                    { x: 150, y: 15, marker },
                ],
                mode: "lines",
            },
        )?

    chart : Chart F64 F64
    chart =
        Chart.empty({})
        |> Chart.add_scatter_chart(scatter)
        |> Chart.with_layout(
            Layout.new(
                {
                    title: Title.new({ text: "House Price vs Size" }),
                    x_axis: Axis.new(
                        {
                            title: Title.new({ text: "Square Meters" }),
                            range: Set({ min: 40, max: 160 }),
                        },
                    ),
                    y_axis: Axis.new(
                        {
                            title: Title.new({ text: "Price in Millions ($USD)" }),
                            range: Set({ min: 5, max: 16 }),
                        },
                    ),
                },
            ),
        )

    File.write_utf8!(Chart.to_html(chart), "out.html")?

    Cmd.exec!("open", ["out.html"])?

    Ok({})
