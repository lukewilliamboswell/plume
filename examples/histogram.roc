# Compare two response-time distributions with overlaid histograms.
# Run from the repository root: roc examples/histogram.roc > chart.html
app [main!] {
	cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
	plume: "../package/main.roc",
}

import cli.OsStr
import cli.Stdout
import plume.Axis
import plume.Chart
import plume.Color
import plume.Coordinate
import plume.Histogram
import plume.Layout
import plume.Title

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	before = samples({ seed: 7, centre: 120, spread: 30 })?
	after = samples({ seed: 11, centre: 85, spread: 20 })?
	bins = Fixed({ start: 0, end: 240, size: 10 })
	chart = Chart.new({
		traces: [
			Histogram(Histogram.new({ values: before, name: "Before", bins, normalization: Percent, color: Color.rgba({ red: 214, green: 39, blue: 40, alpha: 140 }) })?),
			Histogram(Histogram.new({ values: after, name: "After", bins, normalization: Percent, color: Color.rgba({ red: 31, green: 119, blue: 180, alpha: 140 }) })?),
		],
		layout: Layout.new({
			title: Title.new({ text: "Response times before and after caching" }),
			bar_mode: Overlay,
			x_axis: Axis.new({ title: Title.new({ text: "Response time" }), tick_suffix: " ms" })?,
			y_axis: Axis.new({ title: Title.new({ text: "Requests" }), tick_suffix: "%" })?,
			legend: Shown,
			legend_position: InsideTopRight,
		}),
	})
	Stdout.line!(chart.to_html())?
	Ok({})
}

## Four hundred reproducible, roughly bell-shaped samples: each is the mean
## of four draws from a linear congruential generator, scaled and shifted.
samples : { seed : U64, centre : F64, spread : F64 } -> Try(List(Coordinate), [NonFiniteCoordinate(F64)])
samples = |{ seed, centre, spread }| {
	var $state = seed
	var $values = []
	for _sample in List.from_iter((0.U64..<400).iter()) {
		var $sum = 0.F64
		for _draw in List.from_iter((0.U64..<4).iter()) {
			$state = $state.times_wrap(6_364_136_223_846_793_005).plus_wrap(1_442_695_040_888_963_407)
			$sum = $sum + ($state // 2_048).to_f64() / 9_007_199_254_740_992
		}
		$values = $values.append(Coordinate.from_number(centre + spread * ($sum - 2) * 1.7)?)
	}
	Ok($values)
}
