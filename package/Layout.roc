module [
    Layout,
    new,
    to_str,
    get_title,
]

import Title
import Font
import Axis

Layout := {
    global_font : List Font.Attr,
    title : List Title.Attr,
    x_axis : Axis.Axis,
    y_axis : Axis.Axis,
    show_legend : Bool,
}
    implements [Inspect]

new :
    {
        global_font ? List Font.Attr,
        title ? List Title.Attr,
        x_axis ? Axis.Axis,
        y_axis ? Axis.Axis,
        show_legend ? Bool,
    }
    -> Layout
new = \{ global_font ? [], title ? [], x_axis ? Axis.default, y_axis ? Axis.default, show_legend ? Bool.false } ->
    @Layout {
        global_font,
        title,
        x_axis,
        y_axis,
        show_legend,
    }

get_title : Layout -> Result Str [NotFound]
get_title = \@Layout { title } ->
    Title.get_text title

to_str : Layout -> Str
to_str = \@Layout inner ->

    global_font_str = Font.from_attrs inner.global_font

    x_axis_str =
        str = Axis.to_str inner.x_axis
        if Str.isEmpty str then
            ""
        else
            "\"xaxis\":$(str)"

    y_axis_str =
        str = Axis.to_str inner.y_axis
        if Str.isEmpty str then
            ""
        else
            "\"yaxis\":$(str)"

    title_str = Title.from_attrs inner.title

    show_legend_str =
        if inner.show_legend then
            "\"showlegend\":true"
        else
            "\"showlegend\":false"

    [
        global_font_str,
        x_axis_str,
        y_axis_str,
        title_str,
        show_legend_str,
    ]
    |> List.dropIf Str.isEmpty
    |> Str.joinWith ","
    |> \str -> "{$(str)}"
