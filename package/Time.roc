## A UTC instant with millisecond precision, from 0001-01-01 00:00 to
## 9999-12-31 23:59:59.999. Use [Coordinate.from_time] to place it on a
## date axis, or `TimeBounds` in [Axis.RangeSpec] to bound such an axis.
Time :: I64.{

	## Compare instants; equal times denote the same millisecond.
	is_eq : _

	## Hash the instant consistently with [Time.is_eq].
	to_hash : _

	## A calendar date and time of day in UTC.
	## `month` runs from 1 to 12 and `day` from 1 to the length of that month,
	## including 29 February in leap years. `hour` (0–23), `minute` (0–59),
	## `second` (0–59) and `millisecond` (0–999) default to zero, so a date
	## alone denotes its midnight. Leap seconds are not represented.
	Calendar := {
		year : U16,
		month : U8,
		day : U8,
		hour : U8 ?? 0,
		minute : U8 ?? 0,
		second : U8 ?? 0,
		millisecond : U16 ?? 0,
	}

	## Construct an instant from milliseconds since 1970-01-01 00:00 UTC,
	## the unit of JavaScript's `Date.now()`. Negative values denote earlier
	## instants. Returns `TimeOutOfRange(millis)` outside the supported years.
	##
	## ```roc
	## expect {
	##     time = Time.from_epoch_millis(1_762_819_200_000)?
	##     time.to_str() == "2025-11-11"
	## }
	## ```
	from_epoch_millis : I64 -> Try(Time, [TimeOutOfRange(I64)])
	from_epoch_millis = |millis| if (millis >= earliest_millis and millis <= latest_millis) Ok(Time.(millis)) else Err(TimeOutOfRange(millis))

	## Construct an instant from whole seconds since 1970-01-01 00:00 UTC,
	## the unit of Unix timestamps. Returns `TimeOutOfRange(seconds)`
	## outside the supported years.
	from_epoch_seconds : I64 -> Try(Time, [TimeOutOfRange(I64)])
	from_epoch_seconds = |seconds| if (seconds >= earliest_millis // 1000 and seconds <= latest_millis // 1000) Ok(Time.(seconds * 1000)) else Err(TimeOutOfRange(seconds))

	## Construct an instant from a UTC calendar date and time of day.
	## Returns `InvalidDate({ year, month, day })` for a year outside 1–9999,
	## a month outside 1–12 or a day the month does not have, and
	## `InvalidTimeOfDay({ hour, minute, second, millisecond })` for a field
	## beyond its range.
	##
	## ```roc
	## expect {
	##     time = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 9, minute: 30 })?
	##     time.to_str() == "2026-11-11 09:30"
	## }
	## ```
	from_calendar : Calendar -> Try(Time, [InvalidDate({ year : U16, month : U8, day : U8 }), InvalidTimeOfDay({ hour : U8, minute : U8, second : U8, millisecond : U16 })])
	from_calendar = |calendar| {
		date = { year: calendar.year, month: calendar.month, day: calendar.day }
		if calendar.year < 1 or calendar.year > 9999 or calendar.month < 1 or calendar.month > 12 or calendar.day < 1 or calendar.day > days_in_month(date) {
			return Err(InvalidDate(date))
		}
		if calendar.hour > 23 or calendar.minute > 59 or calendar.second > 59 or calendar.millisecond > 999 {
			return Err(InvalidTimeOfDay({ hour: calendar.hour, minute: calendar.minute, second: calendar.second, millisecond: calendar.millisecond }))
		}
		days = days_from_civil(date)
		time_of_day = ((calendar.hour.to_i64() * 60 + calendar.minute.to_i64()) * 60 + calendar.second.to_i64()) * 1000 + calendar.millisecond.to_i64()
		Ok(Time.(days * millis_per_day + time_of_day))
	}

	## Read the instant as milliseconds since 1970-01-01 00:00 UTC.
	to_epoch_millis : Time -> I64
	to_epoch_millis = |Time.(millis)| millis

	## Read the UTC calendar date and time of day.
	to_calendar : Time -> Calendar
	to_calendar = |Time.(millis)| {
		since_earliest = millis - earliest_millis
		date = civil_from_days(since_earliest // millis_per_day + earliest_day)
		time_of_day = since_earliest % millis_per_day
		{
			year: date.year,
			month: date.month,
			day: date.day,
			hour: (time_of_day // 3_600_000).to_u8_wrap(),
			minute: (time_of_day // 60_000 % 60).to_u8_wrap(),
			second: (time_of_day // 1000 % 60).to_u8_wrap(),
			millisecond: (time_of_day % 1000).to_u16_wrap(),
		}
	}

	## Format the instant as a Plotly date string in UTC, such as
	## `2026-11-11`, `2026-11-11 09:30`, `2026-11-11 09:30:05` or
	## `2026-11-11 09:30:05.250`. Trailing zero fields are omitted, so the
	## shortest exact spelling is used. Plotly shows these times unchanged,
	## without converting them to the viewer's time zone.
	to_str : Time -> Str
	to_str = |time| {
		c = time.to_calendar()
		date = "${pad(c.year.to_u64(), 4)}-${pad(c.month.to_u64(), 2)}-${pad(c.day.to_u64(), 2)}"
		if c.millisecond != 0 {
			"${date} ${pad(c.hour.to_u64(), 2)}:${pad(c.minute.to_u64(), 2)}:${pad(c.second.to_u64(), 2)}.${pad(c.millisecond.to_u64(), 3)}"
		} else if c.second != 0 {
			"${date} ${pad(c.hour.to_u64(), 2)}:${pad(c.minute.to_u64(), 2)}:${pad(c.second.to_u64(), 2)}"
		} else if c.hour != 0 or c.minute != 0 {
			"${date} ${pad(c.hour.to_u64(), 2)}:${pad(c.minute.to_u64(), 2)}"
		} else {
			date
		}
	}
}

millis_per_day : I64
millis_per_day = 86_400_000

## 0001-01-01 00:00 UTC, as days and milliseconds relative to 1970-01-01.
earliest_day : I64
earliest_day = -719_162

earliest_millis : I64
earliest_millis = earliest_day * millis_per_day

## 9999-12-31 23:59:59.999 UTC.
latest_millis : I64
latest_millis = 2_932_896 * millis_per_day + millis_per_day - 1

is_leap_year : U16 -> Bool
is_leap_year = |year| (year % 4 == 0 and year % 100 != 0) or year % 400 == 0

days_in_month : { year : U16, month : U8, day : U8 } -> U8
days_in_month = |{ year, month, day: _ }| match month {
	2 => if (is_leap_year(year)) 29 else 28
	4 | 6 | 9 | 11 => 30
	_ => 31
}

## Days since 1970-01-01 for a valid proleptic Gregorian date in years 1–9999
## (Howard Hinnant's days_from_civil, specialised to nonnegative years).
days_from_civil : { year : U16, month : U8, day : U8 } -> I64
days_from_civil = |{ year, month, day }| {
	shifted_year = year.to_i64() - if (month <= 2) 1 else 0
	era = shifted_year // 400
	year_of_era = shifted_year - era * 400
	month_from_march = if (month > 2) month.to_i64() - 3 else month.to_i64() + 9
	day_of_year = (153 * month_from_march + 2) // 5 + day.to_i64() - 1
	day_of_era = year_of_era * 365 + year_of_era // 4 - year_of_era // 100 + day_of_year
	era * 146_097 + day_of_era - 719_468
}

## The calendar date of a day count since 1970-01-01 in years 1–9999.
civil_from_days : I64 -> { year : U16, month : U8, day : U8 }
civil_from_days = |days| {
	shifted = days + 719_468
	era = shifted // 146_097
	day_of_era = shifted - era * 146_097
	year_of_era = (day_of_era - day_of_era // 1460 + day_of_era // 36_524 - day_of_era // 146_096) // 365
	day_of_year = day_of_era - (365 * year_of_era + year_of_era // 4 - year_of_era // 100)
	month_from_march = (5 * day_of_year + 2) // 153
	day = day_of_year - (153 * month_from_march + 2) // 5 + 1
	month = if (month_from_march < 10) month_from_march + 3 else month_from_march - 9
	year = year_of_era + era * 400 + if (month <= 2) 1 else 0
	{ year: year.to_u16_wrap(), month: month.to_u8_wrap(), day: day.to_u8_wrap() }
}

pad : U64, U64 -> Str
pad = |number, width| {
	digits = number.to_str()
	missing = width - Str.count_utf8_bytes(digits)
	if (Str.count_utf8_bytes(digits) >= width) digits else "${Str.repeat("0", missing)}${digits}"
}

## The Unix epoch is 1970-01-01 at midnight.
expect Time.from_epoch_millis(0)?.to_str() == "1970-01-01"

## Times of day keep only the fields they need.
expect {
	actual = [0, 9 * 3_600_000 + 30 * 60_000, 9 * 3_600_000 + 30 * 60_000 + 5_000, 9 * 3_600_000 + 30 * 60_000 + 5_250, 1].map_try(|offset| Ok(Time.from_epoch_millis(1_762_819_200_000 + offset)?.to_str()))?
	actual == ["2025-11-11", "2025-11-11 09:30", "2025-11-11 09:30:05", "2025-11-11 09:30:05.250", "2025-11-11 00:00:00.001"]
}

## Calendar construction agrees with epoch milliseconds.
expect {
	from_calendar = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 9, minute: 30, second: 5, millisecond: 250 })?
	from_millis = Time.from_epoch_millis(1_762_853_405_250 + 365 * 86_400_000)?
	from_calendar == from_millis and from_calendar.to_epoch_millis() == 1_794_389_405_250
}

## Instants before 1970 use negative milliseconds and floor to their day.
expect {
	actual = [-1, -86_400_000, -86_400_001].map_try(|millis| Ok(Time.from_epoch_millis(millis)?.to_str()))?
	actual == ["1969-12-31 23:59:59.999", "1969-12-31", "1969-12-30 23:59:59.999"]
}

## The supported range's endpoints round-trip and the next instants fail.
expect {
	earliest = Time.from_calendar({ year: 1, month: 1, day: 1 })?
	latest = Time.from_calendar({ year: 9999, month: 12, day: 31, hour: 23, minute: 59, second: 59, millisecond: 999 })?
	actual = [
		earliest.to_str(),
		latest.to_str(),
		Str.inspect(Time.from_epoch_millis(earliest.to_epoch_millis() - 1).is_err()),
		Str.inspect(Time.from_epoch_millis(latest.to_epoch_millis() + 1).is_err()),
		Str.inspect(Time.from_epoch_millis(earliest.to_epoch_millis()) == Ok(earliest)),
		Str.inspect(Time.from_epoch_millis(latest.to_epoch_millis()) == Ok(latest)),
	]
	actual == ["0001-01-01", "9999-12-31 23:59:59.999", "True", "True", "True", "True"]
}

## Leap days exist only in leap years.
expect {
	actual = [
		Time.from_calendar({ year: 2024, month: 2, day: 29 }).is_ok(),
		Time.from_calendar({ year: 2000, month: 2, day: 29 }).is_ok(),
		Time.from_calendar({ year: 1900, month: 2, day: 29 }).is_err(),
		Time.from_calendar({ year: 2026, month: 2, day: 29 }).is_err(),
	]
	actual == [True, True, True, True]
}

## Calendar fields outside their ranges return structured errors.
expect {
	actual = [
		Time.from_calendar({ year: 0, month: 1, day: 1 }) == Err(InvalidDate({ year: 0, month: 1, day: 1 })),
		Time.from_calendar({ year: 10000, month: 1, day: 1 }) == Err(InvalidDate({ year: 10000, month: 1, day: 1 })),
		Time.from_calendar({ year: 2026, month: 13, day: 1 }) == Err(InvalidDate({ year: 2026, month: 13, day: 1 })),
		Time.from_calendar({ year: 2026, month: 4, day: 31 }) == Err(InvalidDate({ year: 2026, month: 4, day: 31 })),
		Time.from_calendar({ year: 2026, month: 4, day: 0 }) == Err(InvalidDate({ year: 2026, month: 4, day: 0 })),
		Time.from_calendar({ year: 2026, month: 4, day: 1, hour: 24 }) == Err(InvalidTimeOfDay({ hour: 24, minute: 0, second: 0, millisecond: 0 })),
		Time.from_calendar({ year: 2026, month: 4, day: 1, millisecond: 1000 }) == Err(InvalidTimeOfDay({ hour: 0, minute: 0, second: 0, millisecond: 1000 })),
	]
	actual == [True, True, True, True, True, True, True]
}

## Every day of four consecutive years round-trips through its calendar date.
expect {
	start = Time.from_calendar({ year: 2023, month: 1, day: 1 })?.to_epoch_millis()
	var $passed = True
	for day in List.from_iter((0.I64..<1461).iter()) {
		time = Time.from_epoch_millis(start + day * 86_400_000 + 3_723_004)?
		$passed = $passed and Time.from_calendar(time.to_calendar()) == Ok(time)
	}
	$passed
}

## Epoch seconds scale to milliseconds and share the supported range.
expect {
	actual = [
		Time.from_epoch_seconds(1_762_819_200) == Time.from_epoch_millis(1_762_819_200_000),
		Time.from_epoch_seconds(-62_135_596_801) == Err(TimeOutOfRange(-62_135_596_801)),
		Time.from_epoch_seconds(I64.highest) == Err(TimeOutOfRange(I64.highest)),
	]
	actual == [True, True, True]
}
