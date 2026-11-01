import Font
import InternalJson

## A visible chart or axis title, or an inherited title setting.
Title :: [Hidden, Text(Props)].{
	Props := { text : Str, font : Font ?? Font.default }

	default : Title
	default = Hidden

	new : Props -> Title
	new = |props| Text(props)

	## Read title text. An inherited title has no explicit text.
	get_text : Title -> Try(Str, [TitleNotSet])
	get_text = |title| match title {
		Hidden => Err(TitleNotSet)
		Text(props) => Ok(props.text)
	}

	to_json_value : Title -> InternalJson
	to_json_value = |title| match title {
		Hidden => InternalJson.object([])
		Text(props) => InternalJson.object([
			{ name: "text", value: InternalJson.string(props.text) },
			{ name: "font", value: props.font.to_json_value() },
		])
	}
	to_json : Title -> Str
	to_json = |title| title.to_json_value().to_json()
}

expect Title.default.get_text() == Err(TitleNotSet)
expect Title.default.to_json() == "{}"
expect {
	original = "A \"title\"\n雪</script>"
	title = Title.new({ text: original })
	parsed : Try({ text : Str }, _)
	parsed = Json.parse(title.to_json())
	parsed == Ok({ text: original }) and title.get_text() == Ok(original)
}
