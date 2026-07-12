local miru = require "miru"
local rounded_rect = require "example.rounded_rect"

local args = ...
local floor <const> = math.floor

local function pixel(value)
	return floor((value or 0) + 0.5)
end

return function()
	miru.canvas({
		width = args.width or "100%",
		height = args.height or "100%",
		position = args.position,
		left = args.left,
		top = args.top,
		right = args.right,
		bottom = args.bottom,
	}, function(width, height)
		local fill = args.fill
		if fill == nil then
			return
		end

		local w = pixel(width)
		local h = pixel(height)
		if w <= 0 or h <= 0 then
			return
		end

		rounded_rect.draw(miru.batch, w, h, {
			radius = args.radius or 0,
			fill = fill,
			border = args.border_color or fill,
			border_width = pixel(args.border_width or 0),
		})
	end)
end
