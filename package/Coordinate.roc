import InternalJson
import Time

## One Cartesian coordinate: a category/date string or a finite number.
## String and numeric literals are checked by their literal conversions.
## Runtime text uses [Coordinate.from_text]; runtime floating numbers pass
## through [Coordinate.from_number] before entering a point.
Coordinate :: [Text(Str), Number(F64)].{

	## Compare coordinates by kind and value; text "1" differs from numeric 1.
	is_eq : _

	## Hash the coordinate kind and value consistently with [Coordinate.is_eq].
	to_hash : _

	## Construct categorical or date text. Plotly interprets date strings
	## according to the selected axis type.
	from_text : Str -> Coordinate
	from_text = |text| Text(text)

	## Construct a date coordinate from a validated UTC instant.
	## The coordinate is the instant's Plotly date text, as returned by
	## [Time.to_str], so it equals the matching [Coordinate.from_text] value.
	## Use it on an axis whose type is `Date`, or let Plotly infer the type.
	##
	## ```roc
	## expect {
	##     start = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 9 })?
	##     Coordinate.from_time(start).to_json() == "\"2026-11-11 09:00\""
	## }
	## ```
	from_time : Time -> Coordinate
	from_time = |time| Text(time.to_str())

	## Construct a numeric coordinate after checking that it is finite.
	## Returns `NonFiniteCoordinate(number)` for NaN or either infinity.
	## All finite F64 values, including negative values and zero, are
	## accepted without changing them. Numbers use F64 precision.
	##
	## ```roc
	## expect {
	##     coordinate = Coordinate.from_number(2.5)?
	##     coordinate.to_json() == "2.5"
	## }
	## ```
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

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Coordinate.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
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

## Time coordinates are the instant's Plotly date text.
expect {
	time = Time.from_epoch_millis(1_762_853_405_250)?
	Coordinate.from_time(time) == Coordinate.from_text("2025-11-11 09:30:05.250")
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
