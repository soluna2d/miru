local miru = require "miru"

local args = ...

miru.clickable {
	enabled = args.enabled,
	on_click = args.on_click,
}
miru.focusable {
	enabled = args.enabled,
	on_char = args.on_char,
}
miru.scrollable {
	enabled = args.enabled,
	on_scroll = args.on_scroll,
}

return function()
	miru.box {
		width = args.width,
		height = args.height,
		background = 0xffffffff,
	}
end
