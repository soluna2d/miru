local miru = require "miru"
local rounded_rect = require "test.material.rounded_rect_native"

local floor = math.floor

local function pixel(value)
	return floor(value + 0.5)
end

return function(props, children)
	props = props or {}
	miru.box({
		width = props.width,
		height = props.height,
		minWidth = props.minWidth,
		minHeight = props.minHeight,
		maxWidth = props.maxWidth,
		maxHeight = props.maxHeight,
		flex = props.flex,
		position = props.position,
		left = props.left,
		top = props.top,
		right = props.right,
		bottom = props.bottom,
		margin = props.margin,
		padding = props.padding,
	}, function()
		miru.canvas({
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
		}, function(width, height)
			if width <= 0 or height <= 0 then
				return
			end
			miru.batch:add(rounded_rect.rect {
				width = pixel(width),
				height = pixel(height),
				radius = pixel(props.radius or 0),
				fill = props.fill or props.background or 0xffffffff,
				border = props.border or props.fill or props.background or 0xffffffff,
				border_width = pixel(props.border_width or 0),
			}, 0, 0)
		end)
		if children then
			children()
		end
	end)
end
