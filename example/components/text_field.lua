local miru = require "miru"

local args = ...
---@type MiruCursor
---@diagnostic disable-next-line: assign-type-mismatch
local TEXT_CURSOR <const> = "ibeam"

return function()
	local palette = miru.use "palette"
	local focused = miru.focused()()
	local width = args.width or 420
	local value = args.value or ""

	miru.focusable {
		on_char = function(event)
			if event.codepoint and event.codepoint >= 32 and args.on_char then
				args.on_char(event.codepoint)
			end
		end,
		on_key = function(event)
			if event.keycode == 259 and (event.state == 1 or event.state == 2) and args.on_backspace then
				args.on_backspace()
			end
		end,
		on_clipboard_pasted = function(event)
			if event.text and args.on_paste then
				args.on_paste(event.text)
			end
		end,
	}
	miru.clickable {
		cursor = TEXT_CURSOR,
	}
	miru.vbox({
		width = width,
		gap = 8,
	}, function()
		miru.text(args.label or "", {
			width = width,
			height = 18,
			style = "label",
			color = palette.muted,
		})
		miru.hbox({
			width = width,
			height = 44,
			padding = 12,
			alignItems = "center",
		}, function()
			miru.mount("surface", {
				position = "absolute",
				left = 0,
				top = 0,
				width = "100%",
				height = "100%",
				fill = focused and palette.primary_soft or palette.surface,
				border_color = focused and palette.primary or palette.line,
				border_width = focused and 2 or 1,
			})
			miru.text(value ~= "" and value or args.placeholder or "", {
				width = width - 24,
				height = 20,
				size = 15,
				color = value ~= "" and palette.text or 0xff8d9a96,
				align = "LV",
			})
		end)
	end)
end
