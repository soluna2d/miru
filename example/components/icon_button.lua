local icons = require "example.icons"
local miru = require "miru"

local args = ...

return function()
	local palette = miru.use "palette"
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	local size = args.size or 38
	local fill = pressed and palette.surface_alt or hovered and palette.primary_soft or palette.surface
	local color = hovered and palette.primary_pressed or palette.muted

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
			radius = args.radius or 6,
			fill = fill,
			border_color = palette.line,
			border_width = 1,
		})
		icons.node(args.icon or "refresh_cw", {
			width = size,
			height = size,
			size = args.icon_size or 18,
			color = color,
		})
	end)
end
