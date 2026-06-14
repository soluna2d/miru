local miru = require "miru"

local args = ...

local progress = miru.animated(function()
	return args.checked == true and 1 or 0
end, {
	duration = 0.12,
	easing = "out_cubic",
})

return function()
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	local enabled = args.enabled ~= false
	local width = args.width or 48
	local height = args.height or 26
	local knob = args.knob_size or 20
	local value = progress()
	local fill = miru.lerp_color(0xffe2e8f0, 0xff0d9488, value)
	local border_color = miru.lerp_color(hovered and 0xff64748b or 0xff94a3b8, 0xff0d9488, value)
	local knob_fill = miru.lerp_color(0xffffffff, 0xffecfdf5, value)
	if not enabled then
		fill = 0xffe5e7eb
		border_color = 0xffcbd5e1
		knob_fill = 0xff94a3b8
	elseif pressed then
		border_color = 0xff0f766e
	end

	miru.clickable {
		enabled = enabled,
		on_click = function()
			if args.on_change then
				args.on_change(args.checked ~= true)
			end
		end,
	}

	miru.box({
		width = width,
		height = height,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			radius = height // 2,
			fill = fill,
			border_color = border_color,
			border_width = 1,
		})
		miru.mount("surface", {
			position = "absolute",
			left = 3 + (width - knob - 6) * value,
			top = (height - knob) // 2,
			width = knob,
			height = knob,
			radius = knob // 2,
			fill = knob_fill,
		})
	end)
end
