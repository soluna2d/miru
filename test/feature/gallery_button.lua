local miru = require "miru"

local args = ...
local max <const> = math.max

local function colors(kind, hovered, pressed, active)
	if kind == "primary" then
		return pressed and 0xff0f766e or hovered and 0xff14b8a6 or 0xff0d9488, 0xffffffff, 0xff0d9488
	elseif kind == "danger" then
		return pressed and 0xffffe4e6 or hovered and 0xfffff1f2 or 0xffffffff, 0xffb91c1c, 0xffffcdd2
	elseif active then
		return 0xffe0f2fe, 0xff075985, 0xff7dd3fc
	end
	return pressed and 0xffe2e8f0 or hovered and 0xfff8fafc or 0xffffffff, 0xff334155, 0xffcbd5e1
end

return function()
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	miru.clickable {
		on_click = args.on_click,
	}
	local background, color, border = colors(args.kind, hovered, pressed, args.active)
	local height = args.height or 36
	local width = args.width or 120
	local icon_name = args.icon_right
	local icon_size = icon_name and (args.icon_size or 16) or 0
	local icon_gap = icon_name and 6 or 0
	miru.hbox({
		width = width,
		height = height,
		padding = 8,
		gap = icon_gap,
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
			radius = args.radius or 8,
			border_color = border,
			border_width = args.border_width or 1,
		})
		miru.text(args.label or "", {
			width = max(0, width - 16 - icon_size - icon_gap),
			height = height - 16,
			size = args.size or 14,
			color = color,
			align = "CV",
		})
		if icon_name then
			miru.mount("icon", {
				name = icon_name,
				size = icon_size,
				color = args.icon_color or color,
				angle = args.icon_right_angle or 0,
			})
		end
	end)
end
