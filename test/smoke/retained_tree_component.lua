local miru = require "miru"

return function()
	miru.vbox({
		width = 200,
		alignItems = "flex-start",
	}, function()
		miru.box({
			key = "intrinsic",
			alignSelf = "flex-start",
		}, function()
			miru.box {
				width = 64,
				height = 28,
			}
		end)

		miru.box({
			key = "percent_parent",
			width = 120,
			height = 50,
		}, function()
			miru.box {
				key = "percent_child",
				width = "100%",
				height = "100%",
			}
		end)

		miru.mount "retained_tree_child"

		miru.box {
			key = "tail",
			width = 80,
			height = 20,
		}
	end)
end
