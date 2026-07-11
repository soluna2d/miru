local miru = require "miru"

local args = ...
local text_ref = miru.ref()

args.report.ref = text_ref

return function()
	miru.vbox({
		width = args.width,
	}, function()
		miru.text(args.text, {
			ref = text_ref,
			line_height = 20,
		})
	end)
end
