local M = {}

local max = math.max

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function text_engine(report)
	return {
		layout = function(args)
			local width = assert(args.width, "text layout requires resolved width")
			local advance = args.advance or 10
			local line_height = args.line_height or 20
			local count = #tostring(args.text or "")
			local chars_per_line = max(1, width // advance)
			local lines = max(1, (count + chars_per_line - 1) // chars_per_line)
			local height = lines * line_height
			report.layout_count = (report.layout_count or 0) + 1
			report.layout_width = width
			report.layout_height = height
			report.line_count = lines
			return {
				height = height,
				line_count = lines,
			}
		end,
		draw = function(_, _, _, _, width, height)
			report.draw_width = width
			report.draw_height = height
		end,
	}
end

function M.run()
	local miru = require "miru"
	local report = {}
	local view = miru.new {
		w = 300,
		h = 200,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
		text_engine = text_engine(report),
	}
	local instance = view:mount("text_layout_component", {
		report = report,
		width = 120,
		text = "12345678901234567890",
	})

	view:update()
	local rect = assert(report.ref:rect())
	assert_equal(report.layout_width, 120, "initial layout width")
	assert_equal(report.layout_height, 40, "initial layout height")
	assert_equal(rect.w, 120, "initial rect width")
	assert_equal(rect.h, 40, "initial rect height")

	instance.args.width = 80
	view:update()
	rect = assert(report.ref:rect())
	assert_equal(report.layout_width, 80, "updated layout width")
	assert_equal(report.layout_height, 60, "updated layout height")
	assert_equal(rect.w, 80, "updated rect width")
	assert_equal(rect.h, 60, "updated rect height")

	view:draw {
		layer = function() end,
		add = function() end,
	}
	assert_equal(report.draw_width, 80, "draw width")
	assert_equal(report.draw_height, 60, "draw height")
end

return M
