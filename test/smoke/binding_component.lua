local miru = require "miru"

local args = ...

local title = miru.signal "First"
local color = miru.signal(0xfff97316)

if args.bind then
	args.bind {
		title = title,
		color = color,
	}
end

return function()
	miru.box({
		width = 160,
		height = 40,
		background = 0xff1f2937,
	}, function()
		miru.text(title, {
			width = 160,
			height = 40,
			color = color,
			size = 14,
		})
	end)
end
