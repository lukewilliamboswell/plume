module [
    Color,
    BarTrace,
    new,
    with_color,
    to_html,
]

# REFERENCE https://plotly.com/javascript/reference/bar/

import "static/template.html" as template : Str

to_html : BarTrace x y -> Str where x implements Inspect, y implements Inspect
to_html = \data ->
    Str.replaceFirst
        template
        "{{REPLACE_ME}}"
        """
        {
            "data": [$(data_to_str data)]
        }
        """

Color : [
    RGB U8 U8 U8,
    Named Str,
    Hex Str,
]

BarTrace x y := {
    xy : List (x, y),
    orientation : [Vertical, Horizontal],
    color : Color,
}

new : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @BarTrace {
        xy,
        orientation: Vertical,
        color: RGB 124 56 245,
    }

with_color : BarTrace x y, Color -> BarTrace x y
with_color = \@BarTrace trace, color ->
    @BarTrace { trace & color }

color_to_str : Color -> Str
color_to_str = \color ->
    when color is
        RGB r g b -> "rgb($(Num.toStr r), $(Num.toStr g), $(Num.toStr b))"
        Named name -> name
        Hex hex -> hex

data_to_str : BarTrace x y -> Str where x implements Inspect, y implements Inspect
data_to_str = \@BarTrace data ->

    data2 = List.walk data.xy ([], []) \(xs, ys), (x, y) -> (List.append xs x, List.append ys y)

    x_str = List.map data2.0 Inspect.toStr |> Str.joinWith ", "
    y_str = List.map data2.1 Inspect.toStr |> Str.joinWith ", "

    """
    {
        "x": [$(x_str)],
        "y": [$(y_str)],
        "showlegend": true,
        "type": "bar",
        "marker": {
            "color": "$(color_to_str data.color)"
        },
        "opacity": 1,
        $(if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\",")
        "name": "Fruits"
    }
    """
