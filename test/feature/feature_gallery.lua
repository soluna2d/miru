local miru = require "miru"

local args = ...

local KEY_BACKSPACE <const> = 259

local PAGE <const> = 0xfff8fafc
local SURFACE <const> = 0xffffffff
local SURFACE_ALT <const> = 0xfff1f5f9
local LINE <const> = 0xffcbd5e1
local MUTED <const> = 0xff64748b
local TEXT <const> = 0xff111827
local floor <const> = math.floor
local min <const> = math.min
local max <const> = math.max

local COMPONENTS <const> = {
	{
		group = "Foundation",
		items = {
			{ name = "Surface", detail = "Rounded material backed panels" },
			{ name = "Separator", detail = "Hairline layout divider" },
			{ name = "IconButton", detail = "Icon-only command button" },
		},
	},
	{
		group = "Controls",
		items = {
			{ name = "Button", detail = "Text and command buttons" },
			{ name = "Switch", detail = "Animated boolean toggle" },
			{ name = "Dropdown", detail = "Single menu selection" },
			{ name = "TextField", detail = "Focused single-line input" },
		},
	},
	{
		group = "Application",
		items = {
			{ name = "FormActions", detail = "Cancel and save command row" },
			{ name = "Message", detail = "Chat message bubble" },
		},
	},
}

local function all_components()
	local out = {}
	for i = 1, #COMPONENTS do
		local group = COMPONENTS[i]
		for j = 1, #group.items do
			out[#out + 1] = group.items[j].name
		end
	end
	return out
end

local ALL_COMPONENTS <const> = all_components()

local function clamp(value, min_value, max_value)
	return min(max(value, min_value), max_value)
end

local function pixel(value)
	return floor(value + 0.5)
end

local function viewport_metrics(width, height)
	local padding = width < 900 and 16 or 24
	local gap = width < 900 and 16 or 24
	local sidebar_width = pixel(clamp(width * 0.25, 170, 300))
	local content_width = width - padding * 2 - gap - sidebar_width
	if content_width < 360 then
		sidebar_width = pixel(max(150, width - padding * 2 - gap - 360))
		content_width = width - padding * 2 - gap - sidebar_width
	end
	return {
		padding = padding,
		gap = gap,
		sidebar_width = sidebar_width,
		sidebar_height = pixel(max(360, height - padding * 2)),
		content_width = pixel(max(360, content_width)),
		panel_width = pixel(clamp(content_width, 380, 760)),
	}
end

local function panel(width, height, children)
	miru.vbox({
		width = width,
		height = height,
		padding = 20,
		gap = 14,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = SURFACE,
			radius = 14,
			border_color = LINE,
			border_width = 1,
		})
		children()
	end)
end

local function title(text, detail, width)
	miru.vbox({
		width = width,
		gap = 6,
	}, function()
		miru.text(text, {
			width = width,
			height = 28,
			size = 22,
			color = TEXT,
		})
		miru.text(detail, {
			width = width,
			height = 36,
			size = 13,
			color = MUTED,
		})
	end)
end

local function section(text, width)
	miru.text(text, {
		width = width,
		height = 20,
		size = 13,
		color = MUTED,
	})
end

local function metric(label, value, width)
	miru.vbox({
		width = width,
		padding = 12,
		gap = 4,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = SURFACE_ALT,
			radius = 10,
		})
		miru.text(label, {
			width = width - 24,
			height = 16,
			size = 12,
			color = MUTED,
		})
		miru.text(value, {
			width = width - 24,
			height = 20,
			size = 15,
			color = TEXT,
		})
	end)
end

local function nav_item(item, selected, on_select, width)
	miru.mount("gallery_button", {
		width = width,
		height = 38,
		radius = 9,
		label = item.name,
		active = selected == item.name,
		on_click = function()
			on_select(item.name)
		end,
	})
end

local function sidebar(selected, on_select, width, height)
	local inner_width = width - 36
	miru.vbox({
		width = width,
		height = height,
		padding = 18,
		gap = 12,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = SURFACE,
			radius = 16,
			border_color = LINE,
			border_width = 1,
		})
		miru.text("Miru Gallery", {
			width = inner_width,
			height = 28,
			size = 20,
			color = TEXT,
		})
		miru.text("Components", {
			width = inner_width,
			height = 18,
			size = 13,
			color = MUTED,
		})
		for i = 1, #COMPONENTS do
			local group = COMPONENTS[i]
			section(group.group, inner_width)
			for j = 1, #group.items do
				nav_item(group.items[j], selected, on_select, inner_width)
			end
		end
	end)
end

