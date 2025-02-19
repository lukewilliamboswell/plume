app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/bi5zubJ-_Hva9vxxPq4kNx4WHX6oFs8OP6Ad0tCYlrY.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Cmd
import plume.Chart exposing [Chart]
import plume.Font
import plume.Layout
import plume.Title
import plume.Color
import plume.Sankey

main! = |_|

    fuscia = Color.hex("#ff00ff")?
    purple = Color.rgba(124, 56, 245, 150)

    global_font = Font.new(
        {
            family: "'Comic Sans MS', 'Chalkboard SE', 'Comic Neue', sans-serif;",
            style: Italic,
        },
    )?

    sankey_chart : Sankey.Trace U8 F64
    sankey_chart =
        Sankey.new(
            {
                nodes: [
                    { label: 1, color: fuscia, hover: "<em>Node A</em><br>In: $12.50<br>Out: $32.00<br>" },
                    { label: 2, color: fuscia, hover: "<em>Node B</em><br>In: $12.50<br>Out: $32.00<br>" },
                    { label: 3, color: purple, hover: "<em>Node C</em><br>In: $12.50<br>Out: $32.00<br>" },
                    { label: 4, color: purple, hover: "<em>Node D</em><br>In: $12.50<br>Out: $32.00<br>" },
                    { label: 5, color: fuscia, hover: "<em>Node E</em><br>In: $12.50<br>Out: $32.00<br>" },
                ],
                links: [
                    { source: 1, target: 3, value: 8.0, hover: "" },
                    { source: 2, target: 4, value: 4.0, hover: "" },
                    { source: 1, target: 4, value: 2.0, hover: "" },
                    { source: 3, target: 5, value: 8.0, hover: "" },
                    { source: 4, target: 5, value: 4.0, hover: "" },
                    { source: 4, target: 5, value: 2.0, hover: "" },
                ],
            },
        )

    chart : Chart U8 F64
    chart =
        Chart.empty({})
        |> Chart.add_sankey_chart(sankey_chart)
        |> Chart.with_layout(Layout.new({ global_font, title: Title.new({ text: "Example Sankey Chart" }) }))

    File.write_utf8!(Chart.to_html(chart), "out.html")?

    Cmd.exec!("open", ["out.html"])?

    Ok({})
