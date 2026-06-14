local app = require "soluna.app"
local miru = require "miru"
local rounded_rect = require "test.material.rounded_rect_native"
local soluna = require "soluna"
local text_engine = require "test.feature.text_engine"
local lucide_icon = require "test.support.lucide_icon"

local KEY_ESCAPE <const> = 256
local KEY_BACKSPACE <const> = 259
local KEYSTATE_PRESS <const> = 1
local KEYSTATE_REPEAT <const> = 2
local MOUSE_LEFT <const> = 0
local PROBE_WIDTH <const> = 260
local PROBE_HEIGHT <const> = 92

local args = ...

soluna.set_window_title "Miru Component Gallery"

local report = {}
local view = miru.new {
	width = args.width,
	height = args.height,
	component_path = "test/feature/?.lua;test/smoke/?.lua;?.lua;?/init.lua",
	text_engine = text_engine,
}
view:provide("rounded_rect", rounded_rect)
view:provide("icon", lucide_icon)
---@class GalleryInstance : MiruInstance
---@field select_component fun(self: GalleryInstance, name: string)
---@field press_primary_button fun(self: GalleryInstance)
---@field press_icon_button fun(self: GalleryInstance)
---@field toggle_switch fun(self: GalleryInstance)
---@field set_switch_enabled fun(self: GalleryInstance, enabled: boolean)
---@field focus_text_field fun(self: GalleryInstance)
---@field type_text fun(self: GalleryInstance, text: string)
---@field key fun(self: GalleryInstance, keycode: integer)
---@field toggle_dropdown fun(self: GalleryInstance)
---@field choose_dropdown fun(self: GalleryInstance, value: string)
---@field save_form fun(self: GalleryInstance)
---@field cancel_form fun(self: GalleryInstance)
local instance = view:mount("feature_gallery", {
	report = report,
	screen_width = args.width,
	screen_height = args.height,
})
---@cast instance GalleryInstance
local max_frames = tonumber(os.getenv and os.getenv "TEST_FRAMES" or "")
local viewport_width = args.width
local viewport_height = args.height
local frame_count = 0
local draw_count = 0
local resize_count = 0
local last_render_count = 0
local script_index = 0
local script_steps = {}

local function draw_probe(batch, count)
	local stats = view:statistics()
	local render_count = stats.render_count
	local render_delta = render_count - last_render_count
	last_render_count = render_count
	local x = math.max(12, viewport_width - PROBE_WIDTH - 16)
	local y = 16
	batch:add(rounded_rect.rect {
		width = PROBE_WIDTH,
		height = PROBE_HEIGHT,
		radius = 10,
		fill = 0xee0f172a,
		border = 0xff334155,
		border_width = 1,
	}, x, y)
	local layout = text_engine.layout {
		text = string.format(
			"frame %d  draw %d\ncomponent render %d  +%d\nresize %d  %dx%d",
			count,
			draw_count,
			render_count,
			render_delta,
			resize_count,
			viewport_width,
			viewport_height
		),
		width = PROBE_WIDTH - 24,
		height = PROBE_HEIGHT - 20,
		size = 12,
		color = 0xffe2e8f0,
	}
	layout:draw(batch, x + 12, y + 10)
end

local function expect(value, expected, name)
	assert(value == expected, name .. "=" .. tostring(value) .. ", expected=" .. tostring(expected))
end

local callback = {}

script_steps[1] = function()
	callback.window_resize(960, 700)
	instance:select_component("Switch")
	instance:set_switch_enabled(false)
end

script_steps[2] = function()
	instance:select_component("Dropdown")
	instance:toggle_dropdown()
end

script_steps[3] = function()
	instance:choose_dropdown("OpenAI Codex")
end

script_steps[4] = function()
	instance:select_component("TextField")
	instance:focus_text_field()
	instance:type_text("/chat")
	instance:key(KEY_BACKSPACE)
end

script_steps[5] = function()
	instance:select_component("IconButton")
	instance:press_icon_button()
end

script_steps[6] = function()
	instance:select_component("FormActions")
	instance:save_form()
end

script_steps[7] = function()
	instance:select_component("Button")
	instance:press_primary_button()
end

function callback.window_resize(width, height)
	viewport_width = width
	viewport_height = height
	resize_count = resize_count + 1
	view:resize(width, height)
	instance.args.screen_width = width
	instance.args.screen_height = height
end

function callback.frame(count)
	frame_count = count
	if max_frames then
		script_index = script_index + 1
		local step = script_steps[script_index]
		if step then
			step()
		end
	end

	view:update(1 / 60)
	view:draw(args.batch)
	draw_count = draw_count + 1
	draw_probe(args.batch, frame_count)

	if max_frames and script_index >= max_frames then
		expect(report.selected_component, "Button", "selected_component")
		expect(report.dropdown_action, "OpenAI Codex", "dropdown_action")
		expect(report.switch_enabled, false, "switch_enabled")
		expect(report.text_value, "https://api.example.local/v1/cha", "text_value")
		expect(report.button_count, 1, "button_count")
		expect(report.icon_button_count, 1, "icon_button_count")
		expect(report.form_action, "Save", "form_action")
		expect(report.screen_width, 960, "screen_width")
		expect(report.screen_height, 700, "screen_height")
		assert(report.panel_width < 720)
		app.quit()
	end
end

function callback.key(keycode, state)
	if keycode == KEY_ESCAPE and state == KEYSTATE_PRESS then
		app.quit()
		return
	end
	if state == KEYSTATE_PRESS or state == KEYSTATE_REPEAT then
		instance:key(keycode)
	end
end

function callback.char(char)
	instance:type_text(char)
end

function callback.mouse_move(x, y)
	view:pointer(x, y)
end

function callback.mouse_button(button, state)
	if button == MOUSE_LEFT then
		view:mouse_button(button, state)
	end
end

return callback
