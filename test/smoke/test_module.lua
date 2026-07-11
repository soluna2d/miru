local M = {}

function M.run()
	local miru = require "miru"

	assert(type(miru.new) == "function")
	assert(type(miru.value) == "function")
	assert(type(miru.computed) == "function")
	assert(type(miru.box) == "function")
	assert(type(miru.canvas) == "function")
	assert(type(miru.text) == "function")
	assert(type(miru.text_styles) == "function")
	assert(type(miru.use) == "function")
	assert(type(miru.focusable) == "function")
	assert(type(miru.scrollable) == "function")
	assert(type(miru.focused) == "function")
end

return M
