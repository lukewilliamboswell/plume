module [
    Layout,
    new,
    to_str,
]

import Axis

Layout := {
    x_axis : Axis.Axis,
    y_axis : Axis.Axis,
    show_legend : Bool,
}
    implements [Inspect]

new : { x_axis ? Axis.Axis, y_axis ? Axis.Axis, show_legend ? Bool, } -> Layout
new = \{  x_axis ? Axis.new {}, y_axis ? Axis.new {}, show_legend ? Bool.false } ->
    @Layout {
        x_axis,
        y_axis,
        show_legend,
    }

to_str : Layout -> Str
to_str = \_ -> ""
