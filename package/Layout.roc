module [
    Attr,
    from_attrs,
    title,
    x_axis,
    y_axis,
    global_font,
    show_legend,
    get_title,
]

import Title
import Font

Attr := [
    GlobalFont (List Font.Attr),
    Title (List Title.Attr),
    XAxis (List Title.Attr),
    YAxis (List Title.Attr),
    ShowLegend Bool,
]
    implements [Inspect]

global_font : List Font.Attr -> Attr
global_font = \font_attrs ->
    @Attr (GlobalFont font_attrs)

title : List Title.Attr -> Attr
title = \title_attrs ->
    @Attr (Title title_attrs)

x_axis : List Title.Attr -> Attr
x_axis = \x_axis_attrs ->
    @Attr (XAxis x_axis_attrs)

y_axis : List Title.Attr -> Attr
y_axis = \y_axis_attrs ->
    @Attr (YAxis y_axis_attrs)

show_legend : Bool -> Attr
show_legend = \show ->
    @Attr (ShowLegend show)

get_title : List Attr -> Result Str [NotFound]
get_title = \attrs ->
    attrs
    |> List.keepOks \@Attr attr ->
        when attr is
            Title title_attrs -> Title.get_text title_attrs
            _ -> Err NotFound
    |> List.first
    |> Result.mapErr \ListWasEmpty -> NotFound

from_attrs : List Attr -> Str
from_attrs = \attrs ->

    fields_str =
        attrs
        |> List.map \@Attr inner ->
            when inner is
                GlobalFont font_attrs -> Font.from_attrs font_attrs
                Title title_attrs -> Title.from_attrs title_attrs
                XAxis x_axis_attrs -> "\"xaxis\":{$(Title.from_attrs x_axis_attrs)}"
                YAxis y_axis_attrs -> "\"yaxis\":{$(Title.from_attrs y_axis_attrs)}"
                ShowLegend show ->
                    if show then
                        "\"showlegend\":true"
                    else
                        "\"showlegend\":false"

        |> Str.joinWith ","

    "\"layout\":{$(fields_str)}"
