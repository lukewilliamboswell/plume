# Watch request latency through an incident on a live-updating time axis.
# Run from the repository root: roc examples/latency.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Axis
import plume.Chart
import plume.Color
import plume.Coordinate
import plume.Layout
import plume.Line
import plume.Scatter
import plume.Shape
import plume.Size
import plume.Time
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	start = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 11 })?
	at_minute = |minute| Time.from_epoch_millis(start.to_epoch_millis() + minute * 60_000)
	# One sample a minute. The collector was down for minutes 30 to 32, so
	# those samples are missing and the next one starts a new line segment.
	samples = List.from_iter((0.I64..<90).iter()).drop_if(|minute| minute >= 30 and minute <= 32)
	incident = |minute| if (minute >= 50 and minute < 62) 180.F64 else 0
	median = samples.map_try(
		|minute| {
			x = Coordinate.from_time(at_minute(minute)?)
			y = Coordinate.from_number(40 + 8 * F64.sin(minute.to_f64() / 7) + incident(minute) / 4)?
			Ok({ x, y, from_previous: if (minute == 33) Gap else Connected })
		},
	)?
	tail = samples.map_try(
		|minute| {
			x = Coordinate.from_time(at_minute(minute)?)
			y = Coordinate.from_number(120 + 25 * F64.sin(minute.to_f64() / 5) + incident(minute))?
			Ok({ x, y, from_previous: if (minute == 33) Gap else Connected })
		},
	)?
	blue = Color.rgb({ red: 31, green: 119, blue: 180 })
	red = Color.rgb({ red: 214, green: 39, blue: 40 })
	chart = Chart.new({
		traces: [
			Scatter(Scatter.new({ data: median, name: "p50", line: Line.new({ color: blue, width: 1.5 })?, fill: ToZeroY, fill_color: Custom(Color.rgba({ red: 31, green: 119, blue: 180, alpha: 64 })) })),
			Scatter(Scatter.new({ data: tail, name: "p95", line: Line.new({ color: red, width: 2, shape: StepAfter })? })),
		],
		layout: Layout.new({
			title: Title.new({ text: "API latency" }),
			size: Size.new({ height: Pixels(420), margin: Pixels({ left: 64, right: 24, top: 80, bottom: 48 }) })?,
			x_axis: Axis.new({ type: Date, tick_format: Pattern("%H:%M") })?,
			y_axis: Axis.new({ range: FromZero, tick_suffix: " ms" })?,
			legend: Shown,
			legend_position: Above,
			hover_mode: XUnified,
			# Keep the viewer's zoom when the page redraws with new samples.
			ui_revision: Preserve("api-latency"),
			shapes: [
				Shape.new({
					placement: VerticalBand({ start: Coordinate.from_time(at_minute(50)?), end: Coordinate.from_time(at_minute(62)?) }),
					fill: Color.rgba({ red: 214, green: 39, blue: 40, alpha: 31 }),
					label: "Incident",
					layer: Below,
				}),
				Shape.new({
					placement: HorizontalLine(250),
					line: Line.new({ color: Color.rgb({ red: 120, green: 120, blue: 120 }), width: 1, dash: Dash })?,
					label: "SLO 250 ms",
				}),
			],
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
