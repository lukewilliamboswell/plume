module [
    Layout,
    new,
    to_str,
    get_title,
]

import Title
import Font
import Axis

Layout x y := {
    global_font : Font.Font,
    title : Title.Title,
    x_axis : Axis.Axis x,
    y_axis : Axis.Axis y,
    show_legend : Bool,
}
    implements [Inspect]

new :
    {
        global_font ?? Font.Font,
        title ?? Title.Title,
        x_axis ?? Axis.Axis x,
        y_axis ?? Axis.Axis y,
        show_legend ?? Bool,
    }
    -> Layout x y
new = |{ global_font ?? Font.default, title ?? Title.default, x_axis ?? Axis.default({}), y_axis ?? Axis.default({}), show_legend ?? Bool.false }|
    @Layout(
        {
            global_font,
            title,
            x_axis,
            y_axis,
            show_legend,
        },
    )

get_title : Layout x y -> Result Str [NotFound]
get_title = |@Layout({ title })|
    Title.get_text(title)

to_str : Layout x y -> Str where x implements Inspect, y implements Inspect
to_str = |@Layout(inner)|

    global_font_str = Font.to_str(inner.global_font)

    x_axis_str =
        str = Axis.to_str(inner.x_axis)
        if Str.is_empty(str) then
            ""
        else
            "\"xaxis\":${str}"

    y_axis_str =
        str = Axis.to_str(inner.y_axis)
        if Str.is_empty(str) then
            ""
        else
            "\"yaxis\":${str}"

    title_str = Title.to_str(inner.title)

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
    |> List.drop_if(Str.is_empty)
    |> Str.join_with(",")
    |> |str| "{${str}}"
