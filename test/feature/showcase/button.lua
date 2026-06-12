local miru = require "miru"
local surface = require "test.feature.showcase.surface"

local args = ...

local label <const> = args.label or "Button"
local hovered = miru.hovered()
local pressed = miru.pressed()

miru.clickable {
	enabled = args.enabled,
	on_click = args.on_click,
}

return function()
	local enabled = args.enabled ~= false
	local fill = args.background or 0xffe5e7eb
	local color = args.text_color or 0xff111827
	if not enabled then
		fill = args.disabled_background or 0xfff3f4f6
		color = args.disabled_text_color or 0xff9ca3af
	elseif pressed() then
		fill = args.pressed_background or 0xffbfdbfe
	elseif hovered() then
		fill = args.hover_background or 0xffdbeafe
	end

	surface({
		width = args.width or 150,
		height = args.height or 38,
		radius = args.radius or 8,
		fill = fill,
		border = args.border or 0xffcbd5e1,
		border_width = args.border_width or 1,
	}, function()
		miru.text(label, {
			width = "100%",
			height = "100%",
			size = args.text_size or 15,
			color = color,
			align = "CV",
		})
	end)
end
