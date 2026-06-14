local font_loader = require "core.font"
local mattext = require "soluna.material.text"
local sfont = require "soluna.font"

local floor = math.floor
local max = math.max

local loaded = assert(font_loader.load())
local fontid = loaded.id
local fontcobj = sfont.cobj()

local M = {}

local function px(value)
	value = value or 0
	return floor(value + 0.5)
end

function M.layout(args)
	local width = max(1, px(args.width or 1))
	local height = px(args.height)
	if height <= 0 then
		height = px(args.measure_height or 4096)
	end
	local size = px(args.size or 15)
	local color = args.color or 0xff111827
	local align = args.align or "LT"
	local block = mattext.block(fontcobj, fontid, size, color, align)
	local stream, measured_height = block(tostring(args.text or ""), width, height)
	return {
		stream = stream,
		width = width,
		height = measured_height,
		line_height = args.line_height or size,
		draw = function(self, batch, x, y)
			batch:add(self.stream, x or 0, y or 0)
		end,
	}
end

function M.icon(codepoint, size, color)
	local pixel_size = px(size or 15)
	local block = mattext.block(fontcobj, fontid, pixel_size, color or 0xff111827, "LT")
	local stream = block("[i" .. tostring(codepoint) .. "]", pixel_size, pixel_size)
	return stream
end

return M
