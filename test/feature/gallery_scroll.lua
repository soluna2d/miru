local miru = require "miru"

local args = ...

return function()
	local width = args.width or 360
	local height = args.height or 132
	local offset = args.offset or 0

	miru.scrollable {
		on_scroll = function(event)
			if args.on_scroll then
				args.on_scroll(event.scroll_y)
			end
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
			fill = 0xffffffff,
			radius = 10,
			border_color = 0xffcbd5e1,
			border_width = 1,
		})
		miru.vbox({
			position = "absolute",
			left = 12,
			top = 12 - offset,
			width = width - 24,
			gap = 8,
		}, function()
			for i = 1, 8 do
				miru.text("Scrollable row " .. tostring(i), {
					width = width - 24,
					height = 24,
					size = 14,
					color = i % 2 == 0 and 0xff0f766e or 0xff334155,
					align = "LV",
				})
			end
		end)
	end)
end
