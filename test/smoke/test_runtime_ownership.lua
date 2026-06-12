local M = {}

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function capture_batch()
	local batch = {
		count = 0,
	}

	function batch:layer(...)
		self.count = self.count + 1
	end

	function batch:add(...)
		self.count = self.count + 1
	end

	return batch
end

function M.run()
	local miru = require "miru"

	local controls
	local view = miru.new {
		width = 200,
		height = 100,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	local root = view:mount("binding_component", {
		bind = function(value)
			controls = value
		end,
	})

	local text_node = root.render_node.children[1].children[1]
	assert_equal(text_node.kind, "text", "fixture exposes text node")
	assert_equal(text_node.text, "First", "text binding resolves initial signal")
	assert_equal(text_node.props.color, 0xfff97316, "prop binding resolves initial signal")

	local stats = view:statistics()
	assert_equal(stats.render_count, 1, "component builds once on mount")
	assert_equal(stats.command_compile_count, 1, "mount compiles initial commands")

	local binding_count = stats.binding_count
	controls.title "Second"
	controls.color(0xff22c55e)
	view:update()

	assert_equal(text_node.text, "Second", "text binding updates from signal")
	assert_equal(text_node.props.color, 0xff22c55e, "prop binding updates from signal")
	assert_equal(root.commands, nil, "binding update marks root commands dirty")
	assert_equal(stats.render_count, 1, "binding update keeps component structure stable")
	assert_equal(stats.command_compile_count, 1, "update does not compile commands")
	assert_equal(stats.binding_count, binding_count + 2, "changed bindings rerun once each")

	local batch = capture_batch()
	root:draw(batch)
	assert_equal(stats.command_compile_count, 2, "draw compiles dirty commands")
	assert(batch.count > 0, "draw emits commands")

	local effect_controls
	local effect_view = miru.new {
		width = 100,
		height = 60,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	local effect_root = effect_view:mount("ownership_effect_component", {
		bind = function(value)
			effect_controls = value
		end,
	})
	assert_equal(effect_controls.effect_runs(), 1, "component owner effect runs on mount")
	effect_controls.source(1)
	effect_view:update()
	assert_equal(effect_controls.effect_runs(), 2, "component owner effect responds before destroy")
	effect_root:destroy()
	assert_equal(effect_controls.cleanup_runs(), 1, "component owner cleanup runs on destroy")
	effect_root:destroy()
	assert_equal(effect_controls.cleanup_runs(), 1, "component owner cleanup runs once")
	effect_controls.source(2)
	effect_view:update()
	assert_equal(effect_controls.effect_runs(), 2, "component owner effect stops after destroy")

	local mixed_controls
	local mixed_view = miru.new {
		width = 200,
		height = 120,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	local mixed_root = mixed_view:mount("ownership_mixed_component", {
		bind = function(value)
			mixed_controls = value
		end,
	})
	assert_equal(mixed_controls.animation.stopped, nil, "animation owner is active before destroy")
	local mixed_stats = mixed_view:statistics()
	local mixed_binding_count = mixed_stats.binding_count
	mixed_controls.title "Second"
	mixed_view:update()
	assert(mixed_stats.binding_count > mixed_binding_count, "host binding runs before destroy")
	mixed_root:destroy()
	assert_equal(mixed_controls.canvas_cleanups(), 1, "canvas owner cleanup runs on destroy")
	assert_equal(mixed_controls.range_cleanups(), 1, "control-flow owner cleanup runs on destroy")
	assert_equal(mixed_controls.animation.stopped, true, "animation owner stops on destroy")
	mixed_binding_count = mixed_stats.binding_count
	mixed_controls.title "Third"
	mixed_controls.target(20)
	mixed_view:update()
	assert_equal(mixed_stats.binding_count, mixed_binding_count, "host binding owner stops after destroy")

	local diagnostic_view = miru.new {
		width = 100,
		height = 60,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	local ok, err = pcall(function()
		diagnostic_view:mount "ownership_bad_build_component"
	end)
	assert_equal(ok, false, "direct build-scope signal read raises diagnostic")
	assert(tostring(err):find("signal read during component build", 1, true), "diagnostic names build-scope signal read")
end

return M
