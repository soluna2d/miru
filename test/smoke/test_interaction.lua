local M = {}

local function new_view(miru)
	return miru.new {
		width = 300,
		height = 200,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
end

local function test_setup_prop_bindings(miru)
	local report = {}
	local view = new_view(miru)
	local instance = view:mount("prop_binding_component", {
		width = 120,
		height = 80,
		enabled = false,
		on_click = function()
			report.click = "old"
		end,
		on_char = function()
			report.char = "old"
		end,
		on_scroll = function()
			report.scroll = "old"
		end,
	})
	view:update()
	view:pointer(10, 10)
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	view:char {}
	view:mouse_scroll {}
	assert(not report.click and not report.char and not report.scroll)

	instance.args.enabled = true
	instance.args.on_click = function()
		report.click = "new"
	end
	instance.args.on_char = function()
		report.char = "new"
	end
	instance.args.on_scroll = function()
		report.scroll = "new"
	end
	view:update()
	view:mouse_button(0, 1)
	view:mouse_button(0, 0)
	view:char {}
	view:mouse_scroll {}
	assert(report.click == "new")
	assert(report.char == "new")
	assert(report.scroll == "new")
end

local function test_interaction_lifecycle(miru)
	local report = {}
	local view = new_view(miru)
	local instance = view:mount("interaction_component", {
		width = 120,
		height = 80,
		report = report,
	})
	view:update()

	local rect = assert(report.ref:window_rect())
	assert(rect.x == 0 and rect.y == 0 and rect.w == 120 and rect.h == 80)
	view:pointer(10, 10)
	view:update()
	assert(report.hovered)

	view:mouse_button(0, 1)
	view:update()
	assert(report.pressed)
	assert(report.focused)

	view:char {
		codepoint = string.byte "a",
	}
	view:key {
		keycode = 259,
	}
	view:clipboard_pasted {
		text = "paste",
	}
	view:mouse_scroll {
		scroll_y = 2,
	}
	assert(report.codepoint == string.byte "a")
	assert(report.keycode == 259)
	assert(report.clipboard == "paste")
	assert(report.scroll_y == 2)

	view:mouse_button(0, 0)
	view:update()
	assert(report.clicks == 1)
	assert(not report.pressed)

	view:pointer(200, 160)
	view:update()
	assert(not report.hovered)
	view:pointer(10, 10)
	view:mouse_button(0, 1)
	view:update()
	assert(report.hovered)
	assert(report.pressed)
	instance:destroy()
	view:update()
	view:mouse_button(0, 0)
	view:char {
		codepoint = string.byte "b",
	}
	view:key {
		keycode = 260,
	}
	view:clipboard_pasted {
		text = "stale",
	}
	view:mouse_scroll {
		scroll_y = 3,
	}
	assert(report.blur_count == 1)
	assert(report.clicks == 1)
	assert(report.codepoint == string.byte "a")
	assert(report.keycode == 259)
	assert(report.clipboard == "paste")
	assert(report.scroll_y == 2)
	assert(not report.ref:window_rect())
end

function M.run()
	local miru = require "miru"
	test_setup_prop_bindings(miru)
	test_interaction_lifecycle(miru)
end

return M
