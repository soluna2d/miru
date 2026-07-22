local miru = require "miru"

local args = ...

local function option_button(option, width)
	miru.mount("button", {
		width = width,
		height = 34,
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
	local palette = miru.use "palette"
	local width = args.width or 280
	local open = args.open == true
	local options = args.options or {}
	local menu_height = #options == 0 and 16 or 10 + #options * 40

	miru.dismissable(open and {
		on_dismiss = args.on_close,
	} or nil)
	miru.vbox({
		width = width,
		gap = 8,
	}, function()
		miru.mount("button", {
			width = width,
			height = 40,
			label = args.value or "Select",
			right_icon = open and "chevron_up" or "chevron_down",
			on_click = args.on_toggle,
		})
		miru.transition({
			show = open,
			width = width,
			height = menu_height,
			translateY = 0,
			overflow = "hidden",
			enter_from = {
				height = 0,
				translateY = -8,
			},
			leave_to = {
				height = 0,
				translateY = -8,
			},
			duration = 0.18,
			easing = "out_cubic",
		}, function()
			miru.vbox({
				width = width,
				height = menu_height,
				padding = 8,
				gap = 6,
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
				for _, option in ipairs(options) do
					option_button(option, width - 16)
				end
			end)
		end)
	end)
end
