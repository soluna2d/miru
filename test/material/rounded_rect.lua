local render = require "soluna.render"
local matext = require "soluna.material.ext"
local rounded_rect = require "test.material.rounded_rect_native"

local ctx = ...
local state = ctx.state
local render_conf = ctx.settings

rounded_rect.set_material_id(ctx.id)

local inst_buffer = render.buffer {
	type = "vertex",
	usage = "stream",
	label = "miru-test-rounded-rect-instance",
	size = rounded_rect.instance_size * render_conf.draw_instance,
}

local bindings = render.bindings()
bindings:vbuffer(0, inst_buffer)
bindings:view(0, state.views.storage)

return matext.new {
	id = ctx.id,
	instance_size = rounded_rect.instance_size,
	inst_buffer = inst_buffer,
	bindings = bindings,
	uniform = state.uniform,
	sr_buffer = state.srbuffer_mem,
	hooks = rounded_rect.hooks,
	label = "miru-test-rounded-rect-pipeline",
}
