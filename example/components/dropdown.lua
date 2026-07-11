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
	local open = args.open

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
			label = (args.value or "Select") .. (open and "  -" or "  +"),
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
					fill = palette.surface,
					border_color = palette.line,
					border_width = 1,
				})
				for _, option in ipairs(args.options or {}) do
					option_button(option, width - 16)
				end
			end)
		end
	end)
end
