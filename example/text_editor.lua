local M = {}

local KEY_A <const> = 65
local KEY_C <const> = 67
local KEY_V <const> = 86
local KEY_X <const> = 88
local KEY_Y <const> = 89
local KEY_Z <const> = 90
local KEY_BACKSPACE <const> = 259
local KEY_DELETE <const> = 261
local KEY_RIGHT <const> = 262
local KEY_LEFT <const> = 263
local KEY_HOME <const> = 268
local KEY_END <const> = 269
local KEYSTATE_PRESS <const> = 1
local KEYSTATE_REPEAT <const> = 2
local MODIFIER_SHIFT <const> = 0x1
local MODIFIER_CTRL <const> = 0x2
local MODIFIER_ALT <const> = 0x4
local MODIFIER_SUPER <const> = 0x8
local CHAR_BACKSPACE <const> = 8
local HISTORY_LIMIT <const> = 100

local min <const> = math.min
local max <const> = math.max
local remove <const> = table.remove

local Editor = {}
Editor.__index = Editor

local function text_len(text)
	return utf8.len(text or "") or 0
end

local function clamp_position(text, position)
	return min(max(position or text_len(text), 0), text_len(text))
end

local function byte_offset(text, position)
	if position <= 0 then
		return 1
	end
	if position >= text_len(text) then
		return #text + 1
	end
	return utf8.offset(text, position + 1) or (#text + 1)
end

local function codepoint_at(text, position)
	local offset = byte_offset(text, position)
	if offset > #text then
		return nil
	end
	return utf8.codepoint(text, offset, offset)
end

local function character_class(codepoint)
	if not codepoint then
		return nil
	end
	if codepoint == 32 or codepoint == 9 or codepoint == 10 or codepoint == 13 then
		return "space"
	end
	if (codepoint >= 48 and codepoint <= 57)
		or (codepoint >= 65 and codepoint <= 90)
		or (codepoint >= 97 and codepoint <= 122)
		or codepoint == 95
	then
		return "word"
	end
	return "other"
end

local function previous_word_position(text, position)
	position = clamp_position(text, position)
	while position > 0 and character_class(codepoint_at(text, position - 1)) == "space" do
		position = position - 1
	end
	local class = character_class(codepoint_at(text, position - 1))
	while position > 0 and character_class(codepoint_at(text, position - 1)) == class do
		position = position - 1
	end
	return position
end

local function next_word_position(text, position)
	local length = text_len(text)
	position = clamp_position(text, position)
	local class = character_class(codepoint_at(text, position))
	while position < length and character_class(codepoint_at(text, position)) == class do
		position = position + 1
	end
	while position < length and character_class(codepoint_at(text, position)) == "space" do
		position = position + 1
	end
	return position
end

local function selection_range(editor)
	local anchor = editor.selection_anchor
	local focus = editor.selection_focus
	if anchor == nil or focus == nil or anchor == focus then
		return nil
	end
	return min(anchor, focus), max(anchor, focus)
end

local function clear_selection(editor)
	editor.selection_anchor = nil
	editor.selection_focus = nil
end

local function clear_input_markers(editor)
	editor.suppressed_control = nil
end

local function snapshot(editor)
	return {
		text = editor.text,
		cursor = editor.cursor,
		selection_anchor = editor.selection_anchor,
		selection_focus = editor.selection_focus,
	}
end

local function restore(editor, value)
	editor.text = value.text
	editor.cursor = clamp_position(editor.text, value.cursor)
	editor.selection_anchor = value.selection_anchor
	editor.selection_focus = value.selection_focus
	clear_input_markers(editor)
end

local function push_snapshot(stack, value)
	local previous = stack[#stack]
	if previous
		and previous.text == value.text
		and previous.cursor == value.cursor
		and previous.selection_anchor == value.selection_anchor
		and previous.selection_focus == value.selection_focus
	then
		return
	end
	stack[#stack + 1] = value
	if #stack > HISTORY_LIMIT then
		remove(stack, 1)
	end
end

local function record_undo(editor)
	push_snapshot(editor.undo, snapshot(editor))
	editor.redo = {}
end

local function delete_selection(editor)
	local start, finish = selection_range(editor)
	if not start then
		return false
	end
	record_undo(editor)
	editor.text = editor.text:sub(1, byte_offset(editor.text, start) - 1)
		.. editor.text:sub(byte_offset(editor.text, finish))
	editor.cursor = start
	clear_selection(editor)
	clear_input_markers(editor)
	return true
end

local function set_cursor(editor, position, select)
	local start, finish = selection_range(editor)
	if not select and start then
		if position < editor.cursor then
			position = start
		else
			position = finish
		end
	end
	position = clamp_position(editor.text, position)
	if select then
		if editor.selection_anchor == nil then
			editor.selection_anchor = editor.cursor
		end
		editor.selection_focus = position
	else
		clear_selection(editor)
	end
	editor.cursor = position
	clear_input_markers(editor)
	return true
end

local function command_modifier(modifiers)
	return (modifiers & (MODIFIER_CTRL | MODIFIER_SUPER)) ~= 0
end

local function word_modifier(modifiers)
	return (modifiers & (MODIFIER_ALT | MODIFIER_CTRL)) ~= 0
end

local function shift_modifier(modifiers)
	return (modifiers & MODIFIER_SHIFT) ~= 0
end

local function command_key_from_char(value)
	local codepoint = type(value) == "number" and value or utf8.codepoint(value or "", 1, 1)
	if not codepoint then
		return nil
	end
	local controls = {
		[1] = KEY_A,
		[3] = KEY_C,
		[22] = KEY_V,
		[24] = KEY_X,
		[25] = KEY_Y,
		[26] = KEY_Z,
	}
	if controls[codepoint] then
		return controls[codepoint]
	end
	if codepoint >= 97 and codepoint <= 122 then
		return codepoint - 32
	end
	return codepoint
end

function M.new(text)
	text = text or ""
	return setmetatable({
		text = text,
		cursor = text_len(text),
		focused = false,
		undo = {},
		redo = {},
	}, Editor)
end

function Editor:state()
	local value = snapshot(self)
	value.focused = self.focused
	return value
end

function Editor:set_text(text)
	self.text = text or ""
	self.cursor = text_len(self.text)
	clear_selection(self)
	clear_input_markers(self)
	self.undo = {}
	self.redo = {}
end

function Editor:set_focused(focused)
	focused = not not focused
	if self.focused == focused then
		return false
	end
	self.focused = focused
	clear_input_markers(self)
	if not focused then
		clear_selection(self)
	end
	return true
end

function Editor:selection()
	return selection_range(self)
end

function Editor:selected_text()
	local start, finish = selection_range(self)
	if not start then
		return nil
	end
	return self.text:sub(byte_offset(self.text, start), byte_offset(self.text, finish) - 1)
end

function Editor:select_all()
	local length = text_len(self.text)
	if length == 0 then
		clear_selection(self)
		return false
	end
	self.selection_anchor = 0
	self.selection_focus = length
	self.cursor = length
	clear_input_markers(self)
	return true
end

function Editor:insert(text)
	text = (text or ""):gsub("[\r\n]+", " ")
	if text == "" then
		return false
	end
	record_undo(self)
	local start, finish = selection_range(self)
	local position = self.cursor
	if start then
		self.text = self.text:sub(1, byte_offset(self.text, start) - 1)
			.. text .. self.text:sub(byte_offset(self.text, finish))
		position = start
	else
		self.text = self.text:sub(1, byte_offset(self.text, position) - 1)
			.. text .. self.text:sub(byte_offset(self.text, position))
	end
	self.cursor = position + text_len(text)
	clear_selection(self)
	clear_input_markers(self)
	return true
end

function Editor:backspace(word)
	if delete_selection(self) then
		return true
	end
	if self.cursor <= 0 then
		return false
	end
	local start = word and previous_word_position(self.text, self.cursor) or self.cursor - 1
	record_undo(self)
	self.text = self.text:sub(1, byte_offset(self.text, start) - 1)
		.. self.text:sub(byte_offset(self.text, self.cursor))
	self.cursor = start
	return true
end

function Editor:delete_forward(word)
	if delete_selection(self) then
		return true
	end
	local length = text_len(self.text)
	if self.cursor >= length then
		return false
	end
	local finish = word and next_word_position(self.text, self.cursor) or self.cursor + 1
	record_undo(self)
	self.text = self.text:sub(1, byte_offset(self.text, self.cursor) - 1)
		.. self.text:sub(byte_offset(self.text, finish))
	return true
end

function Editor:begin_selection(position)
	position = clamp_position(self.text, position)
	self.cursor = position
	self.selection_anchor = position
	self.selection_focus = position
	clear_input_markers(self)
	return true
end

function Editor:update_selection(position)
	position = clamp_position(self.text, position)
	self.cursor = position
	self.selection_focus = position
	return true
end

function Editor:finish_selection()
	if self.selection_anchor == self.selection_focus then
		clear_selection(self)
	end
	return true
end

function Editor:undo_change()
	local value = remove(self.undo)
	if not value then
		return false
	end
	push_snapshot(self.redo, snapshot(self))
	restore(self, value)
	return true
end

function Editor:redo_change()
	local value = remove(self.redo)
	if not value then
		return false
	end
	push_snapshot(self.undo, snapshot(self))
	restore(self, value)
	return true
end

function Editor:handle_command(keycode, modifiers, clipboard)
	if keycode == KEY_A then
		self:select_all()
		return true, false
	elseif keycode == KEY_C then
		clipboard(self:selected_text() or "")
		return true, false
	elseif keycode == KEY_X then
		local selected = self:selected_text()
		if selected then
			clipboard(selected)
			return true, self:backspace()
		end
		return true, false
	elseif keycode == KEY_V then
		return true, false
	elseif keycode == KEY_Z then
		if shift_modifier(modifiers or 0) then
			return true, self:redo_change()
		end
		return true, self:undo_change()
	elseif keycode == KEY_Y then
		return true, self:redo_change()
	end
	return false, false
end

function Editor:char(value, modifiers, clipboard)
	if not self.focused then
		return false, false
	end
	modifiers = modifiers or 0
	if command_modifier(modifiers) then
		return self:handle_command(command_key_from_char(value), modifiers, clipboard)
	end
	local codepoint = type(value) == "number" and value or utf8.codepoint(value or "", 1, 1)
	if not codepoint then
		return false, false
	end
	if codepoint == CHAR_BACKSPACE then
		if self.suppressed_control == codepoint then
			self.suppressed_control = nil
			return true, false
		end
		return true, self:backspace(word_modifier(modifiers))
	end
	if codepoint < 32 or (codepoint >= 127 and codepoint <= 159) then
		return false, false
	end
	local text = type(value) == "number" and utf8.char(value) or value
	return true, self:insert(text)
end

function Editor:key(keycode, state, modifiers, clipboard)
	if not self.focused or (state ~= KEYSTATE_PRESS and state ~= KEYSTATE_REPEAT) then
		return false, false
	end
	modifiers = modifiers or 0
	if command_modifier(modifiers) then
		local handled, changed = self:handle_command(keycode, modifiers, clipboard)
		if handled then
			return handled, changed
		end
		if (modifiers & MODIFIER_SUPER) ~= 0 and keycode == KEY_LEFT then
			return true, set_cursor(self, 0, shift_modifier(modifiers)) and false
		elseif (modifiers & MODIFIER_SUPER) ~= 0 and keycode == KEY_RIGHT then
			return true, set_cursor(self, text_len(self.text), shift_modifier(modifiers)) and false
		end
	end
	local select = shift_modifier(modifiers)
	local by_word = word_modifier(modifiers)
	if keycode == KEY_BACKSPACE then
		local changed = self:backspace(by_word)
		self.suppressed_control = CHAR_BACKSPACE
		return true, changed
	elseif keycode == KEY_DELETE then
		return true, self:delete_forward(by_word)
	elseif keycode == KEY_LEFT then
		local position = by_word and previous_word_position(self.text, self.cursor) or self.cursor - 1
		set_cursor(self, position, select)
		return true, false
	elseif keycode == KEY_RIGHT then
		local position = by_word and next_word_position(self.text, self.cursor) or self.cursor + 1
		set_cursor(self, position, select)
		return true, false
	elseif keycode == KEY_HOME then
		set_cursor(self, 0, select)
		return true, false
	elseif keycode == KEY_END then
		set_cursor(self, text_len(self.text), select)
		return true, false
	end
	return false, false
end

return M
