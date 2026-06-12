local soluna = require "soluna"
local font = require "core.font"
local mattext = require "soluna.material.text"
local rounded_rect = require "test.material.rounded_rect_native"
local sfont = require "soluna.font"
local miru = require "miru"

return function(args)
	soluna.set_window_title "Miru Showcase Metrics"

	local view = miru.new {
		w = args.width,
		h = args.height,
	}
	local root = view:mount("test/feature/showcase/root", {
		width = args.width,
		height = args.height,
	})

	local callback = {}
	local batch = args.batch
	local fontid <const> = assert(font.load()).id
	local text_block <const> = mattext.block(sfont.cobj(), fontid, 14, 0xff374151, "LC")
	local render_count = -1
	local render_label

	local function draw_metrics()
		local stats = view:statistics()
		if stats.render_count ~= render_count then
			render_count = stats.render_count
			render_label = text_block("Component renders: " .. tostring(render_count), 220, 28)
		end
		batch:add(rounded_rect.rect {
			width = 244,
			height = 48,
			radius = 10,
			fill = 0xeeffffff,
			border = 0xffcbd5e1,
			border_width = 1,
		}, 32, 32)
		batch:add(render_label, 44, 42)
	end

	function callback.window_resize(w, h)
		view:resize(w, h)
		root.args.width = w
		root.args.height = h
	end

	function callback.mouse_move(x, y)
		view:pointer(x, y)
	end

	function callback.mouse_button(button, state)
		view:mouse_button(button, state)
	end

	function callback.frame()
		view:update(1 / 60)
		view:draw(batch)
		draw_metrics()
	end

	return callback
end
