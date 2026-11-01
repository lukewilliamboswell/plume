import Color
import InternalJson

## Per-point size, color and validated Plotly marker symbol.
Marker :: { size : F64, color : Color, symbol : Symbol }.{

	## Plotly's finite set of named marker symbols. Use tags in props,
	## and [Marker.Symbol.from_str] when reading a name from external data.
	Symbol := [
		Circle,
		CircleOpen,
		CircleDot,
		CircleOpenDot,
		Square,
		SquareOpen,
		SquareDot,
		SquareOpenDot,
		Diamond,
		DiamondOpen,
		DiamondDot,
		DiamondOpenDot,
		Cross,
		CrossOpen,
		CrossDot,
		CrossOpenDot,
		X,
		XOpen,
		XDot,
		XOpenDot,
		TriangleUp,
		TriangleUpOpen,
		TriangleUpDot,
		TriangleUpOpenDot,
		TriangleDown,
		TriangleDownOpen,
		TriangleDownDot,
		TriangleDownOpenDot,
		TriangleLeft,
		TriangleLeftOpen,
		TriangleLeftDot,
		TriangleLeftOpenDot,
		TriangleRight,
		TriangleRightOpen,
		TriangleRightDot,
		TriangleRightOpenDot,
		TriangleNe,
		TriangleNeOpen,
		TriangleNeDot,
		TriangleNeOpenDot,
		TriangleSe,
		TriangleSeOpen,
		TriangleSeDot,
		TriangleSeOpenDot,
		TriangleSw,
		TriangleSwOpen,
		TriangleSwDot,
		TriangleSwOpenDot,
		TriangleNw,
		TriangleNwOpen,
		TriangleNwDot,
		TriangleNwOpenDot,
		Pentagon,
		PentagonOpen,
		PentagonDot,
		PentagonOpenDot,
		Hexagon,
		HexagonOpen,
		HexagonDot,
		HexagonOpenDot,
		Hexagon2,
		Hexagon2Open,
		Hexagon2Dot,
		Hexagon2OpenDot,
		Octagon,
		OctagonOpen,
		OctagonDot,
		OctagonOpenDot,
		Star,
		StarOpen,
		StarDot,
		StarOpenDot,
		Hexagram,
		HexagramOpen,
		HexagramDot,
		HexagramOpenDot,
		StarTriangleUp,
		StarTriangleUpOpen,
		StarTriangleUpDot,
		StarTriangleUpOpenDot,
		StarTriangleDown,
		StarTriangleDownOpen,
		StarTriangleDownDot,
		StarTriangleDownOpenDot,
		StarSquare,
		StarSquareOpen,
		StarSquareDot,
		StarSquareOpenDot,
		StarDiamond,
		StarDiamondOpen,
		StarDiamondDot,
		StarDiamondOpenDot,
		DiamondTall,
		DiamondTallOpen,
		DiamondTallDot,
		DiamondTallOpenDot,
		DiamondWide,
		DiamondWideOpen,
		DiamondWideDot,
		DiamondWideOpenDot,
		Hourglass,
		HourglassOpen,
		Bowtie,
		BowtieOpen,
		CircleCross,
		CircleCrossOpen,
		CircleX,
		CircleXOpen,
		SquareCross,
		SquareCrossOpen,
		SquareX,
		SquareXOpen,
		DiamondCross,
		DiamondCrossOpen,
		DiamondX,
		DiamondXOpen,
		CrossThin,
		CrossThinOpen,
		XThin,
		XThinOpen,
		Asterisk,
		AsteriskOpen,
		Hash,
		HashOpen,
		HashDot,
		HashOpenDot,
		YUp,
		YUpOpen,
		YDown,
		YDownOpen,
		YLeft,
		YLeftOpen,
		YRight,
		YRightOpen,
		LineEw,
		LineEwOpen,
		LineNs,
		LineNsOpen,
		LineNe,
		LineNeOpen,
		LineNw,
		LineNwOpen,
		ArrowUp,
		ArrowUpOpen,
		ArrowDown,
		ArrowDownOpen,
		ArrowLeft,
		ArrowLeftOpen,
		ArrowRight,
		ArrowRightOpen,
		ArrowBarUp,
		ArrowBarUpOpen,
		ArrowBarDown,
		ArrowBarDownOpen,
		ArrowBarLeft,
		ArrowBarLeftOpen,
		ArrowBarRight,
		ArrowBarRightOpen,
		Arrow,
		ArrowOpen,
		ArrowWide,
		ArrowWideOpen,
	].{
		is_eq : _
		to_hash : _

		## Parse a canonical Plotly name. Numeric aliases are intentionally
		## omitted from this API; tags make the selected symbol explicit.
		from_str : Str -> Try(Symbol, [InvalidSymbol(Str)])
		from_str = |text| match text {
			"circle" => Ok(Circle)
			"circle-open" => Ok(CircleOpen)
			"circle-dot" => Ok(CircleDot)
			"circle-open-dot" => Ok(CircleOpenDot)
			"square" => Ok(Square)
			"square-open" => Ok(SquareOpen)
			"square-dot" => Ok(SquareDot)
			"square-open-dot" => Ok(SquareOpenDot)
			"diamond" => Ok(Diamond)
			"diamond-open" => Ok(DiamondOpen)
			"diamond-dot" => Ok(DiamondDot)
			"diamond-open-dot" => Ok(DiamondOpenDot)
			"cross" => Ok(Cross)
			"cross-open" => Ok(CrossOpen)
			"cross-dot" => Ok(CrossDot)
			"cross-open-dot" => Ok(CrossOpenDot)
			"x" => Ok(X)
			"x-open" => Ok(XOpen)
			"x-dot" => Ok(XDot)
			"x-open-dot" => Ok(XOpenDot)
			"triangle-up" => Ok(TriangleUp)
			"triangle-up-open" => Ok(TriangleUpOpen)
			"triangle-up-dot" => Ok(TriangleUpDot)
			"triangle-up-open-dot" => Ok(TriangleUpOpenDot)
			"triangle-down" => Ok(TriangleDown)
			"triangle-down-open" => Ok(TriangleDownOpen)
			"triangle-down-dot" => Ok(TriangleDownDot)
			"triangle-down-open-dot" => Ok(TriangleDownOpenDot)
			"triangle-left" => Ok(TriangleLeft)
			"triangle-left-open" => Ok(TriangleLeftOpen)
			"triangle-left-dot" => Ok(TriangleLeftDot)
			"triangle-left-open-dot" => Ok(TriangleLeftOpenDot)
			"triangle-right" => Ok(TriangleRight)
			"triangle-right-open" => Ok(TriangleRightOpen)
			"triangle-right-dot" => Ok(TriangleRightDot)
			"triangle-right-open-dot" => Ok(TriangleRightOpenDot)
			"triangle-ne" => Ok(TriangleNe)
			"triangle-ne-open" => Ok(TriangleNeOpen)
			"triangle-ne-dot" => Ok(TriangleNeDot)
			"triangle-ne-open-dot" => Ok(TriangleNeOpenDot)
			"triangle-se" => Ok(TriangleSe)
			"triangle-se-open" => Ok(TriangleSeOpen)
			"triangle-se-dot" => Ok(TriangleSeDot)
			"triangle-se-open-dot" => Ok(TriangleSeOpenDot)
			"triangle-sw" => Ok(TriangleSw)
			"triangle-sw-open" => Ok(TriangleSwOpen)
			"triangle-sw-dot" => Ok(TriangleSwDot)
			"triangle-sw-open-dot" => Ok(TriangleSwOpenDot)
			"triangle-nw" => Ok(TriangleNw)
			"triangle-nw-open" => Ok(TriangleNwOpen)
			"triangle-nw-dot" => Ok(TriangleNwDot)
			"triangle-nw-open-dot" => Ok(TriangleNwOpenDot)
			"pentagon" => Ok(Pentagon)
			"pentagon-open" => Ok(PentagonOpen)
			"pentagon-dot" => Ok(PentagonDot)
			"pentagon-open-dot" => Ok(PentagonOpenDot)
			"hexagon" => Ok(Hexagon)
			"hexagon-open" => Ok(HexagonOpen)
			"hexagon-dot" => Ok(HexagonDot)
			"hexagon-open-dot" => Ok(HexagonOpenDot)
			"hexagon2" => Ok(Hexagon2)
			"hexagon2-open" => Ok(Hexagon2Open)
			"hexagon2-dot" => Ok(Hexagon2Dot)
			"hexagon2-open-dot" => Ok(Hexagon2OpenDot)
			"octagon" => Ok(Octagon)
			"octagon-open" => Ok(OctagonOpen)
			"octagon-dot" => Ok(OctagonDot)
			"octagon-open-dot" => Ok(OctagonOpenDot)
			"star" => Ok(Star)
			"star-open" => Ok(StarOpen)
			"star-dot" => Ok(StarDot)
			"star-open-dot" => Ok(StarOpenDot)
			"hexagram" => Ok(Hexagram)
			"hexagram-open" => Ok(HexagramOpen)
			"hexagram-dot" => Ok(HexagramDot)
			"hexagram-open-dot" => Ok(HexagramOpenDot)
			"star-triangle-up" => Ok(StarTriangleUp)
			"star-triangle-up-open" => Ok(StarTriangleUpOpen)
			"star-triangle-up-dot" => Ok(StarTriangleUpDot)
			"star-triangle-up-open-dot" => Ok(StarTriangleUpOpenDot)
			"star-triangle-down" => Ok(StarTriangleDown)
			"star-triangle-down-open" => Ok(StarTriangleDownOpen)
			"star-triangle-down-dot" => Ok(StarTriangleDownDot)
			"star-triangle-down-open-dot" => Ok(StarTriangleDownOpenDot)
			"star-square" => Ok(StarSquare)
			"star-square-open" => Ok(StarSquareOpen)
			"star-square-dot" => Ok(StarSquareDot)
			"star-square-open-dot" => Ok(StarSquareOpenDot)
			"star-diamond" => Ok(StarDiamond)
			"star-diamond-open" => Ok(StarDiamondOpen)
			"star-diamond-dot" => Ok(StarDiamondDot)
			"star-diamond-open-dot" => Ok(StarDiamondOpenDot)
			"diamond-tall" => Ok(DiamondTall)
			"diamond-tall-open" => Ok(DiamondTallOpen)
			"diamond-tall-dot" => Ok(DiamondTallDot)
			"diamond-tall-open-dot" => Ok(DiamondTallOpenDot)
			"diamond-wide" => Ok(DiamondWide)
			"diamond-wide-open" => Ok(DiamondWideOpen)
			"diamond-wide-dot" => Ok(DiamondWideDot)
			"diamond-wide-open-dot" => Ok(DiamondWideOpenDot)
			"hourglass" => Ok(Hourglass)
			"hourglass-open" => Ok(HourglassOpen)
			"bowtie" => Ok(Bowtie)
			"bowtie-open" => Ok(BowtieOpen)
			"circle-cross" => Ok(CircleCross)
			"circle-cross-open" => Ok(CircleCrossOpen)
			"circle-x" => Ok(CircleX)
			"circle-x-open" => Ok(CircleXOpen)
			"square-cross" => Ok(SquareCross)
			"square-cross-open" => Ok(SquareCrossOpen)
			"square-x" => Ok(SquareX)
			"square-x-open" => Ok(SquareXOpen)
			"diamond-cross" => Ok(DiamondCross)
			"diamond-cross-open" => Ok(DiamondCrossOpen)
			"diamond-x" => Ok(DiamondX)
			"diamond-x-open" => Ok(DiamondXOpen)
			"cross-thin" => Ok(CrossThin)
			"cross-thin-open" => Ok(CrossThinOpen)
			"x-thin" => Ok(XThin)
			"x-thin-open" => Ok(XThinOpen)
			"asterisk" => Ok(Asterisk)
			"asterisk-open" => Ok(AsteriskOpen)
			"hash" => Ok(Hash)
			"hash-open" => Ok(HashOpen)
			"hash-dot" => Ok(HashDot)
			"hash-open-dot" => Ok(HashOpenDot)
			"y-up" => Ok(YUp)
			"y-up-open" => Ok(YUpOpen)
			"y-down" => Ok(YDown)
			"y-down-open" => Ok(YDownOpen)
			"y-left" => Ok(YLeft)
			"y-left-open" => Ok(YLeftOpen)
			"y-right" => Ok(YRight)
			"y-right-open" => Ok(YRightOpen)
			"line-ew" => Ok(LineEw)
			"line-ew-open" => Ok(LineEwOpen)
			"line-ns" => Ok(LineNs)
			"line-ns-open" => Ok(LineNsOpen)
			"line-ne" => Ok(LineNe)
			"line-ne-open" => Ok(LineNeOpen)
			"line-nw" => Ok(LineNw)
			"line-nw-open" => Ok(LineNwOpen)
			"arrow-up" => Ok(ArrowUp)
			"arrow-up-open" => Ok(ArrowUpOpen)
			"arrow-down" => Ok(ArrowDown)
			"arrow-down-open" => Ok(ArrowDownOpen)
			"arrow-left" => Ok(ArrowLeft)
			"arrow-left-open" => Ok(ArrowLeftOpen)
			"arrow-right" => Ok(ArrowRight)
			"arrow-right-open" => Ok(ArrowRightOpen)
			"arrow-bar-up" => Ok(ArrowBarUp)
			"arrow-bar-up-open" => Ok(ArrowBarUpOpen)
			"arrow-bar-down" => Ok(ArrowBarDown)
			"arrow-bar-down-open" => Ok(ArrowBarDownOpen)
			"arrow-bar-left" => Ok(ArrowBarLeft)
			"arrow-bar-left-open" => Ok(ArrowBarLeftOpen)
			"arrow-bar-right" => Ok(ArrowBarRight)
			"arrow-bar-right-open" => Ok(ArrowBarRightOpen)
			"arrow" => Ok(Arrow)
			"arrow-open" => Ok(ArrowOpen)
			"arrow-wide" => Ok(ArrowWide)
			"arrow-wide-open" => Ok(ArrowWideOpen)
			_ => Err(InvalidSymbol(text))
		}

		## The canonical Plotly name of this symbol.
		to_str : Symbol -> Str
		to_str = |symbol| match symbol {
			Circle => "circle"
			CircleOpen => "circle-open"
			CircleDot => "circle-dot"
			CircleOpenDot => "circle-open-dot"
			Square => "square"
			SquareOpen => "square-open"
			SquareDot => "square-dot"
			SquareOpenDot => "square-open-dot"
			Diamond => "diamond"
			DiamondOpen => "diamond-open"
			DiamondDot => "diamond-dot"
			DiamondOpenDot => "diamond-open-dot"
			Cross => "cross"
			CrossOpen => "cross-open"
			CrossDot => "cross-dot"
			CrossOpenDot => "cross-open-dot"
			X => "x"
			XOpen => "x-open"
			XDot => "x-dot"
			XOpenDot => "x-open-dot"
			TriangleUp => "triangle-up"
			TriangleUpOpen => "triangle-up-open"
			TriangleUpDot => "triangle-up-dot"
			TriangleUpOpenDot => "triangle-up-open-dot"
			TriangleDown => "triangle-down"
			TriangleDownOpen => "triangle-down-open"
			TriangleDownDot => "triangle-down-dot"
			TriangleDownOpenDot => "triangle-down-open-dot"
			TriangleLeft => "triangle-left"
			TriangleLeftOpen => "triangle-left-open"
			TriangleLeftDot => "triangle-left-dot"
			TriangleLeftOpenDot => "triangle-left-open-dot"
			TriangleRight => "triangle-right"
			TriangleRightOpen => "triangle-right-open"
			TriangleRightDot => "triangle-right-dot"
			TriangleRightOpenDot => "triangle-right-open-dot"
			TriangleNe => "triangle-ne"
			TriangleNeOpen => "triangle-ne-open"
			TriangleNeDot => "triangle-ne-dot"
			TriangleNeOpenDot => "triangle-ne-open-dot"
			TriangleSe => "triangle-se"
			TriangleSeOpen => "triangle-se-open"
			TriangleSeDot => "triangle-se-dot"
			TriangleSeOpenDot => "triangle-se-open-dot"
			TriangleSw => "triangle-sw"
			TriangleSwOpen => "triangle-sw-open"
			TriangleSwDot => "triangle-sw-dot"
			TriangleSwOpenDot => "triangle-sw-open-dot"
			TriangleNw => "triangle-nw"
			TriangleNwOpen => "triangle-nw-open"
			TriangleNwDot => "triangle-nw-dot"
			TriangleNwOpenDot => "triangle-nw-open-dot"
			Pentagon => "pentagon"
			PentagonOpen => "pentagon-open"
			PentagonDot => "pentagon-dot"
			PentagonOpenDot => "pentagon-open-dot"
			Hexagon => "hexagon"
			HexagonOpen => "hexagon-open"
			HexagonDot => "hexagon-dot"
			HexagonOpenDot => "hexagon-open-dot"
			Hexagon2 => "hexagon2"
			Hexagon2Open => "hexagon2-open"
			Hexagon2Dot => "hexagon2-dot"
			Hexagon2OpenDot => "hexagon2-open-dot"
			Octagon => "octagon"
			OctagonOpen => "octagon-open"
			OctagonDot => "octagon-dot"
			OctagonOpenDot => "octagon-open-dot"
			Star => "star"
			StarOpen => "star-open"
			StarDot => "star-dot"
			StarOpenDot => "star-open-dot"
			Hexagram => "hexagram"
			HexagramOpen => "hexagram-open"
			HexagramDot => "hexagram-dot"
			HexagramOpenDot => "hexagram-open-dot"
			StarTriangleUp => "star-triangle-up"
			StarTriangleUpOpen => "star-triangle-up-open"
			StarTriangleUpDot => "star-triangle-up-dot"
			StarTriangleUpOpenDot => "star-triangle-up-open-dot"
			StarTriangleDown => "star-triangle-down"
			StarTriangleDownOpen => "star-triangle-down-open"
			StarTriangleDownDot => "star-triangle-down-dot"
			StarTriangleDownOpenDot => "star-triangle-down-open-dot"
			StarSquare => "star-square"
			StarSquareOpen => "star-square-open"
			StarSquareDot => "star-square-dot"
			StarSquareOpenDot => "star-square-open-dot"
			StarDiamond => "star-diamond"
			StarDiamondOpen => "star-diamond-open"
			StarDiamondDot => "star-diamond-dot"
			StarDiamondOpenDot => "star-diamond-open-dot"
			DiamondTall => "diamond-tall"
			DiamondTallOpen => "diamond-tall-open"
			DiamondTallDot => "diamond-tall-dot"
			DiamondTallOpenDot => "diamond-tall-open-dot"
			DiamondWide => "diamond-wide"
			DiamondWideOpen => "diamond-wide-open"
			DiamondWideDot => "diamond-wide-dot"
			DiamondWideOpenDot => "diamond-wide-open-dot"
			Hourglass => "hourglass"
			HourglassOpen => "hourglass-open"
			Bowtie => "bowtie"
			BowtieOpen => "bowtie-open"
			CircleCross => "circle-cross"
			CircleCrossOpen => "circle-cross-open"
			CircleX => "circle-x"
			CircleXOpen => "circle-x-open"
			SquareCross => "square-cross"
			SquareCrossOpen => "square-cross-open"
			SquareX => "square-x"
			SquareXOpen => "square-x-open"
			DiamondCross => "diamond-cross"
			DiamondCrossOpen => "diamond-cross-open"
			DiamondX => "diamond-x"
			DiamondXOpen => "diamond-x-open"
			CrossThin => "cross-thin"
			CrossThinOpen => "cross-thin-open"
			XThin => "x-thin"
			XThinOpen => "x-thin-open"
			Asterisk => "asterisk"
			AsteriskOpen => "asterisk-open"
			Hash => "hash"
			HashOpen => "hash-open"
			HashDot => "hash-dot"
			HashOpenDot => "hash-open-dot"
			YUp => "y-up"
			YUpOpen => "y-up-open"
			YDown => "y-down"
			YDownOpen => "y-down-open"
			YLeft => "y-left"
			YLeftOpen => "y-left-open"
			YRight => "y-right"
			YRightOpen => "y-right-open"
			LineEw => "line-ew"
			LineEwOpen => "line-ew-open"
			LineNs => "line-ns"
			LineNsOpen => "line-ns-open"
			LineNe => "line-ne"
			LineNeOpen => "line-ne-open"
			LineNw => "line-nw"
			LineNwOpen => "line-nw-open"
			ArrowUp => "arrow-up"
			ArrowUpOpen => "arrow-up-open"
			ArrowDown => "arrow-down"
			ArrowDownOpen => "arrow-down-open"
			ArrowLeft => "arrow-left"
			ArrowLeftOpen => "arrow-left-open"
			ArrowRight => "arrow-right"
			ArrowRightOpen => "arrow-right-open"
			ArrowBarUp => "arrow-bar-up"
			ArrowBarUpOpen => "arrow-bar-up-open"
			ArrowBarDown => "arrow-bar-down"
			ArrowBarDownOpen => "arrow-bar-down-open"
			ArrowBarLeft => "arrow-bar-left"
			ArrowBarLeftOpen => "arrow-bar-left-open"
			ArrowBarRight => "arrow-bar-right"
			ArrowBarRightOpen => "arrow-bar-right-open"
			Arrow => "arrow"
			ArrowOpen => "arrow-open"
			ArrowWide => "arrow-wide"
			ArrowWideOpen => "arrow-wide-open"
		}
	}

	Props := {
		size : F64 ?? 6,
		color : Color ?? Color.rgb({ red: 31, green: 119, blue: 180 }),
		symbol : Symbol ?? Circle,
	}

	## The standard Plotly marker.
	default : Marker
	default = Marker.({ size: 6, color: Color.rgb({ red: 31, green: 119, blue: 180 }), symbol: Circle })

	## Size must be finite and nonnegative, including zero for hidden points.
	new : Props -> Try(Marker, [InvalidMarkerSize(F64)])
	new = |props| {
		if props.size.is_finite() and props.size >= 0 {
			Ok(Marker.({ size: props.size, color: props.color, symbol: props.symbol }))
		} else {
			Err(InvalidMarkerSize(props.size))
		}
	}

	get_size : Marker -> F64
	get_size = |Marker.(fields)| fields.size
	get_color : Marker -> Color
	get_color = |Marker.(fields)| fields.color
	get_symbol : Marker -> Str
	get_symbol = |Marker.(fields)| fields.symbol.to_str()

	to_json_value : Marker -> InternalJson
	to_json_value = |Marker.(fields)| InternalJson.object([
		{ name: "size", value: InternalJson.encode(fields.size) ?? crash "Marker.to_json_value: non-finite size passed constructor" },
		{ name: "color", value: fields.color.to_json_value() },
		{ name: "symbol", value: InternalJson.string(fields.symbol.to_str()) },
	])
	to_json : Marker -> Str
	to_json = |marker| marker.to_json_value().to_json()
}

