local miru = require "miru"

local args = ...

local progress = miru.animated(function()
	return args.checked and 1 or 0
end, {
	duration = 0.16,
	easing = "out_cubic",
})

return function()
	local palette = miru.use "palette"
	local hovered = miru.hovered()()
	local pressed = miru.pressed()()
	local enabled = args.enabled ~= false
	local width = args.width or 52
	local height = args.height or 28
	local knob = args.knob_size or 20
	local value = progress()
	local fill = miru.lerp_color(palette.surface_alt, palette.primary, value)
	local border = miru.lerp_color(hovered and palette.muted or palette.line, palette.primary_pressed, value)

	if not enabled then
		fill = 0xffdfe4e2
		border = palette.line
	elseif pressed then
		border = palette.primary_pressed
	end

	miru.clickable {
		enabled = enabled,
		on_click = args.on_toggle,
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
			fill = fill,
			border_color = border,
			border_width = 1,
		})
		miru.box {
			position = "absolute",
			left = 4 + (width - knob - 8) * value,
			top = (height - knob) // 2,
			width = knob,
			height = knob,
			background = enabled and palette.white or 0xffaab4b0,
		}
	end)
end
