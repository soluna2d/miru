local miru = require "miru"

local args = ...

return function()
	args.report.value = miru.use "value"
end