# Canonical names round-trip through the closed symbol type.
expect Marker.Symbol.from_str("circle-open-dot").map_ok(Marker.Symbol.to_str) == Ok("circle-open-dot")
expect Marker.Symbol.from_str("arrow-wide-open").map_ok(Marker.Symbol.to_str) == Ok("arrow-wide-open")
expect Marker.Symbol.from_str("154").is_err()
expect Marker.Symbol.from_str("unknown").is_err()
expect {
	marker = Marker.new({})?
	marker.get_size() == 6 and marker.get_symbol() == "circle"
}
expect Marker.new({ size: 0, symbol: CircleOpenDot }).is_ok()
expect Marker.new({ size: -1 }).is_err()
expect Marker.new({ size: F64.nan }).is_err()
expect Marker.new({ size: F64.infinity }).is_err()

expect [
	Circle,
	CircleOpen,
	CircleDot,
	CircleOpenDot,
	Square,
	SquareOpen,
	SquareDot,
	SquareOpenDot,
	Diamond,
	DiamondOpen,
	DiamondDot,
	DiamondOpenDot,
	Cross,
	CrossOpen,
	CrossDot,
	CrossOpenDot,
	X,
	XOpen,
	XDot,
	XOpenDot,
	TriangleUp,
	TriangleUpOpen,
	TriangleUpDot,
	TriangleUpOpenDot,
	TriangleDown,
	TriangleDownOpen,
	TriangleDownDot,
	TriangleDownOpenDot,
	TriangleLeft,
	TriangleLeftOpen,
	TriangleLeftDot,
	TriangleLeftOpenDot,
	TriangleRight,
	TriangleRightOpen,
	TriangleRightDot,
	TriangleRightOpenDot,
	TriangleNe,
	TriangleNeOpen,
	TriangleNeDot,
	TriangleNeOpenDot,
	TriangleSe,
	TriangleSeOpen,
	TriangleSeDot,
	TriangleSeOpenDot,
	TriangleSw,
	TriangleSwOpen,
	TriangleSwDot,
	TriangleSwOpenDot,
	TriangleNw,
	TriangleNwOpen,
	TriangleNwDot,
	TriangleNwOpenDot,
	Pentagon,
	PentagonOpen,
	PentagonDot,
	PentagonOpenDot,
	Hexagon,
	HexagonOpen,
	HexagonDot,
	HexagonOpenDot,
	Hexagon2,
	Hexagon2Open,
	Hexagon2Dot,
	Hexagon2OpenDot,
	Octagon,
	OctagonOpen,
	OctagonDot,
	OctagonOpenDot,
	Star,
	StarOpen,
	StarDot,
	StarOpenDot,
	Hexagram,
	HexagramOpen,
	HexagramDot,
	HexagramOpenDot,
	StarTriangleUp,
	StarTriangleUpOpen,
	StarTriangleUpDot,
	StarTriangleUpOpenDot,
	StarTriangleDown,
	StarTriangleDownOpen,
	StarTriangleDownDot,
	StarTriangleDownOpenDot,
	StarSquare,
	StarSquareOpen,
	StarSquareDot,
	StarSquareOpenDot,
	StarDiamond,
	StarDiamondOpen,
	StarDiamondDot,
	StarDiamondOpenDot,
	DiamondTall,
	DiamondTallOpen,
	DiamondTallDot,
	DiamondTallOpenDot,
	DiamondWide,
	DiamondWideOpen,
	DiamondWideDot,
	DiamondWideOpenDot,
	Hourglass,
	HourglassOpen,
	Bowtie,
	BowtieOpen,
	CircleCross,
	CircleCrossOpen,
	CircleX,
	CircleXOpen,
	SquareCross,
	SquareCrossOpen,
	SquareX,
	SquareXOpen,
	DiamondCross,
	DiamondCrossOpen,
	DiamondX,
	DiamondXOpen,
	CrossThin,
	CrossThinOpen,
	XThin,
	XThinOpen,
	Asterisk,
	AsteriskOpen,
	Hash,
	HashOpen,
	HashDot,
	HashOpenDot,
	YUp,
	YUpOpen,
	YDown,
	YDownOpen,
	YLeft,
	YLeftOpen,
	YRight,
	YRightOpen,
	LineEw,
	LineEwOpen,
	LineNs,
	LineNsOpen,
	LineNe,
	LineNeOpen,
	LineNw,
	LineNwOpen,
	ArrowUp,
	ArrowUpOpen,
	ArrowDown,
	ArrowDownOpen,
	ArrowLeft,
	ArrowLeftOpen,
	ArrowRight,
	ArrowRightOpen,
	ArrowBarUp,
	ArrowBarUpOpen,
	ArrowBarDown,
	ArrowBarDownOpen,
	ArrowBarLeft,
	ArrowBarLeftOpen,
	ArrowBarRight,
	ArrowBarRightOpen,
	Arrow,
	ArrowOpen,
	ArrowWide,
	ArrowWideOpen,
].all(|symbol| Marker.Symbol.from_str(Marker.Symbol.to_str(symbol)) == Ok(symbol))
