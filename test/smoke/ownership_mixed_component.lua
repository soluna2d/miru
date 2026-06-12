local miru = require "miru"

local args = ...

local title = miru.signal "First"
local target = miru.signal(10)
local canvas_cleanups = 0
local range_cleanups = 0

local animation = miru.animated(function()
	return target()
end)

if args.bind then
	args.bind {
		title = title,
		target = target,
		animation = animation,
		canvas_cleanups = function()
			return canvas_cleanups
		end,
		range_cleanups = function()
			return range_cleanups
		end,
	}
end

return function()
	miru.vbox({
		width = 160,
		height = 80,
	}, function()
		miru.text(title, {
			width = 160,
			height = 24,
		})
		miru.canvas({
			width = 160,
			height = 24,
		}, function()
			miru.cleanup(function()
				canvas_cleanups = canvas_cleanups + 1
			end)
		end)
		miru.transition({
			show = true,
			duration = 0,
		}, function()
			miru.cleanup(function()
				range_cleanups = range_cleanups + 1
			end)
			miru.box {
				width = 160,
				height = 24,
			}
		end)
	end)
end
