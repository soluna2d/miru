local file = require "soluna.file"
local font = require "soluna.font"
local soluna = require "soluna"

local loaded

local function load()
	if loaded then
		return loaded
	end

	local path
	if soluna.platform == "wasm" then
		path = "asset/font/SourceHanSansSC-Regular.ttf"
	else
		path = "soluna/website/public/fonts/SourceHanSansSC-Regular.ttf"
	end

	font.import(assert(file.load(path), "missing example font: " .. path))
	loaded = {
		id = assert(font.name "Source Han Sans SC Regular"),
		cobj = font.cobj(),
	}
	return loaded
end

local M = {}

function M.styles()
	local source = load()
	return {
		font = source.cobj,
		default_font = source.id,
		default = "body",
		body = {
			font = source.id,
			size = 15,
			line_height = 21,
			color = 0xff14201d,
		},
		title = {
			based_on = "body",
			size = 28,
			line_height = 34,
		},
		label = {
			based_on = "body",
			size = 13,
			line_height = 18,
		},
		muted = {
			based_on = "body",
			size = 13,
			line_height = 18,
			color = 0xff5b6965,
		},
	}
end

return M
