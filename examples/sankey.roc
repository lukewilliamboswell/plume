# Connect named flow nodes with weighted links.
# Run from the repository root: roc examples/sankey.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Chart
import plume.Layout
import plume.Title
import plume.Sankey
import plume.Font
import plume.Color

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	pink = Color.hex("#ff00ff")?
	purple = Color.rgba({ red: 124, green: 56, blue: 245, alpha: 150 })
	# Stable IDs identify nodes independently from the labels shown to readers.
	flows = Sankey.new({
		nodes: [
			{ id: "a", label: "Node A", color: pink, hover: Text("<em>Node A</em><br>Out: $10") },
			{ id: "b", label: "Node B", color: pink },
			{ id: "c", label: "Node C", color: purple },
			{ id: "d", label: "Node D", color: purple },
			{ id: "e", label: "Node E", color: pink },
		],
		links: [
			{ source: "a", target: "c", value: 8 },
			{ source: "b", target: "d", value: 4 },
			{ source: "a", target: "d", value: 2 },
			{ source: "c", target: "e", value: 8 },
			{ source: "d", target: "e", value: 6 },
		],
		orientation: Horizontal,
	})?
	chart = Chart.new({
		traces: [Sankey(flows)],
		layout: Layout.new({
			global_font: Font.new({ family: "sans-serif", style: Italic })?,
			title: Title.new({ text: "Example Sankey Chart" }),
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}
