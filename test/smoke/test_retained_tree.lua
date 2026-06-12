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

local function size(node)
	local _, _, w, h = yoga.node_get(node.node)
	return w, h
end

function M.run()
	local miru = require "miru"

	local view = miru.new {
		width = 260,
		height = 160,
		component_path = "test/smoke/?.lua;?.lua;?/init.lua",
	}
	local root = view:mount("retained_tree_component", {
		width = 260,
		height = 160,
	})

	local layout_root = root.render_node.children[1]
	local intrinsic = layout_root.children[1]
	local intrinsic_child = intrinsic.children[1]
	local percent_parent = layout_root.children[2]
	local percent_child = percent_parent.children[1]
	local nested_component = layout_root.children[3]

	local intrinsic_w, intrinsic_h = size(intrinsic)
	local intrinsic_child_w, intrinsic_child_h = size(intrinsic_child)
	assert_close(intrinsic_child_w, 64, "intrinsic child width resolves")
	assert_close(intrinsic_child_h, 28, "intrinsic child height resolves")
	assert_close(intrinsic_w, intrinsic_child_w, "intrinsic parent width follows child")
	assert_close(intrinsic_h, intrinsic_child_h, "intrinsic parent height follows child")

	local percent_parent_w, percent_parent_h = size(percent_parent)
	local percent_child_w, percent_child_h = size(percent_child)
	assert_close(percent_parent_w, 120, "percent parent width resolves")
	assert_close(percent_parent_h, 50, "percent parent height resolves")
	assert_close(percent_child_w, percent_parent_w, "percent child width follows parent")
	assert_close(percent_child_h, percent_parent_h, "percent child height follows parent")

	local _, layout_h_before = size(layout_root)
	assert_close(layout_h_before, 118, "retained parent includes nested component height before destroy")
	assert_equal(#layout_root.children, 4, "retained parent starts with nested component")

	nested_component.instance:destroy()

	assert_equal(#layout_root.children, 3, "destroy detaches retained component node")
	assert_equal(layout_root.children[3].key, "tail", "destroy preserves following retained sibling")
	local _, layout_h_after = size(layout_root)
	assert_close(layout_h_after, 98, "destroy detaches component from Yoga layout")
end

return M