local function surface_demo(width)
	panel(width, 300, function()
		local inner_width = width - 40
		title("Surface", "A layout node owns the rect, and a canvas draws the material.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 96,
			gap = 12,
		}, function()
			for i, fill in ipairs({ 0xffffffff, 0xffecfeff, 0xfffff7ed }) do
				miru.vbox({
					width = pixel((inner_width - 24) / 3),
					height = 96,
					padding = 12,
					gap = 6,
				}, function()
					miru.mount("surface", {
						position = "absolute",
						left = 0,
						top = 0,
						width = "100%",
						height = "100%",
						fill = fill,
						radius = 12,
						border_color = LINE,
						border_width = 1,
					})
					miru.text("Panel " .. tostring(i), {
						width = pixel((inner_width - 24) / 3) - 24,
						height = 20,
						size = 14,
						color = TEXT,
					})
					miru.text("Canvas material", {
						width = pixel((inner_width - 24) / 3) - 24,
						height = 18,
						size = 12,
						color = MUTED,
					})
				end)
			end
		end)
	end)
end

local function separator_demo(width)
	panel(width, 260, function()
		local inner_width = width - 40
		title("Separator", "A stable one-pixel divider that participates in Yoga layout.", inner_width)
		for i, label in ipairs({ "Account", "Runtime", "Network" }) do
			miru.text(label, {
				width = inner_width,
				height = 24,
				size = 15,
				color = TEXT,
			})
			if i < 3 then
				miru.mount("gallery_separator", {
					width = inner_width,
					height = 1,
				})
			end
		end
	end)
end

local function icon_button_demo(width, count, increment)
	panel(width, 260, function()
		local inner_width = width - 40
		title("IconButton", "Icon-only commands use the same hover and pressed state as text buttons.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 44,
			gap = 10,
		}, function()
			miru.mount("gallery_icon_button", {
				name = "close",
				on_click = increment,
			})
			miru.mount("gallery_icon_button", {
				name = "chevron_down",
				angle = math.pi,
				hover_color = 0xff0d9488,
			})
			miru.mount("gallery_icon_button", {
				name = "chevron_down",
				hover_color = 0xff0d9488,
			})
		end)
		metric("Close clicks", tostring(count), 170)
	end)
end

local function button_demo(width, count, increment)
	panel(width, 270, function()
		local inner_width = width - 40
		local button_width = pixel(max(84, (inner_width - 24) / 3))
		local metric_width = pixel(min(170, (inner_width - 12) / 2))
		title("Button", "Clickable commands with hover, pressed, primary, danger, and active states.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 42,
			gap = 12,
		}, function()
			miru.mount("gallery_button", {
				width = button_width,
				kind = "primary",
				label = "Run",
				on_click = increment,
			})
			miru.mount("gallery_button", {
				width = button_width,
				label = "Inspect",
			})
			miru.mount("gallery_button", {
				width = button_width,
				kind = "danger",
				label = "Delete",
			})
		end)
		miru.hbox({
			width = inner_width,
			height = 70,
			gap = 12,
		}, function()
			metric("Click count", tostring(count), metric_width)
			metric("Last command", count > 0 and "Run" or "Idle", metric_width)
		end)
	end)
end

local function switch_demo(width, enabled, set_enabled)
	panel(width, 280, function()
		local inner_width = width - 40
		title("Switch", "Animated boolean state for settings and provider options.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 48,
			gap = 14,
			alignItems = "center",
		}, function()
			miru.mount("gallery_switch", {
				checked = enabled,
				on_change = set_enabled,
			})
			miru.text(enabled and "Enabled" or "Disabled", {
				width = inner_width - 64,
				height = 24,
				size = 15,
				color = TEXT,
				align = "LV",
			})
		end)
		metric("Provider routing", enabled and "On" or "Off", 190)
	end)
end

local function dropdown_demo(width, value, open, toggle, choose)
	panel(width, 330, function()
		local inner_width = width - 40
		title("Dropdown", "A trigger opens a menu and writes the selected action.", inner_width)
		miru.mount("gallery_dropdown", {
			width = min(280, inner_width),
			value = value,
			open = open,
			options = { "OpenAI", "OpenAI Codex", "Local Runtime", "Custom Provider" },
			on_toggle = toggle,
			on_select = choose,
		})
	end)
end

local function text_field_demo(width, value, focused, focus, set_value)
	panel(width, 280, function()
		local inner_width = width - 40
		title("TextField", "Focused single-line editing for provider settings and composer controls.", inner_width)
		miru.mount("gallery_input", {
			width = min(460, inner_width),
			label = "Endpoint",
			placeholder = "https://api.example.local/v1",
			value = value,
			focused = focused,
			on_focus = focus,
		})
		miru.hbox({
			width = inner_width,
			height = 38,
			gap = 10,
		}, function()
			miru.mount("gallery_button", {
				width = 104,
				label = "Preset",
				on_click = function()
					set_value("https://api.example.local/v1")
				end,
			})
			miru.mount("gallery_button", {
				width = 104,
				label = "Clear",
				on_click = function()
					set_value("")
				end,
			})
		end)
	end)
end

local function form_actions_demo(width, action, save, cancel)
	panel(width, 240, function()
		local inner_width = width - 40
		title("FormActions", "A status line plus cancel/save command row.", inner_width)
		miru.mount("gallery_form_actions", {
			width = inner_width,
			status = action == "Save" and "Saved local draft" or action == "Cancel" and "Discarded local draft" or "Unsaved changes",
			on_save = save,
			on_cancel = cancel,
		})
	end)
