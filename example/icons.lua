local font = require "example.font"
local miru = require "miru"

local floor <const> = math.floor

local initialized
local streams = {}

local function pixel(value)
	return floor((value or 0) + 0.5)
end

local function stream(name, size, color)
	local key = table.concat { name, ":", size, ":", color }
	local cached = streams[key]
	if cached then
		return cached
	end
	cached = font.icon(name, size, color)
	streams[key] = cached
	return cached
end

local M = {}

function M.init()
	if initialized then
		return
	end
	font.init_icons()
	initialized = true
end

function M.node(name, props)
	props = props or {}
	local size = pixel(props.size or 18)
	local width = props.width or size
	local height = props.height or size
	local color = props.color or 0xff14201d

	miru.canvas({
		width = width,
		height = height,
	}, function(measured_width, measured_height)
		local x = pixel((measured_width - size) * 0.5)
		local y = pixel((measured_height - size) * 0.5)
		miru.batch:add(stream(name, size, color), x, y)
	end)
end

return M
