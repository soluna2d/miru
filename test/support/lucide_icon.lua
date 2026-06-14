local soluna_icon = require "soluna.icon"
local richtext = require "soluna.text"
local text_engine = require "test.feature.text_engine"

richtext.init "test/asset/icons.dl"

local M = {}

function M.stream(name, size, color)
	local codepoint = assert(soluna_icon.names[name], "missing lucide icon: " .. tostring(name))
	return text_engine.icon(codepoint, size, color)
end

return M
