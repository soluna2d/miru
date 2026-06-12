local miru = require "miru"
local surface = require "test.feature.showcase.surface"

local args = ...

local panel_open = miru.signal(true)
local panel_label = miru.memo(function()
	return panel_open() and "Hide Details" or "Show Details"
end)
local detail_text = miru.memo(function()
	return panel_open() and "Hover and click controls to exercise local state." or ""
end)

return function()
	local width = args.width or 1200
	local height = args.height or 800

	surface({
		width = width,
		height = height,
		fill = 0xfff3f4f6,
	}, function()
		miru.vbox({
			width = math.min(width - 64, 1040),
			height = math.min(height - 64, 680),
			margin = "32 auto 32 auto",
			gap = 16,
		}, function()
			miru.text("Miru Signal Showcase", {
				width = "100%",
				height = 34,
				size = 24,
				color = 0xff111827,
				align = "LC",
			})

			miru.hbox({
				width = "100%",
				height = 260,
				gap = 16,
			}, function()
				surface({
					flex = 1,
					height = "100%",
					radius = 12,
					fill = 0xffffffff,
					border = 0xffe5e7eb,
					border_width = 1,
					padding = "20 20 20 20",
				}, function()
					miru.vbox({
						width = "100%",
						height = "100%",
						gap = 12,
					}, function()
						miru.text("Controls", {
							width = "100%",
							height = 26,
							size = 18,
							color = 0xff111827,
							align = "LC",
						})
						miru.mount("test/feature/showcase/button", {
							label = panel_label,
							background = 0xffeff6ff,
							hover_background = 0xffdbeafe,
							pressed_background = 0xffbfdbfe,
							border = 0xff93c5fd,
							text_color = 0xff1d4ed8,
							on_click = function()
								panel_open(not panel_open())
							end,
						})
						miru.mount("test/feature/showcase/toggle", {
							checked = true,
						})
					end)
				end)

				surface({
					flex = 1,
					height = "100%",
					radius = 12,
					fill = 0xffffffff,
					border = 0xffe5e7eb,
					border_width = 1,
					padding = "20 20 20 20",
				}, function()
					miru.vbox({
						width = "100%",
						height = "100%",
						gap = 10,
					}, function()
						miru.text("Metrics", {
							width = "100%",
							height = 26,
							size = 18,
							color = 0xff111827,
							align = "LC",
						})
						miru.text("Visible component render count is drawn by the host overlay.", {
							width = "100%",
							height = 44,
							size = 14,
							color = 0xff6b7280,
							align = "LC",
						})
						miru.text(detail_text, {
							width = "100%",
							height = 28,
							size = 14,
							color = 0xff374151,
							align = "LC",
						})
					end)
				end)
			end)
		end)
	end)
end
