local miru = require "miru"

local args = ...

return function()
	miru.box {
		width = args.width or "100%",
		height = args.height or 1,
		background = args.color or 0xffbdc9c5,
	}
end
