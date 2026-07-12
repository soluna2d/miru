local M = {}

local KEY_LEFT_SHIFT <const> = 340
local KEY_LEFT_CONTROL <const> = 341
local KEY_LEFT_ALT <const> = 342
local KEY_LEFT_SUPER <const> = 343
local KEY_RIGHT_SHIFT <const> = 344
local KEY_RIGHT_CONTROL <const> = 345
local KEY_RIGHT_ALT <const> = 346
local KEY_RIGHT_SUPER <const> = 347
local KEYSTATE_RELEASE <const> = 0
local MODIFIER_SHIFT <const> = 0x1
local MODIFIER_CTRL <const> = 0x2
local MODIFIER_ALT <const> = 0x4
local MODIFIER_SUPER <const> = 0x8

local MODIFIER_KEY <const> = {
	[KEY_LEFT_SHIFT] = "shift",
	[KEY_RIGHT_SHIFT] = "shift",
	[KEY_LEFT_CONTROL] = "ctrl",
	[KEY_RIGHT_CONTROL] = "ctrl",
	[KEY_LEFT_ALT] = "alt",
	[KEY_RIGHT_ALT] = "alt",
	[KEY_LEFT_SUPER] = "super",
	[KEY_RIGHT_SUPER] = "super",
}

local Device = {}
Device.__index = Device

function M.new()
	return setmetatable({}, Device)
end

function Device:update_modifiers(modifiers)
	self.shift = modifiers & MODIFIER_SHIFT ~= 0
	self.ctrl = modifiers & MODIFIER_CTRL ~= 0
	self.alt = modifiers & MODIFIER_ALT ~= 0
	self.super = modifiers & MODIFIER_SUPER ~= 0
end

function Device:modifiers()
	local modifiers = 0
	if self.shift then modifiers = modifiers | MODIFIER_SHIFT end
	if self.ctrl then modifiers = modifiers | MODIFIER_CTRL end
	if self.alt then modifiers = modifiers | MODIFIER_ALT end
	if self.super then modifiers = modifiers | MODIFIER_SUPER end
	return modifiers
end

function Device:key(keycode, state, modifiers)
	if modifiers ~= nil then
		self:update_modifiers(modifiers)
	end
	local field = MODIFIER_KEY[keycode]
	if field then
		self[field] = state ~= KEYSTATE_RELEASE
		return nil
	end
	return {
		keycode = keycode,
		state = state,
		modifiers = modifiers == nil and self:modifiers() or modifiers,
	}
end

function Device:char(value)
	return {
		char = value,
		codepoint = type(value) == "number" and value or nil,
		modifiers = self:modifiers(),
	}
end

return M
