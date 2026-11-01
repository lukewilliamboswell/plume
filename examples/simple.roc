# Combine a styled line and markers for fruit sales.
# Run from the repository root: roc examples/simple.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Scatter
import plume.Marker
import plume.Line
import plume.Font
import plume.Axis
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	title_font = Font.new({ family: "sans-serif", size: 24, style: Italic })?
	axis_font = Font.new({ family: "monospace", size: 18 })?
	purple = Color.rgb({ red: 124, green: 56, blue: 245 })
	marker = Marker.new({ size: 15, symbol: Diamond, color: purple })?
	sales = Scatter.new({
		data: [
			{ x: "Apples", y: 2.1, marker },
			{ x: "Oranges", y: 3, marker },
			{ x: "Bananas", y: 4, marker },
		],
		mode: LinesMarkers,
		line: Line.new({ width: 2, color: purple, dash: Dash })?,
	})
	chart = Chart.new({
		traces: [Scatter(sales)],
		layout: Layout.new({
			title: Title.new({ text: "Fruit Sales", font: title_font }),
			y_axis: Axis.new({ title: Title.new({ text: "Qty", font: axis_font }) })?,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
