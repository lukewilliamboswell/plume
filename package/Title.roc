import Font
import InternalJson

## A visible chart or axis title, or an inherited title setting.
Title :: [Hidden, Text(Props)].{

	## A visible title's text and font override.
	## `text` is required and may be empty. Plotly interprets supported text
	## markup. `font` defaults to [Font.default], inheriting chart styling.
	Props := { text : Str, font : Font ?? Font.default }

	## Leave the title unset, encoding an empty object.
	## This is different from a title whose text is the empty string.
	default : Title
	default = Hidden

	## Construct a visible title without a fallible validation step.
	## Use it for the chart title in [Layout.Props] or for an axis title.
	## The supplied text is escaped during JSON encoding.
	new : Props -> Title
	new = |props| Text(props)

	## Read the explicitly supplied title text, including an empty string.
	## Returns `TitleNotSet` only for [Title.default]; it does not invent a
	## fallback title.
	get_text : Title -> Try(Str, [TitleNotSet])
	get_text = |title| match title {
		Hidden => Err(TitleNotSet)
		Text(props) => Ok(props.text)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Title.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Title -> InternalJson
	to_json_value = |title| match title {
		Hidden => InternalJson.object([])
		Text(props) => InternalJson.object([
			{ name: "text", value: InternalJson.string(props.text) },
			{ name: "font", value: props.font.to_json_value() },
		])
	}

	## Serialize this validated value as a complete JSON document.
	to_json : Title -> Str
	to_json = |title| title.to_json_value().to_json()
}

## Inherited titles report that no explicit title is set.
expect Title.default.get_text() == Err(TitleNotSet)

## Inherited titles serialize as an empty object.
expect Title.default.to_json() == "{}"

## Title text survives quotes, controls, Unicode and markup.
expect {
	original = "A \"title\"\n雪</script>"
	title = Title.new({ text: original })
	parsed : { text : Str }
	parsed = Json.parse(title.to_json())?
	parsed == { text: original } and title.get_text()? == original
}

## An explicit empty title is different from an inherited title.
expect Title.new({ text: "" }).get_text()? == ""
