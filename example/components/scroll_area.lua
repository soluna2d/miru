local copy = require "example.copy"
local miru = require "miru"

local args = ...
local drag_y

return function()
	local palette = miru.use "palette"
	local width = args.width or 420
	local height = args.height or 144
	local offset = args.offset or 0

	miru.scrollable {
		on_scroll = function(event)
			if args.on_scroll then
				args.on_scroll(event.scroll_y)
			end
		end,
		on_pointer_down = function(event)
			drag_y = event.client_y
		end,
		on_pointer_move = function(event)
			if drag_y == nil then
				return
			end
			local delta = drag_y - event.client_y
			drag_y = event.client_y
			if delta ~= 0 and args.on_drag then
				args.on_drag(delta)
			end
		end,
		on_pointer_up = function()
			drag_y = nil
		end,
	}
	miru.box({
		width = width,
		height = height,
		overflow = "hidden",
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = palette.surface,
			border_color = palette.line,
			border_width = 1,
		})
		miru.vbox({
			position = "absolute",
			left = 12,
			top = 12 - offset,
			width = width - 24,
			gap = 7,
		}, function()
			for i = 1, 12 do
				miru.hbox({
					width = width - 24,
					height = 26,
					padding = 6,
					alignItems = "center",
				}, function()
					if i % 2 == 0 then
						miru.mount("surface", {
							position = "absolute",
							left = 0,
							top = 0,
							width = "100%",
							height = "100%",
							fill = palette.surface_alt,
						})
					end
					miru.text(copy.group("Virtual row " .. tostring(i)), {
						width = width - 36,
						height = 16,
						size = 13,
						color = i % 3 == 0 and palette.primary or palette.text,
						align = "LV",
					})
				end)
			end
		end)
	end)
end
