import InternalJson
import Color
import Coordinate

## A validated Plotly histogram, which counts raw values into bins in the
## browser. For values already counted elsewhere, draw the counts with
## [Bar] instead, which sends one number per bin rather than every value.
Histogram :: InternalJson.{

	## Compare the encoded trace, including input order and all style settings.
	is_eq : _

	## Choose the bins.
	## `Auto` lets Plotly choose. `AtMost(count)` asks for at most `count`
	## bins, with Plotly choosing round boundaries. `Fixed({ start, end,
	## size })` places bins of `size` from `start` to `end` on a numeric axis.
	Bins : [Auto, AtMost(U16), Fixed({ start : F64, end : F64, size : F64 })]

	## Choose what a bar's length measures.
	## `Counts` is the number of values in the bin, `Percent` and
	## `Probability` its share of all values, `Density` the count divided
	## by the bin's width, and `ProbabilityDensity` the share divided by it.
	Normalization : [Counts, Percent, Probability, Density, ProbabilityDensity]

	## Configure a histogram.
	## `values` are the raw observations, which may be empty; text values
	## are counted as categories. `orientation` defaults to `Vertical`, with
	## bins along x; `Horizontal` places them along y. `bins` defaults to
	## `Auto`, `normalization` to `Counts`, and `color` to Plotly blue.
	## `name` is the legend/hover label, and may be empty.
	Props := {
		values : List(Coordinate),
		name : Str ?? "",
		orientation : [Vertical, Horizontal] ?? Vertical,
		bins : Bins ?? Auto,
		normalization : Normalization ?? Counts,
		color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }),
	}

	## Validate the bins and construct a histogram trace.
	## Returns `InvalidBinCount(count)` for `AtMost(0)`, and
	## `InvalidBins({ start, end, size })` for fixed bins whose numbers are
	## nonfinite, whose size is not positive or whose end is not after the
	## start.
	##
	## ```roc
	## expect {
	##     spread = Histogram.new({ values: [1, 2, 2, 3], bins: AtMost(10) })?
	##     spread.to_json().contains("nbinsx")
	## }
	## ```
	new : Props -> Try(Histogram, [InvalidBinCount(U16), InvalidBins({ start : F64, end : F64, size : F64 }), Infinity, NaN, NegativeInfinity])
	new = |props| {
		axis = match props.orientation {
			Vertical => "x"
			Horizontal => "y"
		}
		bin_fields = match props.bins {
			Auto => []
			AtMost(count) =>
				if count == 0 {
					return Err(InvalidBinCount(count))
				} else {
					[{ name: "nbins${axis}", value: InternalJson.encode(count)? }]
				}
			Fixed(bins) =>
				if [bins.start, bins.end, bins.size].all(F64.is_finite) and bins.size > 0 and bins.end > bins.start {
					[
						{
							name: "${axis}bins",
							value: InternalJson.object([
								{ name: "start", value: InternalJson.encode(bins.start)? },
								{ name: "end", value: InternalJson.encode(bins.end)? },
								{ name: "size", value: InternalJson.encode(bins.size)? },
							]),
						},
					]
				} else {
					return Err(InvalidBins(bins))
				}
		}
		normalization_fields = match props.normalization {
			Counts => []
			Percent => [{ name: "histnorm", value: InternalJson.string("percent") }]
			Probability => [{ name: "histnorm", value: InternalJson.string("probability") }]
			Density => [{ name: "histnorm", value: InternalJson.string("density") }]
			ProbabilityDensity => [{ name: "histnorm", value: InternalJson.string("probability density") }]
		}
		Ok(
			Histogram.(
				InternalJson.object(
					[
						{ name: "type", value: InternalJson.string("histogram") },
						{ name: axis, value: InternalJson.array(props.values.map(Coordinate.to_json_value)) },
						{ name: "marker", value: InternalJson.object([{ name: "color", value: props.color.to_json_value() }]) },
						{ name: "name", value: InternalJson.string(props.name) },
					]
						.concat(bin_fields)
						.concat(normalization_fields),
				),
			),
		)
	}

	## Internal composition hook used by Plume's renderers.
	## Applications normally use [Histogram.to_json] for complete JSON text;
	## this returns the package's safe internal value without accepting raw JSON.
	to_json_value : Histogram -> InternalJson
	to_json_value = |Histogram.(json)| json

	## Serialize the trace as JSON.
	to_json : Histogram -> Str
	to_json = |histogram| histogram.to_json_value().to_json()
}

## A default histogram sends its values and a single color.
expect {
	spread = Histogram.new({ values: [1, 2.5, "c"] })?
	spread.to_json() ==
		\\{"type":"histogram","x":[1,2.5,"c"],"marker":{"color":"rgb(31, 119, 180)"},"name":""}
}

## Horizontal histograms bin along y with fixed bins and a normalization.
expect {
	spread = Histogram.new({ values: [1], orientation: Horizontal, bins: Fixed({ start: 0, end: 10, size: 2 }), normalization: ProbabilityDensity })?
	decoded : { y : List(F64), ybins : { start : F64, end : F64, size : F64 }, histnorm : Str }
	decoded = Json.parse(spread.to_json())?
	decoded == { y: [1], ybins: { start: 0, end: 10, size: 2 }, histnorm: "probability density" }
}

## Every normalization has its Plotly spelling, and counts are the default.
expect {
	actual = [Counts, Percent, Probability, Density, ProbabilityDensity].map_try(
		|normalization| {
			json = Histogram.new({ values: [], normalization: normalization })?.to_json()
			Ok(if (json.contains("histnorm")) json.split_on("\"histnorm\":").get(1)? else "none")
		},
	)?
	actual == ["none", "\"percent\"}", "\"probability\"}", "\"density\"}", "\"probability density\"}"]
}

## A bin limit of zero is rejected and other limits become nbins.
expect {
	actual = [
		Histogram.new({ values: [], bins: AtMost(0) }).map_ok(|_| {}) == Err(InvalidBinCount(0)),
		Histogram.new({ values: [], bins: AtMost(25) }).map_ok(|spread| spread.to_json().contains("\"nbinsx\":25")) == Ok(True),
	]
	actual == [True, True]
}

## Fixed bins need a positive size, an end after the start and finite numbers.
expect {
	ordered = [{ start: 0, end: 10, size: 0 }, { start: 0, end: 10, size: -1 }, { start: 5, end: 5, size: 1 }].map(|bins| Histogram.new({ values: [], bins: Fixed(bins) }).map_ok(|_| {}) == Err(InvalidBins(bins)))
	nonfinite = [{ start: F64.nan, end: 10, size: 1 }, { start: 0, end: F64.infinity, size: 1 }].map(|bins| Histogram.new({ values: [], bins: Fixed(bins) }).is_err())
	ordered == [True, True, True] and nonfinite == [True, True]
}
