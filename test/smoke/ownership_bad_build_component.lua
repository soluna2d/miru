local miru = require "miru"

local count = miru.signal(1)

return function()
	miru.text("Count: " .. tostring(count()), {
		width = 80,
		height = 24,
	})
end
