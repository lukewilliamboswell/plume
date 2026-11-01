## JSON assembled only from values encoded by Roc's builtin JSON encoder.
## This internal type has no constructor accepting preformatted JSON.
InternalJson :: Str.{
    is_eq : _
    ## Encode a JSON string, including its quotes and escapes.
    string : Str -> InternalJson
    string = |text| InternalJson.(Json.to_str(text))

    ## Encode any JSON-encodable value, refusing non-finite floating numbers.
    encode : value -> Try(InternalJson, err) where [value.Json.Encodable(err)]
    encode = |value| Ok(InternalJson.(Json.to_str_try(value)?))

    ## Compose an object from safely encoded fields.
    object : List({ name : Str, value : InternalJson }) -> InternalJson
    object = |fields| {
        entries = fields.map(|{ name, value: InternalJson.(json) }| "${Json.to_str(name)}:${json}")
        InternalJson.("{${Str.join_with(entries, ",")}}")
    }

    ## Compose an array from safely encoded values.
    array : List(InternalJson) -> InternalJson
    array = |values| InternalJson.("[${Str.join_with(values.map(to_json), ",")}]")

    ## Read the complete JSON document.
    to_json : InternalJson -> Str
    to_json = |InternalJson.(json)| json
}

expect {
    # Quotes, slashes, controls and Unicode must survive a JSON round trip.
    original = "a\"\\\n\t\u(1)雪"
    parsed : Try({ text : Str }, _)
    parsed = Json.parse(InternalJson.object([{ name: "text", value: InternalJson.string(original) }]).to_json())
    parsed == Ok({ text: original })
}

expect InternalJson.object([]).to_json() == "{}"
expect InternalJson.array([]).to_json() == "[]"
expect InternalJson.encode(F64.infinity) == Err(Infinity)
expect InternalJson.encode(F64.nan) == Err(NaN)
expect InternalJson.encode(-F64.infinity) == Err(NegativeInfinity)
