local copy = require "example.copy"
local miru = require "miru"

local args = ...
local floor <const> = math.floor
local max <const> = math.max
local min <const> = math.min
local sin <const> = math.sin

local COMPONENTS <const> = {
	"Surface",
	"Separator",
	"Button",
	"IconButton",
	"Switch",
	"Dropdown",
	"TextField",
	"FormActions",
	"Message",
	"ScrollArea",
	"Motion",
}

local DROPDOWN_OPTIONS <const> = {
	"Local runtime",
	"Remote runtime",
	"Preview mode",
	"Safe mode",
}

local function clamp(value, lower, upper)
	return min(max(value, lower), upper)
end

local function pixel(value)
	return floor(value + 0.5)
end

local function panel(width, height, children)
	local palette = miru.use "palette"
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
			fill = palette.surface,
			border_color = palette.line,
			border_width = 1,
		})
		children(width - 40)
	end)
end

local function title(name, detail, width)
	local palette = miru.use "palette"
	local detail_height = width < 280 and 54 or 38
	miru.vbox({
		width = width,
		gap = 5,
	}, function()
		miru.text(copy.group(name), {
			width = width,
			height = 30,
			style = "title",
			color = palette.text,
		})
		miru.text(copy.words(detail), {
			width = width,
			height = detail_height,
			style = "muted",
			color = palette.muted,
		})
	end)
end

local function metric(label, value, width)
	local palette = miru.use "palette"
	miru.vbox({
		width = width,
		height = 64,
		padding = 10,
		gap = 3,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = palette.surface_alt,
		})
		miru.text(copy.group(label), {
			width = width - 20,
			height = 16,
			style = "label",
			color = palette.muted,
		})
		miru.text(copy.group(value), {
			width = width - 20,
			height = 22,
			size = 15,
			color = palette.text,
		})
	end)
end

local function nav_item(name, selected_name, width, on_select)
	miru.mount("button", {
		width = width,
		height = 36,
		label = name,
		active = name == selected_name,
		on_click = on_select,
	})
end

local function desktop_sidebar(width, height, selected_name, select_component)
	local palette = miru.use "palette"
	miru.vbox({
		width = width,
		height = height,
		padding = 16,
		gap = 8,
	}, function()
		miru.mount("surface", {
			position = "absolute",
			left = 0,
			top = 0,
			width = "100%",
			height = "100%",
			fill = palette.dark,
		})
		miru.text(copy.group "MIRU / LIVE", {
			width = width - 32,
			height = 28,
			size = 18,
			color = palette.white,
		})
		miru.text(copy.group "Component index", {
			width = width - 32,
			height = 18,
			style = "label",
			color = 0xffa9c2bb,
		})
		for index, name in ipairs(COMPONENTS) do
			nav_item(name, selected_name, width - 32, function()
				select_component(index)
			end)
		end
	end)
end

local function mobile_navigation(width, selected_index, select_component)
	local selected_name = COMPONENTS[selected_index]
	miru.hbox({
		width = width,
		height = 42,
		gap = 8,
		alignItems = "center",
	}, function()
		miru.mount("icon_button", {
			size = 42,
			icon = "chevron_left",
			on_click = function()
				select_component(selected_index == 1 and #COMPONENTS or selected_index - 1)
			end,
		})
		miru.box({
			flex = 1,
			height = 42,
		}, function()
			miru.text(copy.group(selected_name), {
				width = "100%",
				height = 42,
				size = 16,
				align = "CV",
			})
		end)
		miru.mount("icon_button", {
			size = 42,
			icon = "chevron_right",
			on_click = function()
				select_component(selected_index == #COMPONENTS and 1 or selected_index + 1)
			end,
		})
	end)
end

local function surface_demo(width, height)
	local palette = miru.use "palette"
	panel(width, height, function(inner_width)
		title("Surface", "Compose material-backed panels inside normal Yoga layout nodes.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 112,
			gap = 10,
		}, function()
			local fills = { palette.primary_soft, palette.accent_soft, 0xfffff3cc }
			for index, fill in ipairs(fills) do
				local card_width = pixel((inner_width - 20) / 3)
				miru.vbox({
					width = card_width,
					height = 112,
					padding = 12,
					gap = 7,
				}, function()
					miru.mount("surface", {
						position = "absolute",
						left = 0,
						top = 0,
						width = "100%",
						height = "100%",
						fill = fill,
						border_color = palette.line,
						border_width = 1,
					})
					miru.text(copy.group("Layer " .. tostring(index)), {
						width = card_width - 24,
						height = 22,
						size = 15,
					})
					miru.text(copy.words "quad + layout", {
						width = card_width - 24,
						height = 36,
						style = "muted",
					})
				end)
			end
		end)
		metric("Composition", "canvas + box", min(210, inner_width))
	end)
end

local function separator_demo(width, height)
	local palette = miru.use "palette"
	panel(width, height, function(inner_width)
		title("Separator", "A one-pixel visual rule that participates in the same layout tree.", inner_width)
		for index, label in ipairs { "Foundation", "Interaction", "Rendering" } do
			miru.text(copy.group(label), {
				width = inner_width,
				height = 28,
				size = 15,
				color = palette.text,
				align = "LV",
			})
			if index < 3 then
				miru.mount("separator", {
					width = inner_width,
				})
			end
		end
	end)
end

local button_count = miru.value(0)
local icon_button_count = miru.value(0)
local switch_enabled = miru.value(true)
local dropdown_open = miru.value(false)
local dropdown_value = miru.value(DROPDOWN_OPTIONS[1])
local text_value = miru.value "https://api.example.dev/v1"
local form_status = miru.value "Unsaved changes"
local scroll_offset = miru.value(0)
local selected_index = miru.value(4)
local phase = miru.value(0)

local function button_demo(width, height)
	panel(width, height, function(inner_width)
		title("Button", "Hover, press, active, primary, and danger states share one component contract.", inner_width)
		local button_width = pixel((inner_width - 20) / 3)
		miru.hbox({
			width = inner_width,
			height = 42,
			gap = 10,
		}, function()
			miru.mount("button", {
				width = button_width,
				height = 42,
				kind = "primary",
				label = "Run",
				on_click = function()
					button_count(button_count() + 1)
				end,
			})
			miru.mount("button", {
				width = button_width,
				height = 42,
				label = "Inspect",
			})
			miru.mount("button", {
				width = button_width,
				height = 42,
				kind = "danger",
				label = "Delete",
			})
		end)
		metric("Run count", tostring(button_count()), min(190, inner_width))
	end)
end

local function icon_button_demo(width, height)
	panel(width, height, function(inner_width)
		title("IconButton", "Compact commands use a stable square hit target and Lucide icons.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 42,
			gap = 10,
		}, function()
			for _, icon in ipairs { "refresh_cw", "pencil", "close" } do
				miru.mount("icon_button", {
					icon = icon,
					on_click = function()
						icon_button_count(icon_button_count() + 1)
					end,
				})
			end
		end)
		metric("Command count", tostring(icon_button_count()), min(190, inner_width))
	end)
