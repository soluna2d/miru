local app = require "soluna.app"
local copy = require "example.copy"
local font = require "example.font"
local matclip = require "soluna.material.clip"
local matquad = require "soluna.material.quad"
local miru = require "miru"
local text_editor = require "example.text_editor"

local args = ...

local CURSOR_WIDTH <const> = 2
local CURSOR_BLINK_FRAMES <const> = 30
local TEXT_INSET_X <const> = 12
local TEXT_HEIGHT <const> = 20
local TEXT_SIZE <const> = 15
local LAYOUT_WIDTH <const> = 65536
local MOUSE_LEFT <const> = 0
---@type MiruCursor
---@diagnostic disable-next-line: assign-type-mismatch
local TEXT_CURSOR <const> = "ibeam"

local floor <const> = math.floor
local max <const> = math.max
local min <const> = math.min

local editor = text_editor.new(args.value or "")
local focused = miru.focused()
local text_ref = miru.ref()
local selecting = false
local scroll_x = 0
local last_prop_value = args.value or ""
local render_state = editor:state()
local state_value = miru.value(render_state)
local current_palette

local function publish()
	state_value(editor:state())
end

local function sync_external_value()
	local value = args.value or ""
	if value == last_prop_value then
		return
	end
	last_prop_value = value
	if value ~= editor.text then
		editor:set_text(value)
		scroll_x = 0
		publish()
	end
end

local function changed(before)
	if editor.text == before then
		publish()
		return
	end
	last_prop_value = editor.text
	if args.on_change then
		args.on_change(editor.text)
	end
	publish()
end

local function clipboard(text)
	app.set_clipboard_text(text or "")
end

local function text_layout(value, color, height)
	return font.layout(value, TEXT_SIZE, color, "LV", LAYOUT_WIDTH, height)
end

local function cursor_x(query, position)
	local x = query:cursor(position)
	return x or 0
end

local function content_width(query)
	return cursor_x(query, query:cursor_count() - 1)
end

local function sync_scroll(query, viewport_width, state)
	local maximum = max(0, content_width(query) - viewport_width)
	scroll_x = min(max(scroll_x, 0), maximum)
	if state.focused then
		local x = cursor_x(query, state.cursor)
		if x < scroll_x then
			scroll_x = x
		elseif x + CURSOR_WIDTH > scroll_x + viewport_width then
			scroll_x = x + CURSOR_WIDTH - viewport_width
		end
	end
	scroll_x = min(max(scroll_x, 0), maximum)
end

local function selection_range(state)
	local anchor = state.selection_anchor
	local focus = state.selection_focus
	if anchor == nil or focus == nil or anchor == focus then
		return nil
	end
	return min(anchor, focus), max(anchor, focus)
end

local function position_at(event)
	local rect = text_ref:rect()
	if not rect then
		return 0
	end
	local palette = assert(current_palette)
	local _, query = text_layout(editor.text, palette.text, rect.h)
	local x = (event.x or 0) - rect.x + scroll_x
	local position = query:hit_test(x, rect.h / 2)
	return position
end

local function handle_focus()
	if editor:set_focused(true) then
		publish()
	end
end

local function handle_blur()
	selecting = false
	app.set_ime_rect(nil)
	if editor:set_focused(false) then
		publish()
	end
end

local function handle_pointer_down(event)
	if event.button ~= MOUSE_LEFT then
		return
	end
	local rect = text_ref:rect()
	if not rect then
		return
	end
	local x = event.x or 0
	local y = event.y or 0
	if x < rect.x or x > rect.x + rect.w or y < rect.y or y > rect.y + rect.h then
		return
	end
	editor:begin_selection(position_at(event))
	selecting = true
	publish()
end

local function handle_pointer_move(event)
	if not selecting then
		return
	end
	editor:update_selection(position_at(event))
	publish()
end

local function handle_pointer_up(event)
	if event.button ~= MOUSE_LEFT or not selecting then
		return
	end
	selecting = false
	editor:finish_selection()
	publish()
end

