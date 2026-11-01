# Plot house size against price using individual markers.
# Run from the repository root: roc examples/scatter.roc > chart.html
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
import plume.Axis
import plume.Marker
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	up = Marker.new({ size: 12, color: Color.named("Green")?, symbol: TriangleUp })?
	down = Marker.new({ size: 12, color: Color.named("Red")?, symbol: TriangleDown })?
	prices = Scatter.new({
		data: [
			{ x: 50, y: 7, marker: up },
			{ x: 60, y: 8, marker: up },
			{ x: 70, y: 8, marker: up },
			{ x: 80, y: 9, marker: up },
			{ x: 90, y: 9, marker: up },
			{ x: 100, y: 9, marker: up },
			{ x: 110, y: 10, marker: down },
			{ x: 120, y: 11, marker: down },
			{ x: 130, y: 14, marker: down },
			{ x: 140, y: 14, marker: down },
			{ x: 150, y: 15, marker: down },
		],
		mode: Markers,
	})
	chart = Chart.new({
		traces: [Scatter(prices)],
		layout: Layout.new({
			title: Title.new({ text: "House Price vs Size" }),
			x_axis: Axis.new({ title: Title.new({ text: "Square Meters" }), range: Bounds({ min: 40, max: 160 }) })?,
			y_axis: Axis.new({ title: Title.new({ text: "Price in Millions ($USD)" }), range: Bounds({ min: 5, max: 16 }) })?,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