end

local function switch_demo(width, height)
	local palette = miru.use "palette"
	panel(width, height, function(inner_width)
		title("Switch", "A reactive boolean drives an animated visual target without imperative tweens.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 48,
			gap = 14,
			alignItems = "center",
		}, function()
			miru.mount("switch", {
				checked = switch_enabled(),
				on_toggle = function()
					switch_enabled(not switch_enabled())
				end,
			})
			miru.text(copy.group(switch_enabled() and "Live updates enabled" or "Live updates paused"), {
				width = inner_width - 66,
				height = 24,
				size = 15,
				color = palette.text,
				align = "LV",
			})
		end)
		metric("Reactive value", tostring(switch_enabled()), min(210, inner_width))
	end)
end

local function dropdown_demo(width, height)
	panel(width, height, function(inner_width)
		title("Dropdown", "Dismissable overlays keep open state and selection in ordinary Miru values.", inner_width)
		miru.mount("dropdown", {
			width = min(300, inner_width),
			value = dropdown_value(),
			open = dropdown_open(),
			options = DROPDOWN_OPTIONS,
			on_toggle = function()
				dropdown_open(not dropdown_open())
			end,
			on_close = function()
				dropdown_open(false)
			end,
			on_select = function(value)
				dropdown_value(value)
				dropdown_open(false)
			end,
		})
	end)
end

local function text_field_demo(width, height)
	panel(width, height, function(inner_width)
		title("TextField", "Focus, character, key, and clipboard events stay inside the component boundary.", inner_width)
		miru.mount("text_field", {
			width = min(480, inner_width),
			label = "Endpoint",
			placeholder = "Enter a runtime endpoint",
			value = text_value(),
			on_char = function(codepoint)
				text_value(text_value() .. utf8.char(codepoint))
			end,
			on_backspace = function()
				local current = text_value()
				local offset = utf8.offset(current, -1)
				text_value(offset and current:sub(1, offset - 1) or "")
			end,
			on_paste = function(value)
				text_value(text_value() .. value)
			end,
		})
		miru.hbox({
			width = inner_width,
			height = 38,
			gap = 10,
		}, function()
			miru.mount("button", {
				width = 100,
				height = 38,
				label = "Preset",
				on_click = function()
					text_value "https://api.example.dev/v1"
				end,
			})
			miru.mount("button", {
				width = 100,
				height = 38,
				label = "Clear",
				on_click = function()
					text_value ""
				end,
			})
		end)
	end)
end

local function form_actions_demo(width, height)
	panel(width, height, function(inner_width)
		title("FormActions", "Compose status and command components while the parent owns form state.", inner_width)
		miru.mount("form_actions", {
			width = inner_width,
			button_width = inner_width < 390 and 76 or 88,
			status = form_status(),
			on_save = function()
				form_status "Saved locally"
			end,
			on_cancel = function()
				form_status "Changes discarded"
			end,
		})
	end)
end

local function message_demo(width, height)
	panel(width, height, function(inner_width)
		title("Message", "Measured text and nested layout determine each row's final height.", inner_width)
		local message_width = min(560, inner_width)
		miru.mount("message", {
			width = message_width,
			role = "user",
			title = "Developer",
			body = "Build a component from values, layout, and interaction modifiers.",
		})
		miru.mount("message", {
			width = message_width,
			role = "assistant",
			title = "Miru",
			body = "The component rerenders only when its reactive dependencies change.",
		})
	end)
