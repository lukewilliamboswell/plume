module [
    Axis,
    new,
    #default,
    to_str,
]

Axis := [
    None,
    Some {
        type : Str,
        range : Str,
    },
]

new :{type ? Str,range ? Str,} -> Axis
new = \{ type ? "", range ? ""} ->
    @Axis (Some { type,  range })

#default : Axis/
#default = @Axis None

to_str : Axis -> Str
to_str = \_ -> ""
