local app = require "soluna.app"
local font = require "example.font"
local miru = require "miru"
local palette = require "example.palette"
local soluna = require "soluna"

local KEY_ESCAPE <const> = 256
local KEYSTATE_PRESS <const> = 1
local KEYSTATE_REPEAT <const> = 2

local args = ...
local viewport_width = args.width
local viewport_height = args.height

soluna.set_window_title "Miru Component Workbench"

local view = miru.new {
	width = viewport_width,
	height = viewport_height,
	component_path = "example/components/?.lua;example/?.lua;?.lua;?/init.lua",
}
view:text_styles(font.styles())
view:provide("palette", palette)

---@class GalleryInstance : MiruInstance
---@field tick fun(self: GalleryInstance, dt: number)
local gallery = view:mount("gallery", {
	screen_width = viewport_width,
	screen_height = viewport_height,
})
---@cast gallery GalleryInstance

local callback = {}

function callback.window_resize(width, height)
	viewport_width = width
	viewport_height = height
	view:resize(width, height)
	gallery.args.screen_width = width
	gallery.args.screen_height = height
end

function callback.frame()
	local dt = 1 / 60
	gallery:tick(dt)
	view:update(dt)
	view:draw(args.batch)
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
