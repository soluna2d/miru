local font_loader = require "core.font"
local mattext = require "soluna.material.text"
local soluna_font = require "soluna.font"

local floor <const> = math.floor
local max <const> = math.max

local loaded = assert(font_loader.load())
local fontid = loaded.id
local fontcobj = soluna_font.cobj()

local M = {}

local function pixel(value)
	return floor((value or 0) + 0.5)
end

function M.styles()
	return {
		font = fontcobj,
		default_font = fontid,
		default = "body",
		body = {
			font = fontid,
			size = 15,
			line_height = 20,
			color = 0xff111827,
		},
		title = {
			based_on = "body",
			size = 22,
			line_height = 28,
		},
		muted = {
			based_on = "body",
			size = 13,
			line_height = 18,
			color = 0xff64748b,
		},
	}
end

function M.layout(args)
	local width = max(1, pixel(args.width or 1))
	local size = pixel(args.size or 15)
	local block, query = mattext.block(fontcobj, fontid, size, args.color or 0xff111827, args.align or "LT")
	local value = tostring(args.text or "")
	local stream = block(value, width)
	local metrics = query(value, width)
	return {
		stream = stream,
		width = width,
		height = metrics:height(),
		line_height = metrics:line_height(),
		line_count = metrics:line_count(),
		draw = function(self, batch, x, y)
			batch:add(self.stream, x or 0, y or 0)
		end,
	}
end

function M.icon(codepoint, size, color)
	local pixel_size = pixel(size or 15)
	local block = mattext.block(fontcobj, fontid, pixel_size, color or 0xff111827, "LT")
	return block("[i" .. tostring(codepoint) .. "]", pixel_size)
end

return M
