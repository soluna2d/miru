local miru = require "miru"

local args = ...

return function()
	local focused = args.focused == true
	local width = args.width or 360
	local value = args.value or ""
	miru.vbox({
		width = width,
		gap = 8,
	}, function()
		miru.text(args.label or "", {
			width = width,
			height = 18,
			size = 13,
			color = 0xff475569,
			align = "LT",
		})
		miru.clickable {
			on_click = args.on_focus,
		}
		miru.hbox({
			width = width,
			height = 42,
			padding = 12,
			alignItems = "center",
		}, function()
			miru.mount("surface", {
				position = "absolute",
				left = 0,
				top = 0,
				width = "100%",
				height = "100%",
				fill = focused and 0xffeff6ff or 0xffffffff,
				radius = 8,
				border_color = focused and 0xff38bdf8 or 0xffcbd5e1,
				border_width = focused and 2 or 1,
			})
			miru.text(value ~= "" and value or args.placeholder or "", {
				width = width - 24,
				height = 18,
				size = 15,
				color = value ~= "" and 0xff111827 or 0xff94a3b8,
				align = "LV",
			})
		end)
	end)
end
