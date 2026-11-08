# Mix different trace types in one chart with a shared layout.
# Run from the repository root: roc examples/hello.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Scatter
import plume.Bar
import plume.Marker
import plume.Line
import plume.Font
import plume.Axis
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	purple = Color.rgba({ red: 124, green: 56, blue: 245, alpha: 150 })
	marker = Marker.new({ size: 15, color: purple, symbol: Diamond })?
	fruit = Scatter.new({
		data: [
			{ x: "Apples", y: 2.1, marker },
			{ x: "Oranges", y: 3, marker },
			{ x: "Bananas", y: 4, marker },
		],
		name: "Fruit",
		mode: LinesMarkers,
		line: Line.new({ width: 2, color: Color.named("FireBrick")?, dash: Dash })?,
	})
	snacks = Bar.new({
		data: [
			{ x: "Tuna", y: 0.3, color: purple },
			{ x: "Muesli Bar", y: 2.5, color: purple },
			{ x: "Carrot", y: 5.5, color: purple },
		],
		name: "Snacks",
		width: 0.9,
	})?
	chart = Chart.new({
		traces: [Scatter(fruit), Bar(snacks)],
		layout: Layout.new({
			legend: Shown,
			global_font: Font.new({ family: "sans-serif", style: Italic })?,
			title: Title.new({ text: "Snacks and Fruit" }),
			y_axis: Axis.new({ title: Title.new({ text: "Quantity" }) })?,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
