app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.18.0/0APbwVN1_p1mJ96tXjaoiUCr8NBGamr8G8Ac_DrXR-o.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.11.0/z45Wzc-J39TLNweQUoLw3IGZtkQiEN3lTBv3BXErRjQ.tar.br",
    plume: "../package/main.roc",
}

import cli.File
import cli.Env
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

main! = \_ ->

    firebrick = Color.named? "DeepSkyBlue"
    fuscia = Color.hex? "#ffbbff"
    purple = Color.rgba 124 56 245 150

    select_color = \str ->
        if str == "Income" then
            fuscia
        else if str == "Bills" then
            purple
        else
            firebrick

    path = Env.var! "INPUT" |> Result.mapErr? \_ -> MissingEnvVar "expected path, e.g. INPUT=examples/baseline.json"

    scenario : Scenario
    scenario = Decode.fromBytes? (File.read_bytes!? path) Json.utf8

    flows = flow_analysis scenario.links

    links =
        scenario.links
        |> List.map \{ source, target, monthly } -> { source, target, value: monthly }

    nodes =
        scenario.links
        |> List.map \{ source, target } -> [source, target]
        |> List.join
        |> Set.fromList
        |> Set.toList
        |> List.map \label -> {
            label,
            color: select_color label,
            hover: hover_label label flows |> Result.withDefault "NODE NOT FOUND",
        }

    chart =
        Chart.empty
        |> Chart.add_sankey_chart (Sankey.new { nodes, links })
        |> Chart.with_layout [
            Layout.title [
                Title.text "Budget Scenario: $(scenario.scenario)",
            ],
        ]

    File.write_utf8! (Chart.to_html chart) "out.html"

hover_label : Str, Dict Str { in : F64, out : F64 } -> Result Str _
hover_label = \label, dict ->

    { in, out } = Dict.get? dict label

    net = in - out

    [
        "<em>$(label)</em>",
        "In: $$(Num.toStr in)",
        "Out: $$(Num.toStr out)",
        "Net: $$(Num.toStr net)",
    ]
    |> List.intersperse "<br>"
    |> Str.joinWith ""
    |> Ok

flow_analysis : List Link -> Dict Str { in : F64, out : F64 }
flow_analysis = \links ->
    List.walk links (Dict.empty {}) \dict, { source, target, monthly } ->
        # Update source node's outflow
        dictWithSource =
            Dict.update dict source \maybeValue ->
                when maybeValue is
                    Err Missing -> Ok { in: 0, out: monthly }
                    Ok value -> Ok { value & out: value.out + monthly }

        # Update target node's inflow
        Dict.update dictWithSource target \maybeValue ->
            when maybeValue is
                Err Missing -> Ok { in: monthly, out: 0 }
                Ok value -> Ok { value & in: value.in + monthly }
