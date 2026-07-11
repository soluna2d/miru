local miru = require "miru"

local args = ...
local box_ref = miru.ref()

args.report.ref = box_ref

return function()
	args.report.hovered = miru.hovered()()
	args.report.pressed = miru.pressed()()
	args.report.focused = miru.focused()()
	miru.clickable {
		on_click = function()
			args.report.clicks = (args.report.clicks or 0) + 1
		end,
	}
	miru.focusable {
		on_blur = function()
			args.report.blur_count = (args.report.blur_count or 0) + 1
		end,
		on_char = function(event)
			args.report.codepoint = event.codepoint
		end,
		on_key = function(event)
			args.report.keycode = event.keycode
		end,
		on_clipboard_pasted = function(event)
			args.report.clipboard = event.text
		end,
	}
	miru.scrollable {
		on_scroll = function(event)
			args.report.scroll_y = event.scroll_y
		end,
	}
	miru.box({
		ref = box_ref,
		width = args.width,
		height = args.height,
		overflow = "hidden",
		background = 0xffffffff,
	}, function()
		miru.box {
			width = args.width * 2,
			height = args.height * 2,
			background = 0xffe2e8f0,
		}
	end)
end
