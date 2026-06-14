local miru = require "miru"

local args = ...

local ROLE_COLOR <const> = {
	user = 0xff0f766e,
	assistant = 0xff7c3aed,
	system = 0xff475569,
}

local ROLE_FILL <const> = {
	user = 0xffecfdf5,
	assistant = 0xfffaf5ff,
	system = 0xfff8fafc,
}

local function Surface(fill)
	miru.mount("surface", {
		position = "absolute",
		left = 0,
		top = 0,
		width = "100%",
		height = "100%",
		fill = fill,
		radius = 12,
		border_color = 0xffcbd5e1,
		border_width = 1,
	})
end

local function RoleDot(color)
	miru.box({
		width = 8,
		height = 8,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = color,
			radius = 4,
		})
	end)
end

return function()
	local role = args.role or "assistant"
	local width = args.width or 520
	local role_color = ROLE_COLOR[role] or ROLE_COLOR.system
	local role_fill = ROLE_FILL[role] or 0xffffffff
	miru.vbox({
		width = width,
		padding = 16,
		gap = 10,
	}, function()
		Surface(role_fill)
		miru.hbox({
			width = width - 32,
			height = 22,
			alignItems = "center",
			gap = 8,
		}, function()
			RoleDot(role_color)
			miru.text(args.title or role, {
				width = width - 48,
				height = 22,
				size = 13,
				color = role_color,
				align = "LV",
			})
		end)
		miru.text(args.body or "", {
			width = width - 32,
			size = args.size or 15,
			color = 0xff1f2937,
			align = "LT",
		})
	end)
end
