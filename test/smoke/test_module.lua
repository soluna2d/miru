local M = {}

function M.run()
	local miru = require "miru"

	assert(type(miru.new) == "function")
	assert(type(miru.value) == "function")
	assert(type(miru.computed) == "function")
	assert(type(miru.box) == "function")
	assert(type(miru.text) == "function")
end

return M
