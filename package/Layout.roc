module [
    Attr,
    from_attrs,
    title,
]

import Title

Attr := [
    Title (List Title.Attr),
]
    implements [Inspect]

title : List Title.Attr -> Attr
title = \title_attrs ->
    @Attr (Title title_attrs)

from_attrs : List Attr -> Str
from_attrs = \attrs ->

    fields_str =
        attrs
        |> List.map \@Attr inner ->
            when inner is
                Title title_attrs -> Title.from_attrs title_attrs
        |> Str.joinWith ","

    "\"layout\":{$(fields_str)}"
