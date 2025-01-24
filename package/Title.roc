module [
    Title,
    new,
    default,
    to_str,
    get_text,
]

import Font

Title := [
    None,
    Some {
            text : Str,
            font : Font.Font,
        },
]
    implements [Inspect]

new : { text : Str, font ?? Font.Font } -> Title
new = |{ text, font ?? Font.default }|
    @Title(Some({ text, font }))

default : Title
default = @Title(None)

get_text : Title -> Result Str [NotFound]
get_text = |@Title(inner)|
    when inner is
        None -> Err(NotFound)
        Some({ text }) -> Ok(text)

to_str : Title -> Str
to_str = |@Title(inner)|
    when inner is
        None -> ""
        Some({ text, font }) ->
            [
                Font.to_str(font),
                "\"text\":\"${text}\"",
            ]
            |> List.drop_if(Str.is_empty)
            |> Str.join_with(",")
            |> |str| "\"title\":{${str}}"
