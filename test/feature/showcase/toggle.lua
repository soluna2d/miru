local miru = require "miru"
local surface = require "test.feature.showcase.surface"

local args = ...

local checked = miru.signal(args.checked == true)
local hovered = miru.hovered()
local pressed = miru.pressed()
local enabled = miru.memo(function()
	return args.enabled ~= false
end)
local width = args.width or 56
local height = args.height or 30
local knob = args.knob_size or 22
local fill = miru.memo(function()
	if not enabled() then
		return args.disabled_background or 0xffe5e7eb
	end
	if checked() then
		return (hovered() or pressed()) and 0xff1d4ed8 or 0xff2563eb
	end
	return (hovered() or pressed()) and 0xffcbd5e1 or 0xffd1d5db
end)
local knob_left = miru.memo(function()
	return checked() and (width - knob - 4) or 4
end)

miru.clickable {
	enabled = args.enabled,
	on_click = function(event)
		local next_checked = not checked()
		checked(next_checked)
		if args.on_change then
			args.on_change(next_checked, event)
		end
	end,
}

return function()
	surface({
		width = width,
		height = height,
		radius = height * 0.5,
		fill = fill,
	}, function()
		surface {
			position = "absolute",
			left = knob_left,
			top = 4,
			width = knob,
			height = knob,
			radius = knob * 0.5,
			fill = args.knob_color or 0xffffffff,
			border = 0x18000000,
			border_width = 1,
		}
	end)
end
