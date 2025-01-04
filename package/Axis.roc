module [
    Axis,
    new,
    to_str,
]

Axis := Str

new :{} -> Axis
new = \{} ->
    @Axis ""

to_str : Axis -> Str
to_str = \_ -> ""
