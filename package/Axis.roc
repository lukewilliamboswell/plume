module [
    Axis,
    Type,
    new,
    default,
    to_str,
]

import Title
import Color

Axis := [
    None,
    Some {
        type : Type,
        title : Title.Title,
        range : Str,
        color : Color.Color,
    },
]

Type : [
    None,
    Auto,
    Linear,
    Log,
    Date,
    Category,
    MultiCategory,
]

new :
    {
        title ? Title.Title,
        type ? Type,
        range ? Str,
        color ? Color.Color,
    }
    -> Axis
new = \{ type ? None, title ? Title.default, range ? "", color ? Color.rgb 68 68 68 } ->
    @Axis (Some { type, title, range, color })

default : Axis
default = @Axis None

to_str : Axis -> Str
to_str = \@Axis outer ->
    when outer is
        None -> ""
        Some inner ->
            title_str = Title.to_str inner.title

            # TODO check this is valid
            range_str = if Str.isEmpty inner.range then "" else "\"range\":$(inner.range)"

            type_str = if inner.type == None then "" else "\"type\": \"$(axis_type_to_str inner.type)\""

            color_str = "\"color\":\"$(Color.to_str inner.color)\""

            [
                range_str,
                type_str,
                title_str,
                color_str,
            ]
            |> List.dropIf Str.isEmpty
            |> Str.joinWith ","
            |> \str -> "{$(str)}"

axis_type_to_str : Type -> Str
axis_type_to_str = \axis_type ->
    when axis_type is
        None -> ""
        Auto -> "auto"
        Linear -> "linear"
        Log -> "log"
        Date -> "date"
        Category -> "category"
        MultiCategory -> "multicategory"

# Sets the range of this axis. If the axis `type` is "log", then you must take the log of your desired range (e.g. to set the range from 1 to 100, set the range from 0 to 2). If the axis `type` is "date", it should be date strings, like date data, though Date objects and unix milliseconds will be accepted and converted to strings. If the axis `type` is "category", it should be numbers, using the scale where each category is assigned a serial number from zero in the order it appears. Leaving either or both elements `null` impacts the default `autorange`.
# check_valid_range = ...
