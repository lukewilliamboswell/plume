# Turn a JSON budget into a flow diagram. Each link supplies a monthly amount.
# Run: roc examples/budget.roc examples/baseline.json > budget.html
# Or: cat examples/baseline.json | roc examples/budget.roc - > budget.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Path
import cli.Stdin
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Color
import plume.Sankey

Scenario : { scenario : Str, links : List({ source : Str, target : Str, monthly : F64 }) }

main! : List(OsStr) => Try({}, _)
main! = |args| {
	# Decode once at the input boundary. The package only sees typed chart data.
	source = match args {
		["-"] => Str.from_utf8(Stdin.read_to_end!()?)?
		[path] => Path.from_os_str(path).read_utf8!()?
		_ => return Err(Usage("budget <scenario.json|->"))
	}
	scenario : Scenario
	scenario = Json.parse(source)?

	# Preserve first-appearance order so the graph and its HTML stay reproducible.
	labels = scenario.links.fold([], |known, link|
		[link.source, link.target].fold(known, |current, label|
			if (current.contains(label)) current else current.append(label)))

	nodes = labels.map(
		|label| {
			totals = scenario.links.fold(
				{ income: 0.F64, outgoing: 0.F64 },
				|total, link| {
					income: total.income + if (link.target == label) link.monthly else 0,
					outgoing: total.outgoing + if (link.source == label) link.monthly else 0,
				},
			)
			color = match label {
				"Income" => Color.rgb({ red: 240, green: 130, blue: 190 })
				"Bills" => Color.rgba({ red: 124, green: 56, blue: 245, alpha: 150 })
				_ => Color.rgb({ red: 0, green: 160, blue: 210 })
			}
			{
				id: label,
				label,
				color,
				hover: Text("In: $${totals.income.to_str()}<br>Out: $${totals.outgoing.to_str()}"),
			}
		},
	)
	flows = Sankey.new({
		nodes,
		links: scenario.links.map(
			|link| {
				source: link.source,
				target: link.target,
				value: link.monthly,
				hover: Text("${link.source} -> ${link.target}: $${link.monthly.to_str()}"),
			},
		),
	})?
	chart = Chart.new({
		traces: [Sankey(flows)],
		layout: Layout.new({ title: Title.new({ text: "Budget Scenario: ${scenario.scenario}" }) }),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
