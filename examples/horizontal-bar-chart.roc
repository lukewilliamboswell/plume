# Compare programmer counts with horizontal bars.
# Run from the repository root: roc examples/horizontal-bar-chart.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Bar
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	# The color is shared by every observation in this series.
	color = Color.rgba({ red: 40, green: 90, blue: 210, alpha: 210 })
	bars = Bar.new({
		data: [
			{ x: 55.F64, y: "Italy", color },
			{ x: 49.F64, y: "France", color },
			{ x: 44.F64, y: "Spain", color },
			{ x: 24.F64, y: "USA", color },
			{ x: 15.F64, y: "Australia", color },
		],
		orientation: Horizontal,
	})?
	chart = Chart.new({
		traces: [Bar(bars)],
		layout: Layout.new({ title: Title.new({ text: "Roc Programmers by Country" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
