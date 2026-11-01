# Vary marker shapes, colors and areas across two series.
# Run from the repository root: roc examples/bubble.roc > chart.html
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
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	shapes = Scatter.new({
		data: [
			{ x: 1, y: 15, marker: Marker.new({ size: 20, symbol: Circle })? },
			{ x: 2, y: 30, marker: Marker.new({ size: 20, symbol: Square })? },
			{ x: 3, y: 45, marker: Marker.new({ size: 20, symbol: Diamond })? },
			{ x: 4, y: 60, marker: Marker.new({ size: 20, symbol: Cross })? },
		],
		name: "Shapes",
		mode: Markers,
	})
	colors = Scatter.new({
		data: [
			{ x: 1, y: 10, marker: Marker.new({ size: 20, color: Color.named("Red")? })? },
			{ x: 2, y: 20, marker: Marker.new({ size: 30, color: Color.named("Green")? })? },
			{ x: 3, y: 30, marker: Marker.new({ size: 40, color: Color.named("Blue")? })? },
			{ x: 4, y: 40, marker: Marker.new({ size: 50, color: Color.named("Orange")? })? },
		],
		name: "Colors",
		mode: Markers,
	})
	chart = Chart.new({
		traces: [Scatter(shapes), Scatter(colors)],
		layout: Layout.new({ title: Title.new({ text: "Plotting Bubbles" }), legend: Shown }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
