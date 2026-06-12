local M = {}

function M.app(args)
	return require "test.feature.showcase.app" (args)
end

return M
