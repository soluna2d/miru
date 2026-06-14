local M = {}

function M.run()
	local miru = require "miru"
	local report = {}
	local view = miru.new {
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	view:provide("value", "initial")

	view:mount("provide_component", {
		report = report,
	})
	view:update()
	assert(report.value == "initial")

	view:provide("value", "updated")
	view:update()
	assert(report.value == "updated")
end

return M
