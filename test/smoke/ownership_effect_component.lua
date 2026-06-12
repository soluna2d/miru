local miru = require "miru"

local args = ...

local source = miru.signal(0)
local effect_runs = 0
local cleanup_runs = 0

miru.effect(function()
	effect_runs = effect_runs + 1
	source()
end)

miru.cleanup(function()
	cleanup_runs = cleanup_runs + 1
end)

if args.bind then
	args.bind {
		source = source,
		effect_runs = function()
			return effect_runs
		end,
		cleanup_runs = function()
			return cleanup_runs
		end,
	}
end

return function()
	miru.box {
		width = 40,
		height = 24,
	}
end
