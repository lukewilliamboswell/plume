# Sample sin(x) at evenly spaced coordinates.
# Run from the repository root: roc examples/equation-sine.roc > chart.html
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

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	# Generate integers first so the step count is exact, then scale to F64.
	points = List.from_iter(
		(0.U64..<50).iter().map(
			|step| {
				x = step.to_f64() / 5
				{ x, y: F64.sin(x) }
			},
		),
	)
	curve = Scatter.new({ data: points, mode: Lines })?
	chart = Chart.new({
		traces: [Scatter(curve)],
		layout: Layout.new({ title: Title.new({ text: "y = Math.sin(x)" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
