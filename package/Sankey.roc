module [
    Trace,
    new,
    to_str,
]

import Color

Link node value : {
    source : node,
    target : node,
    value : value,
    hover : Str,
}

Trace node value := {
    nodes : List {
        label : node,
        color : Color.Color,

        # only some html elements permitted
        # ['br', 'sub', 'sup', 'b', 'i', 'em']
        # https://github.com/plotly/plotly.js/blob/c1ef6911da054f3b16a7abe8fb2d56019988ba14/src/components/fx/hover.js#L1596
        hover : Str,
    },
    links : List (Link node value),
    orientation : [Vertical, Horizontal],
}
    implements [Inspect]

new :
    {
        nodes : List { label : node, color : Color.Color, hover : Str },
        links : List (Link node value),
    }
    -> Trace node value
new = \{ nodes, links } -> @Trace {
        nodes,
        links,

        # default values
        orientation: Vertical,
    }

node_help : List { label : node, color : Color.Color, hover : Str } -> Str where node implements Inspect
node_help = \nodes ->

    nodes_str =
        nodes
        |> List.map \node -> "$(Inspect.toStr node.label)"
        |> Str.joinWith ","

    color_str =
        nodes
        |> List.map \node -> "\"$(Color.to_str node.color)\""
        |> Str.joinWith ","

    custom_data_str =
        # if any nodes have hover text, we need to add custom data to it
        if List.any nodes \node -> !(Str.isEmpty node.hover) then
            custom_data_strs =
                nodes
                |> List.map \node -> "\"$(node.hover)\""
                |> Str.joinWith ","

            """
            "customdata": [$(custom_data_strs)],
            "hovertemplate": "%{customdata}<extra></extra>",
            """
        else
            ""

    if List.isEmpty nodes then
        "{}"
    else
        """
        {$(custom_data_str)"label":[$(nodes_str)],"color":[$(color_str)]}
        """

link_help : List Str, List (Link Str Str) -> Str
link_help = \labels, links ->

    indexes = help_indexes labels 0 (Dict.empty {})

    (value_str, source_str, target_str, hover_str) = help_links indexes links ([], [], [], [])

    custom_data_str =
        if List.any links \link -> !(Str.isEmpty link.hover) then
            """
            "customdata": [$(hover_str)],
            "hovertemplate": "%{customdata}<extra></extra>",
            """
        else
            ""

    """
    {$(custom_data_str)"value":[$(value_str)],"source":[$(source_str)],"target":[$(target_str)]}
    """

# map the node labels to their index from the nodes list
help_indexes : List Str, U64, Dict Str U64 -> Dict Str U64
help_indexes = \ls, idx, dict ->
    when ls is
        [] -> dict
        [first, .. as rest] ->
            if Dict.contains dict first then
                crash "Found duplicate node value $(Inspect.toStr first)"
            else
                help_indexes rest (Num.addWrap idx 1) (Dict.insert dict first idx)

help_links : Dict Str U64, List (Link Str Str), (List Str, List Str, List Str, List Str) -> (Str, Str, Str, Str)
help_links = \indexes, ls, (values, sources, targets, hovers) ->
    when ls is
        [] ->
            (
                values |> Str.joinWith ",",
                sources |> Str.joinWith ",",
                targets |> Str.joinWith ",",
                hovers |> Str.joinWith ",",
            )

        [{ source, target, value, hover }, .. as rest] ->
            source_idx =
                when Dict.get indexes source is
                    Ok u64 -> Num.toStr u64
                    _ -> crash "Missing source node $(Inspect.toStr source)"

            target_idx =
                when Dict.get indexes target is
                    Ok u64 -> Num.toStr u64
                    _ -> crash "Missing target node $(Inspect.toStr target)"

            help_links indexes rest (
                List.append values value,
                List.append sources source_idx,
                List.append targets target_idx,
                List.append hovers "\"$(hover)\"",
            )

to_str : Trace node value -> Str where node implements Inspect, value implements Inspect
to_str = \@Trace data ->

    # orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    labels : List Str
    labels =
        data.nodes
        |> List.map .label
        |> List.map Inspect.toStr

    links : List (Link Str Str)
    links =
        List.map data.links \{ source, target, value, hover } ->
            # map to Str using Inspect here to ensure we have Hash and Eq,
            # and avoid some type craziness
            {
                source: Inspect.toStr source,
                target: Inspect.toStr target,
                value: Inspect.toStr value,
                hover,
            }

    node_str = node_help data.nodes

    links_str = link_help labels links

    """
    {
        "type":"sankey",
        "node":$(node_str),
        "arrangement": "snap",
        "link":$(links_str)
    }
    """
