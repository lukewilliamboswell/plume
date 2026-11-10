# Draw two thousand points with the GPU, using the WebGL scatter renderer.
# Run from the repository root: roc examples/webgl.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Color
import plume.Coordinate
import plume.Layout
import plume.Marker
import plume.Scatter
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	# A spiral of points. Every point shares one marker, so the output
	# carries the marker once and two thousand coordinate pairs.
	marker = Marker.new({ size: 4, color: Color.rgba({ red: 31, green: 119, blue: 180, alpha: 128 }) })?
	points = List.from_iter((0.U64..<2_000).iter()).map_try(
		|index| {
			angle = index.to_f64() / 40
			radius = 1 + index.to_f64() / 200
			x = Coordinate.from_number(radius * F64.cos(angle))?
			y = Coordinate.from_number(radius * F64.sin(angle))?
			Ok({ x, y, marker })
		},
	)?
	spiral = Scatter.new({ data: points, mode: Markers, renderer: WebGl, name: "Spiral" })
	chart = Chart.new({
		traces: [Scatter(spiral)],
		layout: Layout.new({ title: Title.new({ text: "2,000 points with WebGL" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
