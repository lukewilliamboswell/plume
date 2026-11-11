# Stack log entries per hour by level, with a time axis.
# Run from the repository root: roc examples/stacked-bars.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Axis
import plume.Bar
import plume.Chart
import plume.Color
import plume.Coordinate
import plume.Layout
import plume.Size
import plume.Time
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	midnight = Time.from_calendar({ year: 2026, month: 11, day: 11 })?
	hours = List.from_iter((0.I64..<24).iter())
	levels = [
		{ level: Info, name: "info", color: Color.rgb({ red: 76, green: 120, blue: 168 }) },
		{ level: Warn, name: "warn", color: Color.rgb({ red: 245, green: 133, blue: 24 }) },
		{ level: Error, name: "error", color: Color.rgb({ red: 214, green: 39, blue: 40 }) },
	]
	traces = levels.map_try(
		|level| {
			data = hours.map_try(
				|hour| {
					x = Coordinate.from_time(Time.from_epoch_millis(midnight.to_epoch_millis() + hour * 3_600_000)?)
					y = Coordinate.from_number(hourly_count({ level: level.level, hour }))?
					Ok({ x, y, color: level.color })
				},
			)?
			bars = Bar.new({ data, name: level.name, width: 3_000_000 })?
			Ok(Bar(bars))
		},
	)?
	chart = Chart.new({
		traces,
		layout: Layout.new({
			title: Title.new({ text: "Log entries per hour" }),
			bar_mode: Stack,
			size: Size.new({ height: Pixels(420) })?,
			x_axis: Axis.new({ type: Date, tick_format: Pattern("%H:%M") })?,
			y_axis: Axis.new({ title: Title.new({ text: "Entries" }), range: FromZero })?,
			legend: Shown,
			legend_position: Below,
			hover_mode: X,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}

## Reproducible hourly counts for each level; warnings and errors burst
## around midday.
hourly_count : { level : [Info, Warn, Error], hour : I64 } -> F64
hourly_count = |{ level, hour }| {
	count : I64
	count = match level {
		Info => 400 + 30 * (hour % 7)
		Warn => 40 + 9 * (hour % 5) + if (hour >= 11 and hour <= 13) 160 else 0
		Error => 5 + hour % 3 + if (hour == 12) 210 else 0
	}
	count.to_f64()
}
