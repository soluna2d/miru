local yoga = require "soluna.layout.yoga"

local M = {}

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assert_close(actual, expected, message)
	if math.abs(actual - expected) > 0.001 then
		error((message or "assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function rounded_stream_size(stream, offset)
	local width, height = string.unpack("<ff", stream, offset + 20)
	return width, height
end

local function assert_surface_draw_commands(node, path)
	path = path or node.kind
	for i = 1, #node.children do
		local child = node.children[i]
		local child_path = path .. "/" .. child.kind .. "[" .. tostring(i) .. "]"
		if child.kind == "canvas" then
			local _, _, parent_w, parent_h = yoga.node_get(node.node)
			local commands = child.commands or {}
			assert_equal(
				#commands,
				1,
				"surface canvas emits one draw command at " .. child_path
				.. " with parent size " .. tostring(parent_w) .. "x" .. tostring(parent_h)
			)
			local command = commands[1]
			assert_equal(command.name, "add", "surface canvas emits add command")
			local stream = command.args[1]
			assert_equal(type(stream), "string", "surface command carries a packed stream")
			assert_equal(#stream, 64, "rounded rect stream has two primitive pairs")
			local width, height = rounded_stream_size(stream, 1)
			assert_close(width, parent_w, "rounded rect stream width matches surface width")
			assert_close(height, parent_h, "rounded rect stream height matches surface height")
		end
		assert_surface_draw_commands(child, child_path)
	end
end

local function assert_surface_canvas_bounds(node)
	for i = 1, #node.children do
		local child = node.children[i]
		if child.kind == "canvas" then
			local _, _, parent_w, parent_h = yoga.node_get(node.node)
			local _, _, canvas_w, canvas_h = yoga.node_get(child.node)
			assert_equal(canvas_w, parent_w, "surface canvas stays within parent width")
			assert_equal(canvas_h, parent_h, "surface canvas stays within parent height")
		end
		assert_surface_canvas_bounds(child)
	end
end

function M.run()
	local miru = require "miru"

	local view = miru.new {
		width = 220,
		height = 80,
		component_path = "test/feature/showcase/?.lua;?.lua;?/init.lua",
	}
	local root = view:mount("button", {
		label = "Button",
	})
	local surface = root.render_node.children[1]
	local canvas = surface.children[1]
	local _, _, surface_w, surface_h = yoga.node_get(surface.node)
	local _, _, canvas_w, canvas_h = yoga.node_get(canvas.node)

	assert_equal(surface_w, 150, "button surface resolves width")
	assert_equal(surface_h, 38, "button surface resolves height")
	assert_equal(canvas_w, surface_w, "surface canvas matches owner width")
	assert_equal(canvas_h, surface_h, "surface canvas matches owner height")

	local showcase = miru.new {
		width = 1200,
		height = 800,
		component_path = "test/feature/showcase/?.lua;?.lua;?/init.lua",
	}
	local showcase_root = showcase:mount("root", {
		width = 1200,
		height = 800,
	})
	assert_surface_canvas_bounds(showcase_root.render_node)
	assert_surface_draw_commands(showcase_root.render_node)
end

return M
