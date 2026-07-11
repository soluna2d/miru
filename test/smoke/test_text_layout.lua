local M = {}

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

function M.run()
	local miru = require "miru"
	local text = require "test.support.text"
	local report = {}
	local view = miru.new {
		width = 300,
		height = 200,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	view:text_styles(text.styles())
	local instance = view:mount("text_layout_component", {
		report = report,
		width = 120,
		text = "one two three four five six seven eight nine ten",
	})

	view:update()
	local rect = assert(report.ref:rect())
	local initial_height = rect.h
	assert_equal(rect.w, 120, "initial rect width")
	assert(initial_height >= 20, "text should have at least one line")

	instance.args.width = 80
	view:update()
	rect = assert(report.ref:rect())
	assert_equal(rect.w, 80, "updated rect width")
	assert(rect.h > initial_height, "narrower text should occupy more lines")

	local draw_count = 0
	view:draw {
		layer = function() end,
		add = function()
			draw_count = draw_count + 1
		end,
	}
	assert(draw_count > 0, "text draw should emit a material stream")
end

return M
