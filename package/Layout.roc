module [
    Layout,
    new,
    to_str,
]

Layout := {}
    implements [Inspect]

new : {} -> Layout
new = \{} -> @Layout {}

to_str : Layout -> Str
to_str = \_ -> ""
