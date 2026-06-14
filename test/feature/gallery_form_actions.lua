local miru = require "miru"

local args = ...

return function()
	local width = args.width or 520
	local height = args.height or 40
	miru.hbox({
		width = width,
		height = height,
		alignItems = "center",
		gap = 12,
	}, function()
		miru.box({
			flex = 1,
			height = "100%",
		}, function()
			if args.status then
				miru.text(args.status, {
					width = "100%",
					height = "100%",
					size = 12,
					color = 0xffb91c1c,
					align = "LV",
				})
			end
		end)
		miru.mount("gallery_button", {
			width = 96,
			height = height,
			label = args.cancel_label or "Cancel",
			active = false,
			on_click = args.on_cancel,
		})
		miru.mount("gallery_button", {
			width = 96,
			height = height,
			kind = "primary",
			label = args.save_label or "Save",
			on_click = args.on_save,
		})
	end)
end
