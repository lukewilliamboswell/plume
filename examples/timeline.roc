# Show a release's stages as bars on a timeline, starting each at its own time.
# Run from the repository root: roc examples/timeline.roc > chart.html
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
import plume.Line
import plume.Shape
import plume.Size
import plume.Time
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	green = Color.rgb({ red: 44, green: 160, blue: 44 })
	red = Color.rgb({ red: 214, green: 39, blue: 40 })
	stages = [
		{ name: "Build", start: { hour: 9, minute: 0 }, minutes: 25.I64, color: green },
		{ name: "Test", start: { hour: 9, minute: 25 }, minutes: 40, color: green },
		{ name: "Canary", start: { hour: 10, minute: 5 }, minutes: 30, color: red },
		{ name: "Rollback", start: { hour: 10, minute: 35 }, minutes: 10, color: green },
		{ name: "Deploy", start: { hour: 11, minute: 0 }, minutes: 45, color: green },
	]
	# A bar's base is its start time; its length is a duration in milliseconds.
	data = stages.map_try(
		|stage| {
			start = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: stage.start.hour, minute: stage.start.minute })?
			length = Coordinate.from_number((stage.minutes * 60_000).to_f64())?
			Ok({ x: length, y: Coordinate.from_text(stage.name), color: stage.color, base: At(Coordinate.from_time(start)) })
		},
	)?
	stages_bar = Bar.new({ data, orientation: Horizontal, width: 0.6, name: "Stages" })?
	alert = Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 10, minute: 20 })?
	window = {
		start: Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 8, minute: 45 })?,
		end: Time.from_calendar({ year: 2026, month: 11, day: 11, hour: 12 })?,
	}
	chart = Chart.new({
		traces: [Bar(stages_bar)],
		layout: Layout.new({
			title: Title.new({ text: "Release 4.2 timeline" }),
			size: Size.new({ height: Pixels(360), margin: Pixels({ left: 90, right: 30, top: 70, bottom: 50 }) })?,
			x_axis: Axis.new({ type: Date, range: TimeBounds(window), tick_format: Pattern("%H:%M") })?,
			y_axis: Axis.new({ type: Category, range: Reversed, grid: Hidden })?,
			shapes: [
				Shape.new({
					placement: VerticalLine(Coordinate.from_time(alert)),
					line: Line.new({ color: red, width: 2, dash: Dot })?,
					label: "Error alert",
				}),
			],
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
