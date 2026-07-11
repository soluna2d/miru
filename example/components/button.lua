local icons = require "example.icons"
local copy = require "example.copy"
local miru = require "miru"

local args = ...
local max <const> = math.max

local function colors(palette, kind, hovered, pressed, active)
	if kind == "primary" then
		return pressed and palette.primary_pressed or hovered and palette.primary_hover or palette.primary,
			palette.white,
			palette.primary_pressed
	elseif kind == "danger" then
		return pressed and 0xffffd8d0 or hovered and palette.accent_soft or palette.surface,
			0xffa62f25,
			palette.accent
	elseif active then
		return palette.primary_soft, palette.primary_pressed, palette.primary
	end
	return pressed and palette.surface_alt or hovered and 0xfff8faf9 or palette.surface,
		palette.text,
		palette.line
end

return function()
	local palette = miru.use "palette"
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	local width = args.width or 120
	local height = args.height or 38
	local background, color, border = colors(palette, args.kind, hovered, pressed, args.active)
	local icon_size = args.right_icon and (args.icon_size or 16) or 0
	local gap = icon_size > 0 and 6 or 0

	miru.clickable {
		enabled = args.enabled,
		on_click = args.on_click,
	}
	miru.hbox({
		width = width,
		height = height,
		padding = 8,
		alignItems = "center",
		justifyContent = "center",
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = background,
			border_color = border,
			border_width = 1,
		})
		miru.text(copy.group(args.label), {
			width = max(0, width - 16 - icon_size - gap),
			height = max(0, height - 16),
			size = args.size or 14,
			color = color,
			align = "CV",
		})
		if args.right_icon then
			icons.node(args.right_icon, {
				width = icon_size,
				height = max(0, height - 16),
				size = icon_size,
				color = color,
			})
		end
	end)
end
