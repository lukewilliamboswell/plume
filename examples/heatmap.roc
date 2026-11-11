# Color a grid of error counts by service and hour.
# Run from the repository root: roc examples/heatmap.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Coordinate
import plume.Heatmap
import plume.Layout
import plume.Size
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	hours = List.from_iter((0.U64..<24).iter())
	services = ["api", "web", "database", "queue", "notifications"]
	# Errors rise at the database around midday and spill into its callers.
	rows = services.map_with_index(
		|service, index| {
			values = hours.map(
				|hour| {
					background = ((hour * 7 + index * 3) % 5).to_f64()
					burst = if (hour >= 11 and hour <= 13) [30.F64, 12, 55, 8, 2].get(index) ?? 0 else 0
					background + burst
				},
			)
			{ y: Coordinate.from_text(service), values }
		},
	)
	x = hours.map(|hour| Coordinate.from_text(if (hour < 10) "0${hour.to_str()}:00" else "${hour.to_str()}:00"))
	errors = Heatmap.new({ x, rows, name: "Errors", color_scale: YlOrRd, direction: Reversed, cell_gap: 1 })?
	chart = Chart.new({
		traces: [Heatmap(errors)],
		layout: Layout.new({
			title: Title.new({ text: "Errors by service and hour" }),
			size: Size.new({ height: Pixels(360) })?,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
