local rounded_rect = require "test.material.rounded_rect_native"

local M = {}

local function rect(overrides)
	local args = {
		width = 100,
		height = 40,
		radius = 8,
		fill = 0xffffffff,
	}
	for key, value in pairs(overrides or {}) do
		args[key] = value
	end
	return rounded_rect.rect(args)
end

function M.run()
	local plain = rect()
	local bordered = rect {
		border = 0xff000000,
		border_width = 1,
	}
	local same_color_border = rect {
		border = 0xffffffff,
		border_width = 1,
	}
	assert(#bordered == #plain * 2)
	assert(#same_color_border == #plain)
	assert(not pcall(rect, {
		width = 0 / 0,
	}))
	assert(not pcall(rect, {
		height = math.huge,
	}))
end

return M
