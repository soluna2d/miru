local miru = require "miru"

local args = ...

local BASELINE_OFFSET_RATIO <const> = 1 / 16

return function()
	local size = args.size or 16
	miru.canvas({
		width = size,
		height = size,
	}, function(width, height)
		if width <= 0 or height <= 0 then
			return
		end
		local icon = miru.use "icon"
		local name = assert(args.name, "missing icon name")
		local color = args.color or 0xff334155
		local stream = assert(icon.stream(name, size, color))
		local x = (width - size) // 2
		local y = (height - size) // 2 + size * BASELINE_OFFSET_RATIO
		local angle = args.angle or 0
		if angle ~= 0 then
			local cx = width // 2
			local cy = height // 2
			miru.batch:layer(1, angle, cx, cy)
			miru.batch:add(stream, x - cx, y - cy)
			miru.batch:layer()
			return
		end
		miru.batch:add(stream, x, y)
	end)
end
