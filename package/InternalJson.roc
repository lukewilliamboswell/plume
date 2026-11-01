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

## JSON string encoding preserves controls, quotes and Unicode.
expect {
	# Quotes, slashes, controls and Unicode must survive a JSON round trip.
	original = "a\"\\\n\t\u(1)雪"
	parsed : { text : Str }
	parsed = Json.parse(InternalJson.object([{ name: "text", value: InternalJson.string(original) }]).to_json())?
	parsed == { text: original }
}

## Empty objects serialize exactly.
expect InternalJson.object([]).to_json() == "{}"

## Empty arrays serialize exactly.
expect InternalJson.array([]).to_json() == "[]"

## Positive infinity cannot be encoded as JSON.
expect InternalJson.encode(F64.infinity) == Err(Infinity)

## NaN cannot be encoded as JSON.
expect InternalJson.encode(F64.nan) == Err(NaN)

## Negative infinity cannot be encoded as JSON.
expect InternalJson.encode(-F64.infinity) == Err(NegativeInfinity)

## Object keys are encoded, and fields keep their supplied order.
expect InternalJson.object([
	{ name: "a\"\n", value: InternalJson.array([InternalJson.string("x"), InternalJson.encode(2.U64)?]) },
	{ name: "", value: InternalJson.encode(Bool.False)? },
]).to_json() == "{\"a\\\"\\n\":[\"x\",2],\"\":false}"

## Finite floating extrema retain their value through JSON encoding.
expect {
	var $passed = True
	for number in [F64.lowest, -1, -0.0, 0, 1, F64.highest] {
		encoded = InternalJson.encode(number)?
		decoded : F64
		decoded = Json.parse(encoded.to_json())?
		$passed = $passed and !(decoded != number)
	}
	$passed
}