local function handle_char(event)
	local before = editor.text
	local handled, did_change = editor:char(event.char or event.codepoint, event.modifiers, clipboard)
	if not handled then
		return
	end
	if did_change then
		changed(before)
	else
		publish()
	end
end

local function handle_key(event)
	local before = editor.text
	local handled, did_change = editor:key(event.keycode, event.state, event.modifiers, clipboard)
	if not handled then
		return
	end
	if did_change then
		changed(before)
	else
		publish()
	end
end

local function handle_clipboard_pasted(event)
	local before = editor.text
	if editor:insert(event.text) then
		changed(before)
	end
end

local function draw_text(width, height, frame)
	local palette = miru.use "palette"
	local state = render_state
	local value = state.text
	local display = value ~= "" and value or (args.placeholder or "")
	local color = value ~= "" and palette.text or 0xff8d9a96
	local stream, query = text_layout(display, color, height)

	if value ~= "" then
		sync_scroll(query, width, state)
	else
		scroll_x = 0
	end

	miru.batch:add(matclip.rect(width, height), 0, 0)
	local start, finish = selection_range(state)
	if value ~= "" and start then
		local x1 = cursor_x(query, start) - scroll_x
		local x2 = cursor_x(query, finish) - scroll_x
		local left = max(0, min(x1, x2))
		local right = min(width, max(x1, x2))
		if right > left then
			miru.batch:add(matquad.quad(floor(right - left + 0.5), max(1, height - 4), 0xffaee5dc), left, 2)
		end
	end
	miru.batch:add(stream, -scroll_x, 0)

	if state.focused then
		local x, y, _, cursor_height = query:cursor(state.cursor)
		x = (x or 0) - scroll_x
		y = y or 1
		cursor_height = min(cursor_height or height - 2, height - y)
		local rect = text_ref:window_rect()
		if rect then
			app.set_ime_font(font.name(), TEXT_SIZE)
			app.set_ime_rect {
				x = rect.x + x,
				y = rect.y + y,
				width = CURSOR_WIDTH,
				height = cursor_height,
				text_color = palette.text,
			}
		end
		if not start and (frame == nil or (frame // CURSOR_BLINK_FRAMES) % 2 == 0) then
			miru.batch:add(matquad.quad(CURSOR_WIDTH, max(1, cursor_height), palette.text), x, y)
		end
	end
	miru.batch:add(matclip.rect())
end

return function()
	sync_external_value()
	local palette = miru.use "palette"
	current_palette = palette
	local focused_now = focused() or false
	if editor.focused ~= focused_now then
		editor:set_focused(focused_now)
	end
	state_value()
	render_state = editor:state()
	local width = args.width or 420

	miru.focusable {
		on_focus = handle_focus,
		on_blur = handle_blur,
		on_char = handle_char,
		on_key = handle_key,
		on_clipboard_pasted = handle_clipboard_pasted,
	}
	miru.clickable {
		cursor = TEXT_CURSOR,
		on_pointer_down = handle_pointer_down,
		on_pointer_move = handle_pointer_move,
		on_pointer_up = handle_pointer_up,
	}
	miru.vbox({
		width = width,
		gap = 8,
	}, function()
		miru.text(copy.group(args.label), {
			width = width,
			height = 18,
			style = "label",
			color = palette.muted,
		})
		miru.hbox({
			width = width,
			height = 44,
			padding = TEXT_INSET_X,
			alignItems = "center",
		}, function()
			miru.mount("surface", {
				position = "absolute",
				left = 0,
				top = 0,
				width = "100%",
				height = "100%",
				radius = 6,
				fill = focused_now and palette.primary_soft or palette.surface,
				border_color = focused_now and palette.primary or palette.line,
				border_width = focused_now and 2 or 1,
			})
			miru.box({
				ref = text_ref,
				width = width - TEXT_INSET_X * 2,
				height = TEXT_HEIGHT,
				overflow = "hidden",
			}, function()
				miru.canvas({
					width = "100%",
					height = "100%",
					live = focused_now,
				}, draw_text)
			end)
		end)
	end)
end
