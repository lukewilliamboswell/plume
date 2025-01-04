module [
    Trace,
    new,
    to_str,
]

Trace x y := Str

new :{} -> Result (Trace x y) _
new = \{} -> Ok (@Trace "")

to_str : Trace x y -> Str
to_str = \_ -> ""
