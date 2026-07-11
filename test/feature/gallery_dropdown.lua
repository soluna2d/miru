local miru = require "miru"

local args = ...

local function Option(option, width)
	miru.mount("gallery_button", {
		ref = args.option_refs and args.option_refs[option],
		width = width,
		height = 32,
		radius = 6,
		label = option,
		active = option == args.value,
		on_click = function()
			if args.on_select then
				args.on_select(option)
			end
		end,
	})
end

return function()
	local width = args.width or 260
	local open = args.open
	miru.dismissable(open and {
		on_dismiss = args.on_close,
	} or nil)
	miru.vbox({
		width = width,
		gap = 8,
	}, function()
		miru.mount("gallery_button", {
			ref = args.trigger_ref,
			width = width,
			height = 38,
			label = args.value or "Select",
			icon_right = "chevron_down",
			icon_right_angle = open and math.pi or 0,
			on_click = args.on_toggle,
		})
		if open then
			miru.vbox({
				width = width,
				padding = 8,
				gap = 6,
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
				local options = args.options or {}
				for i = 1, #options do
					Option(options[i], width - 16)
				end
			end)
		end
	end)
end
