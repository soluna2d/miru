local miru = require "miru"

local args = ...

return function()
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	local size = args.size or 36
	local icon_size = args.icon_size or 18
	local icon_offset = (size - icon_size) // 2
	local fill
	if pressed then
		fill = args.pressed_fill or args.hover_fill or 0xffe2e8f0
	elseif hovered then
		fill = args.hover_fill or 0xfff1f5f9
	end
	local color = hovered and (args.hover_color or 0xffb91c1c) or (args.color or 0xff475569)

	miru.clickable {
		enabled = args.enabled,
		on_click = args.on_click,
	}
	miru.box({
		width = size,
		height = size,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			radius = args.radius or 8,
			fill = fill,
		})
		miru.mount("icon", {
			position = "absolute",
			left = icon_offset,
			top = icon_offset,
			width = icon_size,
			height = icon_size,
			name = args.name,
			size = icon_size,
			color = color,
			angle = args.angle or 0,
		})
	end)
end