end

local function message_demo(width)
	panel(width, 360, function()
		local inner_width = width - 40
		title("Message", "Chat rows combine rounded panels and measured text height.", inner_width)
		miru.mount("gallery_message", {
			width = min(580, inner_width),
			role = "user",
			title = "Hanchin",
			body = "Use the gallery to validate real component interaction, layout, and rendering behavior.",
		})
		miru.mount("gallery_message", {
			width = min(580, inner_width),
			role = "assistant",
			title = "Assistant",
			body = "This bubble reflows through the injected text engine and keeps the panel height in Yoga layout.",
		})
	end)
end

local selected = miru.value("Switch")
local button_count = miru.value(0)
local icon_button_count = miru.value(0)
local text_value = miru.value("https://api.example.local/v1")
local text_focused = miru.value(false)
local switch_enabled = miru.value(true)
local dropdown_open = miru.value(false)
local dropdown_value = miru.value("OpenAI")
local form_action = miru.value("None")

miru.expose {
	select_component = function(name)
		selected(name)
	end,
	press_primary_button = function()
		button_count(button_count() + 1)
	end,
	press_icon_button = function()
		icon_button_count(icon_button_count() + 1)
	end,
	toggle_switch = function()
		switch_enabled(not switch_enabled())
	end,
	set_switch_enabled = function(enabled)
		switch_enabled(enabled == true)
	end,
	focus_text_field = function()
		text_focused(true)
	end,
	type_text = function(text)
		if text_focused() then
			text_value(text_value() .. text)
		end
	end,
	key = function(keycode)
		if text_focused() and keycode == KEY_BACKSPACE then
			local value = text_value()
			text_value(value:sub(1, #value - 1))
		end
	end,
	toggle_dropdown = function()
		dropdown_open(not dropdown_open())
	end,
	choose_dropdown = function(value)
		dropdown_value(value)
		dropdown_open(false)
	end,
	save_form = function()
		form_action("Save")
	end,
	cancel_form = function()
		form_action("Cancel")
	end,
}

return function()
	local screen_width = args.screen_width or 1200
	local screen_height = args.screen_height or 800
	local metrics = viewport_metrics(screen_width, screen_height)
	local report = args.report
	local selected_name = selected()
	if report then
		report.selected_component = selected_name
		report.screen_width = screen_width
		report.screen_height = screen_height
		report.panel_width = metrics.panel_width
		report.button_count = button_count()
		report.icon_button_count = icon_button_count()
		report.text_value = text_value()
		report.switch_enabled = switch_enabled()
		report.dropdown_action = dropdown_value()
		report.form_action = form_action()
	end

	miru.hbox({
		width = screen_width,
		height = screen_height,
		padding = metrics.padding,
		gap = metrics.gap,
		alignItems = "flex-start",
		background = PAGE,
	}, function()
		sidebar(selected_name, function(name)
			selected(name)
		end, metrics.sidebar_width, metrics.sidebar_height)
		miru.vbox({
			width = metrics.content_width,
			gap = 18,
		}, function()
			miru.vbox({
				width = metrics.content_width,
				gap = 8,
			}, function()
				miru.text(selected_name, {
					width = metrics.content_width,
					height = 44,
					size = 36,
					color = TEXT,
				})
				miru.text("Interactive component workbench", {
					width = metrics.content_width,
					height = 20,
					size = 14,
					color = MUTED,
				})
			end)
			if selected_name == "Surface" then
				surface_demo(metrics.panel_width)
			elseif selected_name == "Separator" then
				separator_demo(metrics.panel_width)
			elseif selected_name == "IconButton" then
				icon_button_demo(metrics.panel_width, icon_button_count(), function()
					icon_button_count(icon_button_count() + 1)
				end)
			elseif selected_name == "Button" then
				button_demo(metrics.panel_width, button_count(), function()
					button_count(button_count() + 1)
				end)
			elseif selected_name == "Switch" then
				switch_demo(metrics.panel_width, switch_enabled(), switch_enabled)
			elseif selected_name == "Dropdown" then
				dropdown_demo(metrics.panel_width, dropdown_value(), dropdown_open(), function()
					dropdown_open(not dropdown_open())
				end, function(value)
					dropdown_value(value)
					dropdown_open(false)
				end)
			elseif selected_name == "TextField" then
				text_field_demo(metrics.panel_width, text_value(), text_focused(), function()
					text_focused(true)
				end, text_value)
			elseif selected_name == "FormActions" then
				form_actions_demo(metrics.panel_width, form_action(), function()
					form_action("Save")
				end, function()
					form_action("Cancel")
				end)
			elseif selected_name == "Message" then
				message_demo(metrics.panel_width)
			else
				switch_demo(metrics.panel_width, switch_enabled(), switch_enabled)
			end
			miru.hbox({
				width = metrics.panel_width,
				height = 72,
				gap = 12,
			}, function()
				metric("Selected", selected_name, 190)
				metric("Components", tostring(#ALL_COMPONENTS), 170)
				metric("Theme", "Neutral", 170)
			end)
		end)
	end)
end
