local app = require "soluna.app"
local lucide_icon = require "test.support.lucide_icon"
local miru = require "miru"
local rounded_rect = require "test.material.rounded_rect_native"
local soluna = require "soluna"
local text = require "test.support.text"

local KEY_ESCAPE <const> = 256
local KEY_BACKSPACE <const> = 259
local KEYSTATE_PRESS <const> = 1
local KEYSTATE_REPEAT <const> = 2
local MOUSE_LEFT <const> = 0
local PROBE_WIDTH <const> = 260
local PROBE_HEIGHT <const> = 92

local M = {}

function M.app(args)
	soluna.set_window_title "Miru Component Gallery"

	local report = {}
	local view = miru.new {
		width = args.width,
		height = args.height,
		component_path = "test/feature/?.lua;test/smoke/?.lua;?.lua;?/init.lua",
	}
	view:text_styles(text.styles())
	view:provide("rounded_rect", rounded_rect)
	view:provide("icon", lucide_icon)
	---@class GalleryInstance : MiruInstance
	---@field target_rect fun(self: GalleryInstance, name: string): MiruRect?
	local instance = view:mount("feature_gallery", {
		report = report,
		screen_width = args.width,
		screen_height = args.height,
	})
	---@cast instance GalleryInstance
	local max_frames = math.tointeger(tonumber(os.getenv and os.getenv "TEST_FRAMES" or "") or 0) or 0
	local viewport_width = args.width
	local viewport_height = args.height
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
		---@type number
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
		local layout = text.layout {
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
			size = 12,
			color = 0xffe2e8f0,
		}
		layout:draw(batch, x + 12, y + 10)
	end

	local function expect(value, expected, name)
		assert(value == expected, name .. "=" .. tostring(value) .. ", expected=" .. tostring(expected))
	end

	local callback = {}
	local function click_target(name)
		local rect = assert(instance:target_rect(name), "missing gallery target " .. name)
		view:pointer(rect.x + rect.w / 2, rect.y + rect.h / 2)
		view:mouse_button(MOUSE_LEFT, KEYSTATE_PRESS)
		view:mouse_button(MOUSE_LEFT, 0)
	end

	script_steps[1] = function()
		callback.window_resize(960, 700)
	end

	script_steps[2] = function()
		click_target "switch"
		click_target "Dropdown"
	end

	script_steps[3] = function()
		click_target "dropdown_trigger"
	end

	script_steps[4] = function()
		view:pointer(950, 680)
		view:mouse_button(MOUSE_LEFT, KEYSTATE_PRESS)
		view:mouse_button(MOUSE_LEFT, 0)
	end

	script_steps[5] = function()
		expect(report.dropdown_open, false, "dropdown_open_after_dismiss")
		click_target "dropdown_trigger"
	end

	script_steps[6] = function()
		click_target "OpenAI Codex"
		click_target "TextField"
	end

	script_steps[7] = function()
		click_target "text_field"
		for char in ("/chat"):gmatch "." do
			view:char {
				codepoint = string.byte(char),
			}
		end
		view:key {
			keycode = KEY_BACKSPACE,
			state = KEYSTATE_PRESS,
		}
		click_target "ScrollArea"
	end

	script_steps[8] = function()
		local rect = assert(instance:target_rect "scroll_area")
		view:pointer(rect.x + rect.w / 2, rect.y + rect.h / 2)
		view:mouse_scroll {
			scroll_y = 3,
		}
		click_target "IconButton"
	end

	script_steps[9] = function()
		click_target "icon_button"
		click_target "FormActions"
	end

	script_steps[10] = function()
		click_target "form_save"
		click_target "Button"
	end

	script_steps[11] = function()
		click_target "button"
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
		if max_frames > 0 then
			script_index = script_index + 1
			local step = script_steps[script_index]
			if step then
				step()
			end
		end

		view:update(1 / 60)
		view:draw(args.batch)
		draw_count = draw_count + 1
		draw_probe(args.batch, count)

		if max_frames > 0 and script_index >= max_frames then
			expect(report.selected_component, "Button", "selected_component")
			expect(report.dropdown_action, "OpenAI Codex", "dropdown_action")
			expect(report.dropdown_open, false, "dropdown_open")
			expect(report.switch_enabled, false, "switch_enabled")
			expect(report.text_value, "https://api.example.local/v1/cha", "text_value")
			expect(report.button_count, 1, "button_count")
			expect(report.icon_button_count, 1, "icon_button_count")
			expect(report.form_action, "Save", "form_action")
			expect(report.scroll_offset, 54, "scroll_offset")
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
			view:key {
				keycode = keycode,
				state = state,
			}
		end
	end

	function callback.char(codepoint)
		view:char {
			codepoint = codepoint,
		}
	end

	function callback.clipboard_pasted(value)
		view:clipboard_pasted {
			text = value,
		}
	end

	function callback.mouse_move(x, y)
		view:pointer(x, y)
	end

	function callback.mouse_button(button, state)
		view:mouse_button(button, state)
	end

	function callback.mouse_scroll(y, x)
		view:mouse_scroll {
			scroll_x = x,
			scroll_y = y,
		}
	end

	return callback
end

return M
