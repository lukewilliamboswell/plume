# Compare programmer counts with vertical bars.
# Run from the repository root: roc examples/bar-chart.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
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
			{ x: "Italy", y: 55, color },
			{ x: "France", y: 49, color },
			{ x: "Spain", y: 44, color },
			{ x: "USA", y: 24, color },
			{ x: "Australia", y: 15, color },
		],
		orientation: Vertical,
	})?
	chart = Chart.new({
		traces: [Bar(bars)],
		layout: Layout.new({ title: Title.new({ text: "Roc Programmers by Country" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
