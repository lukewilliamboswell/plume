app [target] {
	fuzz: platform "https://github.com/lukewilliamboswell/roc-fuzz/releases/download/0.5.0/9WT86CuwM7ZJBSs8iTd1jLyrUFTTiGp5hcJE63TwswGE.tar.zst",
	plume: "../package/main.roc",
}

import fuzz.Fuzz
import plume.Chart
import plume.Layout
import plume.Title

## Arbitrary text must survive JSON encoding and remain inert in the HTML
## script element. Allocation reports measure only chart.to_html, with the
## chart constructed before the measurement and decoding performed after it.
test! : Str => Fuzz.Outcome
test! = |text| {
	chart = Chart.new({
		layout: Layout.new({
			title: Title.new({
				text: text,
			}),
		}),
	})
	measured = Fuzz.measure!("chart-html", || chart.to_html())
	if !is_round_trip({ text, html: measured.value }) {
		crash "serialization.test!: chart text did not survive safe HTML embedding"
	}
	Fuzz.keep
}

is_round_trip : { text : Str, html : Str } -> Bool
is_round_trip = |{ text, html }| {
	payload = match html.split_on("id=\"chartData\">") {
		[_, tail] => match tail.split_on("</script>") {
			[json, ..] => json
			_ => crash "serialization.is_round_trip: document has no closing script element"
		}
		_ => crash "serialization.is_round_trip: document has no unique chartData element"
	}
	decoded : Try({ data : List({}), layout : { title : { text : Str } } }, _)
	decoded = Json.parse(payload)
	match decoded {
		Ok(figure) => figure.data.is_empty() and figure.layout.title.text == text and !payload.contains("<")
		Err(_) => False
	}
}

target = Fuzz.target_with!({
	name: "plume-serialization",
	examples: [
		Fuzz.example({ name: "empty", revision: "1", make: || "" }),
		Fuzz.example({ name: "controls", revision: "1", make: || "\u(0)\n\t\r\"\\" }),
		Fuzz.example({ name: "script", revision: "1", make: || "</ScRiPt><script>alert(1)</script>{{CHART_TITLE}}" }),
		Fuzz.example({ name: "unicode", revision: "1", make: || "雪🌻e\u(301)\u(2028)\u(2029)" }),
	],
	generator: Fuzz.str,
	test!,
	show: Str.inspect,
})

## Script terminators and HTML-looking text stay literal data.
expect {
	text = "</ScRiPt><script>alert(1)</script>\"\\\n\t\u(0)雪{{CHART_TITLE}}"
	chart = Chart.new({
		layout: Layout.new({
			title: Title.new({
				text: text,
			}),
		}),
	})
	is_round_trip({ text, html: chart.to_html() })
}

## Empty chart titles round-trip without introducing script markup.
expect {
	chart = Chart.new({ layout: Layout.new({ title: Title.new({ text: "" }) }) })
	is_round_trip({ text: "", html: chart.to_html() })
}
