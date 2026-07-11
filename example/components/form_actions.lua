local miru = require "miru"

local args = ...

return function()
	local palette = miru.use "palette"
	local width = args.width or 520
	local height = args.height or 42

	miru.hbox({
		width = width,
		height = height,
		alignItems = "center",
		gap = 10,
	}, function()
		miru.box({
			flex = 1,
			height = "100%",
		}, function()
			miru.text(args.status or "", {
				width = "100%",
				height = "100%",
				size = 12,
				color = palette.muted,
				align = "LV",
			})
		end)
		miru.mount("button", {
			width = args.button_width or 88,
			height = height,
			label = args.cancel_label or "Cancel",
			on_click = args.on_cancel,
		})
		miru.mount("button", {
			width = args.button_width or 88,
			height = height,
			kind = "primary",
			label = args.save_label or "Save",
			on_click = args.on_save,
		})
	end)
end
