module [
    Trace,
    new,
    with_name,
    to_str,
]

import Color

Trace node value := {
    name : Str,
    nodes : List { label : node, color : Color.Color },
    links : List { source : node, target : node, value : value },
    orientation : [Vertical, Horizontal],
}
    implements [Inspect]

new :
    {
        name : Str,
        nodes : List { label : node, color : Color.Color },
        links : List { source : node, target : node, value : value },
    }
    -> Trace node value
new = \{ name, nodes, links } -> @Trace {
        name,
        nodes,
        links,

        # default values
        orientation: Vertical,
    }

with_name : Trace node value, Str -> Trace node value
with_name = \@Trace trace, name ->
    @Trace { trace & name }

node_help : List Str -> Str
node_help = \nodes ->
    if List.isEmpty nodes then
        "{}"
    else
        """
        {"label": [$(Str.joinWith nodes ",")]}
        """

link_help : List Str, List { source : Str, target : Str, value : Str } -> Str
link_help = \labels, links ->

    indexes = help_indexes labels 0 (Dict.empty {})

    (value_str, source_str, target_str) = help_links indexes links ([], [], [])

    """
    {"value":[$(value_str)],"source":[$(source_str)],"target":[$(target_str)]}
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

help_links : Dict Str U64, List { source : Str, target : Str, value : Str }_, (List Str, List Str, List Str) -> (Str, Str, Str)
help_links = \indexes, ls, (values, sources, targets) ->
    when ls is
        [] ->
            (
                values |> Str.joinWith ",",
                sources |> Str.joinWith ",",
                targets |> Str.joinWith ",",
            )

        [{ source, target, value }, .. as rest] ->
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
            )

to_str : Trace node value -> Str where node implements Inspect, value implements Inspect
to_str = \@Trace data ->

    # orientation_str = if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\","

    labels : List Str
    labels =
        data.nodes
        |> List.map .label
        |> List.map Inspect.toStr

    links : List { source : Str, target : Str, value : Str }
    links =
        data.links
        |> List.map \{ source, target, value } ->
            # map to Str using Inspect here to ensure we have Hash and Eq,
            # and avoid some type craziness
            { source: Inspect.toStr source, target: Inspect.toStr target, value: Inspect.toStr value }

    node_str = node_help labels

    links_str = link_help labels links

    """
    {
        "type":"sankey",
        "name":\"$(data.name)\",
        "node":$(node_str),
        "arrangement": "snap",
        "link":$(links_str)
    }
    """
