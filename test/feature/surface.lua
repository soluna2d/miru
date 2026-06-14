local miru = require "miru"

local args = ...

local floor <const> = math.floor

local function pixel(value)
	return floor(value + 0.5)
end

return function()
	miru.canvas({
		width = "100%",
		height = "100%",
	}, function(width, height)
		local fill = args.fill
		if fill == nil then
			return
		end
		local pixel_width = pixel(width)
		local pixel_height = pixel(height)
		if pixel_width <= 0 or pixel_height <= 0 then
			return
		end
		local rounded_rect = miru.use "rounded_rect"
		local stream = rounded_rect.rect {
			width = pixel_width,
			height = pixel_height,
			radius = pixel(args.radius or 0),
			fill = fill,
			border = args.border_color or fill,
			border_width = pixel(args.border_width or 0),
		}
		if stream then
			miru.batch:add(stream, 0, 0)
		end
	end)
end
