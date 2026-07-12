local matmask = require "soluna.material.mask"
local matquad = require "soluna.material.quad"
local soluna = require "soluna"

local M = {}

local floor <const> = math.floor
local max <const> = math.max
local min <const> = math.min
local sqrt <const> = math.sqrt

local sprites = {}
local masks = {}

local function alpha_byte(distance)
	local alpha = min(max(0.5 - distance, 0), 1)
	return string.char(floor(alpha * 255 + 0.5))
end

local function circle_rgba(radius)
	local diameter = radius * 2
	local rows = {}
	for y = 0, diameter - 1 do
		local row = {}
		for x = 0, diameter - 1 do
			local dx = x + 0.5 - radius
			local dy = y + 0.5 - radius
			local distance = sqrt(dx * dx + dy * dy) - radius
			row[x + 1] = "\255\255\255" .. alpha_byte(distance)
		end
		rows[y + 1] = table.concat(row)
	end
	return table.concat(rows)
end

local function corner_sprites(radius)
	local cached = sprites[radius]
	if cached then
		return cached
	end
	local filename = "@miru_round_" .. tostring(radius)
	soluna.preload {
		filename = filename,
		content = circle_rgba(radius),
		w = radius * 2,
		h = radius * 2,
	}
	cached = soluna.load_sprites {
		{ name = "top_left", filename = filename, cx = 0, cy = 0, cw = radius, ch = radius },
		{ name = "top_right", filename = filename, cx = radius, cy = 0, cw = radius, ch = radius },
		{ name = "bottom_left", filename = filename, cx = 0, cy = radius, cw = radius, ch = radius },
		{ name = "bottom_right", filename = filename, cx = radius, cy = radius, cw = radius, ch = radius },
	}
	sprites[radius] = cached
	return cached
end

local function mask(sprite, color)
	local key = tostring(sprite) .. ":" .. string.format("%08x", color)
	local material = masks[key]
	if not material then
		material = matmask.mask(sprite, color)
		masks[key] = material
	end
	return material
end

local function add_quad(batch, width, height, color, x, y)
	if width > 0 and height > 0 then
		batch:add(matquad.quad(width, height, color), x, y)
	end
end

local function add_fill(batch, width, height, radius, color, x, y)
	radius = floor(min(max(radius, 0), width / 2, height / 2))
	if radius <= 0 then
		add_quad(batch, width, height, color, x, y)
		return
	end
	local corners = corner_sprites(radius)
	add_quad(batch, width - radius * 2, height, color, x + radius, y)
	add_quad(batch, width, height - radius * 2, color, x, y + radius)
	batch:add(mask(corners.top_left, color), x, y)
	batch:add(mask(corners.top_right, color), x + width - radius, y)
	batch:add(mask(corners.bottom_left, color), x, y + height - radius)
	batch:add(mask(corners.bottom_right, color), x + width - radius, y + height - radius)
end

function M.draw(batch, width, height, options)
	width = floor(width + 0.5)
	height = floor(height + 0.5)
	if width <= 0 or height <= 0 then
		return
	end
	local radius = options.radius or 0
	local fill = options.fill
	local border_width = floor((options.border_width or 0) + 0.5)
	if border_width <= 0 then
		add_fill(batch, width, height, radius, fill, 0, 0)
		return
	end
	add_fill(batch, width, height, radius, options.border or fill, 0, 0)
	local inner_width = width - border_width * 2
	local inner_height = height - border_width * 2
	if inner_width > 0 and inner_height > 0 then
		add_fill(batch, inner_width, inner_height, max(0, radius - border_width), fill, border_width, border_width)
	end
end

return M
