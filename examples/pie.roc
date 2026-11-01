# Show each country’s share in a pie.
# Run from the repository root: roc examples/pie.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Pie

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	# Values are nonnegative amounts; Plotly calculates their proportions.
	distribution = Pie.new({
		data: [
			{ label: "Italy", value: 55 },
			{ label: "France", value: 49 },
			{ label: "Spain", value: 44 },
			{ label: "USA", value: 24 },
			{ label: "Australia", value: 15 },
		],
		hole: 0,
	})?
	chart = Chart.new({
		traces: [Pie(distribution)],
		layout: Layout.new({ title: Title.new({ text: "Roc Programmers by Country" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