end

local function scroll_area_demo(width, height)
	panel(width, height, function(inner_width)
		title("ScrollArea", "Overflow clipping and wheel ownership compose into a reusable viewport.", inner_width)
		miru.mount("scroll_area", {
			width = min(520, inner_width),
			height = 150,
			offset = scroll_offset(),
			on_scroll = function(delta)
				scroll_offset(clamp(scroll_offset() + delta * 18, 0, 180))
			end,
		})
		metric("Scroll offset", tostring(pixel(scroll_offset())), min(190, inner_width))
	end)
end

local function motion_demo(width, height)
	local palette = miru.use "palette"
	panel(width, height, function(inner_width)
		title("Motion", "Frame input can update a value while components remain declarative.", inner_width)
		miru.hbox({
			width = inner_width,
			height = 96,
			gap = 12,
			alignItems = "flex-end",
		}, function()
			for index = 1, 5 do
				local wave = (sin(phase() * 3.4 + index * 0.8) + 1) * 0.5
				local bar_height = pixel(24 + wave * 64)
				miru.box({
					width = pixel((inner_width - 48) / 5),
					height = bar_height,
					background = index % 2 == 0 and palette.accent or palette.primary,
				})
			end
		end)
		metric("Animation source", "reactive phase", min(210, inner_width))
	end)
end

local function demo(name, width, height)
	if name == "Surface" then
		surface_demo(width, height)
	elseif name == "Separator" then
		separator_demo(width, height)
	elseif name == "Button" then
		button_demo(width, height)
	elseif name == "IconButton" then
		icon_button_demo(width, height)
	elseif name == "Switch" then
		switch_demo(width, height)
	elseif name == "Dropdown" then
		dropdown_demo(width, height)
	elseif name == "TextField" then
		text_field_demo(width, height)
	elseif name == "FormActions" then
		form_actions_demo(width, height)
	elseif name == "Message" then
		message_demo(width, height)
	elseif name == "ScrollArea" then
		scroll_area_demo(width, height)
	else
		motion_demo(width, height)
	end
end

miru.expose {
	tick = function(dt)
		phase((phase() + dt) % 1000)
	end,
}

return function()
	local palette = miru.use "palette"
	local screen_width = args.screen_width or 1180
	local screen_height = args.screen_height or 720
	local mobile = screen_width < 720
	local padding = mobile and 14 or 24
	local gap = mobile and 12 or 22
	local current_index = clamp(selected_index(), 1, #COMPONENTS)
	local current_name = COMPONENTS[current_index]

	local function select_component(index)
		selected_index(clamp(index, 1, #COMPONENTS))
		dropdown_open(false)
	end

	if mobile then
		local content_width = max(1, screen_width - padding * 2)
		local panel_height = max(470, screen_height - 142)
		miru.vbox({
			width = screen_width,
			height = screen_height,
			padding = padding,
			gap = gap,
			background = palette.page,
		}, function()
			miru.hbox({
				width = content_width,
				height = 36,
				alignItems = "center",
			}, function()
				miru.text(copy.group "MIRU", {
					width = 86,
					height = 36,
					size = 22,
					color = palette.dark,
					align = "LV",
				})
				miru.text(copy.group "Live component workbench", {
					flex = 1,
					height = 36,
					style = "muted",
					color = palette.muted,
					align = "RV",
				})
			end)
			mobile_navigation(content_width, current_index, select_component)
			demo(current_name, content_width, panel_height)
		end)
		return
	end

	local sidebar_width = 226
	local content_width = screen_width - padding * 2 - gap - sidebar_width
	local panel_width = min(780, content_width)
	local panel_height = min(480, screen_height - padding * 2 - 120)
	miru.hbox({
		width = screen_width,
		height = screen_height,
		padding = padding,
		gap = gap,
		alignItems = "flex-start",
		background = palette.page,
	}, function()
		desktop_sidebar(sidebar_width, screen_height - padding * 2, current_name, select_component)
		miru.vbox({
			width = content_width,
			gap = 14,
		}, function()
			miru.vbox({
				width = content_width,
				gap = 4,
			}, function()
				miru.text(copy.group(current_name), {
					width = content_width,
					height = 38,
					size = 30,
					color = palette.dark,
				})
				miru.text(copy.words "Inspect the component's real hover, focus, input, and state behavior.", {
					width = content_width,
					height = 20,
					style = "muted",
					color = palette.muted,
				})
			end)
			demo(current_name, panel_width, panel_height)
			miru.hbox({
				width = panel_width,
				height = 64,
				gap = 10,
			}, function()
				metric("Selected", current_name, min(210, pixel((panel_width - 20) / 3)))
				metric("Components", tostring(#COMPONENTS), min(210, pixel((panel_width - 20) / 3)))
				metric("Runtime", "Soluna + Miru", min(210, pixel((panel_width - 20) / 3)))
			end)
		end)
	end)
end
