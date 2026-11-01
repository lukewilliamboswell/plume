import InternalJson

## One Cartesian coordinate: a category/date string or a finite number.
## String and numeric literals are checked by their literal conversions.
## Runtime text uses [Coordinate.from_text]; runtime floating numbers pass
## through [Coordinate.from_number] before entering a point.
Coordinate :: [Text(Str), Number(F64)].{
	is_eq : _
	to_hash : _

	## Construct categorical or date text. Plotly interprets date strings
	## according to the selected axis type.
	from_text : Str -> Coordinate
	from_text = |text| Text(text)

	## Reject NaN and either infinity before a number can enter a trace.
	from_number : F64 -> Try(Coordinate, [NonFiniteCoordinate(F64)])
	from_number = |number| if (number.is_finite()) Ok(Number(number)) else Err(NonFiniteCoordinate(number))

	## A string literal denotes a text coordinate.
	from_quote : Str -> Try(Coordinate, [BadQuotedBytes(Str)])
	from_quote = |text| Ok(Text(text))

	## A numeric literal denotes a finite numeric coordinate.
	from_numeral : Numeral -> Try(Coordinate, [InvalidNumeral(Str)])
	from_numeral = |numeral| {
		number = F64.from_numeral(numeral)?
		if (number.is_finite()) Ok(Number(number)) else Err(InvalidNumeral("Coordinates must be finite numbers"))
	}

	## Compose a scalar JSON value. The opaque constructors guarantee that
	## the number encoder cannot encounter a non-finite value.
	to_json_value : Coordinate -> InternalJson
	to_json_value = |coordinate| match coordinate {
		Text(text) => InternalJson.string(text)
		Number(number) => InternalJson.encode(number) ?? crash "Coordinate.to_json_value: non-finite number passed constructor"
	}

	## Serialize this scalar as a complete JSON document.
	to_json : Coordinate -> Str
	to_json = |coordinate| coordinate.to_json_value().to_json()
}

## Text literals preserve category and date strings without becoming numbers.
expect {
	coordinate : Coordinate
	coordinate = "2026-11-01"
	decoded : Str
	decoded = Json.parse(coordinate.to_json())?
	decoded == "2026-11-01"
}

## Numeric literals remain JSON numbers, including negative fractions.
expect {
	coordinate : Coordinate
	coordinate = -1.25
	decoded : F64
	decoded = Json.parse(coordinate.to_json())?
	decoded == -1.25
}

## Runtime text round-trips quotes, controls and Unicode through JSON.
expect {
	original = "quote\" slash\\ newline\n 雪 </script>"
	coordinate = Coordinate.from_text(original)
	decoded : Str
	decoded = Json.parse(coordinate.to_json())?
	decoded == original
}

## Every finite numeric endpoint is admitted without changing its value.
expect {
	var $passed = True
	for number in [F64.lowest, -1, -0.0, 0, 1, F64.highest] {
		coordinate = Coordinate.from_number(number)?
		decoded : F64
		decoded = Json.parse(coordinate.to_json())?
		$passed = $passed and decoded == number
	}
	$passed
}

## Runtime NaN and both infinities are rejected before construction.
expect [F64.nan, F64.infinity, -F64.infinity].map(|number| Coordinate.from_number(number).is_err()) == [True, True, True]

## Text and numeric coordinates remain distinct even when their text matches.
expect {
	text : Coordinate
	text = "1"
	number : Coordinate
	number = 1
	text != number and text == Coordinate.from_text("1") and number == Coordinate.from_number(1)?
}
