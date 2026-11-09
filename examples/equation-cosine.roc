# Sample cos(x) at evenly spaced coordinates.
# Run from the repository root: roc examples/equation-cosine.roc > chart.html
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
import plume.Coordinate

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	# Generate an exact step count, then validate computed numbers at the boundary.
	points = List.from_iter((0.U64..<50).iter()).map_try(
		|step| {
			number = step.to_f64() / 5
			x = Coordinate.from_number(number)?
			y = Coordinate.from_number(F64.cos(number))?
			Ok({ x, y })
		},
	)?
	curve = Scatter.new({ data: points, mode: Lines })
	chart = Chart.new({
		traces: [Scatter(curve)],
		layout: Layout.new({ title: Title.new({ text: "y = Math.cos(x)" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
