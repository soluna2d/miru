local miru = require "miru"

local args = ...

local ROLE_COLOR <const> = {
	user = 0xff087f73,
	assistant = 0xffd94b3d,
	system = 0xff5b6965,
}

local ROLE_FILL <const> = {
	user = 0xffe3f5f1,
	assistant = 0xffffebe7,
	system = 0xffedf1f0,
}

return function()
	local palette = miru.use "palette"
	local role = args.role or "assistant"
	local width = args.width or 520
	local role_color = ROLE_COLOR[role] or ROLE_COLOR.system
	local role_fill = ROLE_FILL[role] or palette.surface

	miru.vbox({
		width = width,
		padding = 14,
		gap = 9,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = role_fill,
			border_color = palette.line,
			border_width = 1,
		})
		miru.hbox({
			width = width - 28,
			height = 20,
			alignItems = "center",
			gap = 8,
		}, function()
			miru.box {
				width = 8,
				height = 8,
				background = role_color,
			}
			miru.text(args.title or role, {
				width = width - 44,
				height = 20,
				style = "label",
				color = role_color,
				align = "LV",
			})
		end)
		miru.text(args.body or "", {
			width = width - 28,
			size = args.size or 14,
			color = palette.text,
			align = "LT",
		})
	end)
end
