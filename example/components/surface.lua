local matquad = require "soluna.material.quad"
local miru = require "miru"

local args = ...
local floor <const> = math.floor
local max <const> = math.max

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

		local border_width = pixel(args.border_width or 0)
		if border_width > 0 then
			miru.batch:add(matquad.quad(w, h, args.border_color or fill), 0, 0)
			local inner_width = max(0, w - border_width * 2)
			local inner_height = max(0, h - border_width * 2)
			if inner_width > 0 and inner_height > 0 then
				miru.batch:add(matquad.quad(inner_width, inner_height, fill), border_width, border_width)
			end
		else
			miru.batch:add(matquad.quad(w, h, fill), 0, 0)
		end
	end)
end
