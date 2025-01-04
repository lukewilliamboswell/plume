module [
    Marker,
    new,
    to_str,
]

Marker := {}
    implements [Inspect]

new : {} -> Result Marker _
new = \{} -> Ok (@Marker {})

to_str : Marker -> Str
to_str = \_ -> ""
