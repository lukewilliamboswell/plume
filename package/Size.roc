import InternalJson

## The figure's pixel size and the margins around its plotting area.
## The default leaves all of them to Plotly, which fills the width of its
## container, uses a height of 450 pixels and reserves room for titles.
Size :: [Automatic, Explicit(Props)].{

	## Margins between the figure's edge and its plotting area, in pixels.
	## Unnamed sides keep Plotly's defaults: 80 at the left, right and
	## bottom, and 100 at the top. Axis labels, legends and titles still
	## expand a margin when they need more room.
	Margin := {
		left : U16 ?? 80,
		right : U16 ?? 80,
		top : U16 ?? 100,
		bottom : U16 ?? 80,
	}

	## Configure the figure's size.
	## `width` and `height` default to `Auto`; `Pixels(count)` fixes one
	## dimension, and must be at least ten pixels, the smallest size Plotly
	## draws. A dashboard usually fixes only the height and lets the width
	## follow its container. `margin` defaults to `Auto`, which keeps
	## Plotly's margins; `Pixels(margin)` sets them, which tightens a small
	## chart.
	Props := {
		width : [Auto, Pixels(U16)] ?? Auto,
		height : [Auto, Pixels(U16)] ?? Auto,
		margin : [Auto, Pixels(Margin)] ?? Auto,
	}

	## Leave the size and margins to Plotly, encoding no settings.
	default : Size
	default = Automatic

	## Validate fixed dimensions and construct a size.
	## Returns `InvalidWidth(pixels)` or `InvalidHeight(pixels)` for a fixed
	## dimension below ten pixels. Margins accept any pixel count.
	##
	## ```roc
	## expect {
	##     size = Size.new({ height: Pixels(320), margin: Pixels({ left: 48, right: 16, top: 24, bottom: 40 }) })?
	##     size.to_json().contains("320")
	## }
	## ```
	new : Props -> Try(Size, [InvalidWidth(U16), InvalidHeight(U16)])
	new = |props| {
		match props.width {
			Pixels(pixels) if pixels < minimum_pixels => return Err(InvalidWidth(pixels))
			_ => {}
		}
		match props.height {
			Pixels(pixels) if pixels < minimum_pixels => return Err(InvalidHeight(pixels))
			_ => {}
		}
		Ok(Explicit(props))
	}

	## Internal composition hook used by Plume's renderers.
	## It returns the layout fields this size sets, which [Layout] merges into
	## its own object; most applications use [Size.to_json] instead.
	to_json_fields : Size -> List({ name : Str, value : InternalJson })
	to_json_fields = |size| match size {
		Automatic => []
		Explicit(props) => {
			width_fields = match props.width {
				Auto => []
				Pixels(pixels) => [{ name: "width", value: InternalJson.encode(pixels) ?? crash "Size.to_json_fields: U16 encoding failed" }]
			}
			height_fields = match props.height {
				Auto => []
				Pixels(pixels) => [{ name: "height", value: InternalJson.encode(pixels) ?? crash "Size.to_json_fields: U16 encoding failed" }]
			}
			margin_fields = match props.margin {
				Auto => []
				Pixels(margin) => {
					Margin.(sides) = margin
					[
						{
							name: "margin",
							value: InternalJson.object([
								{ name: "l", value: InternalJson.encode(sides.left) ?? crash "Size.to_json_fields: U16 encoding failed" },
								{ name: "r", value: InternalJson.encode(sides.right) ?? crash "Size.to_json_fields: U16 encoding failed" },
								{ name: "t", value: InternalJson.encode(sides.top) ?? crash "Size.to_json_fields: U16 encoding failed" },
								{ name: "b", value: InternalJson.encode(sides.bottom) ?? crash "Size.to_json_fields: U16 encoding failed" },
							]),
						},
					]
				}
			}
			width_fields.concat(height_fields).concat(margin_fields)
		}
	}

	## Serialize the layout fields this size sets as a JSON object.
	to_json : Size -> Str
	to_json = |size| InternalJson.object(size.to_json_fields()).to_json()
}

## Plotly's smallest drawable figure dimension.
minimum_pixels : U16
minimum_pixels = 10

## The default size sets no layout fields.
expect Size.default.to_json() == "{}"

## Fixed dimensions and margins use Plotly's layout field names.
expect {
	size = Size.new({ width: Pixels(640), height: Pixels(320), margin: Pixels({ left: 48, top: 0 }) })?
	size.to_json() == "{\"width\":640,\"height\":320,\"margin\":{\"l\":48,\"r\":80,\"t\":0,\"b\":80}}"
}

## Dimensions below ten pixels are rejected and ten is accepted.
expect {
	actual = [
		Size.new({ width: Pixels(9) }).map_ok(|_| {}) == Err(InvalidWidth(9)),
		Size.new({ height: Pixels(0) }).map_ok(|_| {}) == Err(InvalidHeight(0)),
		Size.new({ width: Pixels(10), height: Pixels(10) }).is_ok(),
	]
	actual == [True, True, True]
}

## Automatic dimensions with only margins set no width or height.
expect {
	size = Size.new({ margin: Pixels({}) })?
	size.to_json() == "{\"margin\":{\"l\":80,\"r\":80,\"t\":100,\"b\":80}}"
}
