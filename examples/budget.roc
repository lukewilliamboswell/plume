app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/bi5zubJ-_Hva9vxxPq4kNx4WHX6oFs8OP6Ad0tCYlrY.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.12.0/1trwx8sltQ-e9Y2rOB4LWUWLS_sFVyETK8Twl0i9qpw.tar.gz",
    plume: "../package/main.roc",
}

import cli.File
import cli.Env
import cli.Cmd
import json.Json
import plume.Chart
import plume.Layout
import plume.Title
import plume.Color
import plume.Sankey

Scenario : {
    scenario : Str,
    links : List Link,
}

Link : {
    source : Str,
    target : Str,
    monthly : F64,
}

main! = |_|

    firebrick = Color.named("DeepSkyBlue")?
    fuscia = Color.hex("#ffbbff")?
    purple = Color.rgba(124, 56, 245, 150)

    select_color = |str|
        if str == "Income" then
            fuscia
        else if str == "Bills" then
            purple
        else
            firebrick

    path = Env.var!("INPUT") ? |_| MissingEnvVar("expected path, e.g. INPUT=examples/baseline.json")

    scenario : Scenario
    scenario = Decode.from_bytes(File.read_bytes!(path)?, Json.utf8)?

    flows = flow_analysis(scenario.links)

    links =
        scenario.links
        |> List.map(
            |{ source, target, monthly }| {
                source,
                target,
                value: monthly,
                hover: "${source} -> ${target}: $${Num.to_str(monthly)}",
            },
        )

    nodes =
        scenario.links
        |> List.map(|{ source, target }| [source, target])
        |> List.join
        |> Set.from_list
        |> Set.to_list
        |> List.map(
            |label| {
                label,
                color: select_color(label),
                hover: hover_label(label, flows) |> Result.with_default("NODE NOT FOUND"),
            },
        )

    chart =
        Chart.empty({})
        |> Chart.add_sankey_chart(Sankey.new({ nodes, links }))
        |> Chart.with_layout(Layout.new({ title: Title.new({ text: "Budget Scenario: ${scenario.scenario}" }) }))

    File.write_utf8!(Chart.to_html(chart), "out.html")?

    Cmd.exec!("open", ["out.html"])?

    Ok({})

hover_label : Str, Dict Str { in : F64, out : F64 } -> Result Str _
hover_label = |label, dict|

    { in, out } = Dict.get(dict, label)?

    net = in - out

    [
        "<em>${label}</em>",
        "In: $${Num.to_str(in)}",
        "Out: $${Num.to_str(out)}",
        "Net: $${Num.to_str(net)}",
    ]
    |> List.intersperse("<br>")
    |> Str.join_with("")
    |> Ok

flow_analysis : List Link -> Dict Str { in : F64, out : F64 }
flow_analysis = |links|
    List.walk(
        links,
        Dict.empty({}),
        |dict, { source, target, monthly }|
            # Update source node's outflow
            dict_with_source =
                Dict.update(
                    dict,
                    source,
                    |maybe_value|
                        when maybe_value is
                            Err(Missing) -> Ok({ in: 0, out: monthly })
                            Ok(value) -> Ok({ value & out: value.out + monthly }),
                )

            # Update target node's inflow
            Dict.update(
                dict_with_source,
                target,
                |maybe_value|
                    when maybe_value is
                        Err(Missing) -> Ok({ in: monthly, out: 0 })
                        Ok(value) -> Ok({ value & in: value.in + monthly }),
            ),
    )
