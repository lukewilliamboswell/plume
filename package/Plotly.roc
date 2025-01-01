module [
    to_html,
]

# REFERENCE https://plotly.com/javascript/reference/bar/

import "static/template.html" as template : Str

to_html : {} -> Str
to_html = \{} ->

    data : BarTrace Str U64
    data = new [
        ("Apples", 2),
        ("Organes", 3),
        ("Bananas", 4),
    ]

    template
    |> Str.replaceFirst
        "{{REPLACE_ME}}"
        """
        {
            "data": [$(data_to_str data)]
        }
        """

BarTrace x y := {
    xy: List (x, y),
    orientation: [Vertical, Horizontal],
}

new : List (x, y) -> BarTrace x y where x implements Inspect, y implements Inspect
new = \xy -> @BarTrace { xy, orientation: Horizontal }

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
            "color": "rgb(142, 124, 195)"
        },
        "opacity": 0.6,
        $(if data.orientation == Vertical then "\"orientation\": \"v\"," else "\"orientation\": \"h\",")
        "name": "Fruits"
    }
    """
