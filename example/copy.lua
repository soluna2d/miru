local M = {}

local function value_text(value)
	if value == nil then
		return ""
	end
	return tostring(value)
end

function M.group(value)
	local text = value_text(value)
	if text == "" then
		return text
	end
	return "[w1]" .. text .. "[w]"
end

function M.words(value)
	local group_id = 0
	return (value_text(value):gsub("%S+", function(word)
		group_id = group_id + 1
		return "[w" .. tostring(group_id) .. "]" .. word .. "[w]"
	end))
end

return M
