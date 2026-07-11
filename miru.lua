local matquad = require "soluna.material.quad"
local matclip = require "soluna.material.clip"
local mattext = require "soluna.material.text"
local soluna = require "soluna"
local yoga = require "soluna.layout.yoga"
local floor = math.floor
local min = math.min
local max = math.max
---@class (partial) SolunaFile
---@field searchpath fun(name: string, path: string): string?
---@field load fun(path: string): string?
---@type SolunaFile
---@diagnostic disable-next-line: assign-type-mismatch
local file = require "soluna.file"

local COMPONENT_PATH <const> = "?.lua;?/init.lua"
local TEXT_NOWRAP_WIDTH <const> = 4096
---@type table<string, fun(args: table): fun()>
local components = setmetatable({}, {
	__mode = "v",
})
---@type soluna.MouseCursor
---@diagnostic disable-next-line: assign-type-mismatch
local POINTER_CURSOR <const> = "pointing_hand"
---@type soluna.MouseCursor
---@diagnostic disable-next-line: assign-type-mismatch
local DISABLED_CURSOR <const> = "not_allowed"
local DEFAULT_CURSOR <const> = "default"

---@class MiruCommand
---@field name string
---@field args table
---@field draw fun(batch: MiruBatch)?

---@alias MiruAnimatedTarget fun(): number

---@class (partial) MiruAnimation
---@overload fun(): number
---@field view MiruView
---@field value MiruValue<number>
---@field from number
---@field to number
---@field elapsed number
---@field duration number
---@field easing fun(t: number): number
---@field active boolean?
---@field listed boolean?
---@field stopped boolean?
---@field effect MiruEffect?

---@class MiruRenderNode
---@field kind string
---@field key any
---@field chunk string?
---@field node lightuserdata
---@field parent MiruRenderNode?
---@field children MiruRenderNode[]
---@field cursor integer
---@field instance MiruComponent?
---@field owner MiruComponent?
---@field draw fun(width: number, height: number, frame?: integer)?
---@field commands MiruCommand[]?
---@field props table?
---@field text any
---@field text_layout MiruTextLayout?
---@field text_metrics MiruTextMetrics?
---@field ref MiruRef?
---@field slot_name string?

---@class MiruTextMetrics
---@field height number
---@field width? number
---@field line_height? number
---@field line_count? number

---@class MiruTextLayout: MiruTextMetrics
---@field stream string
---@field query table
---@field height number
---@field width? number
---@field line_height? number
---@field line_count? number
---@field scroll_y number?
---@field vertical_align string
---@field draw fun(self: MiruTextLayout, batch: MiruBatch, x?: number, y?: number, width?: number, height?: number)

---@class MiruTextStyleRegistry
---@field font lightuserdata?
---@field default_font integer?
---@field default string?
---@field [string] table?

---@class MiruTextStyles
---@field font lightuserdata
---@field styles userdata
---@field specs table[]
---@field ids table<string, integer>
---@field default string
---@field builders table<string, MiruTextBuilder?>
---@field derived table<string, MiruTextStyles>?

---@class MiruTextBuilder
---@field block fun(text: string, width?: number, height?: number): string
---@field layout fun(text: string, width?: number, height?: number): table

---@class MiruLayout
---@field x number?
---@field y number?
---@field w number?
---@field h number?

---@alias MiruHitMode "clickable"|"target"|"focusable"|"scrollable"

---@class MiruBatch
---@field layer fun(self: MiruBatch, ...: number)
---@field add fun(self: MiruBatch, ...: any)

---@class (partial) MiruEffect
---@field scope MiruScope
---@field fn fun()
---@field deps table[]
---@field order integer
---@field queued boolean?
---@field queue_order integer?
---@field stopped boolean?

---@class (partial) MiruScope
---@field targets table
---@field active MiruEffect?
---@field queue table<integer, MiruEffect?>
---@field queue_head integer
---@field queue_tail integer
---@field flush_batch MiruEffect[]
---@field flushing true?
---@field after_flush_batch fun()?

---@class (partial) MiruValue<T>
---@overload fun(): T
---@overload fun(value: T)
---@field scope MiruScope
---@field value T

---@alias MiruComputed<T> fun(): T

---@class (partial) MiruComputedState<T>
---@field effect MiruEffect?
---@field value MiruValue<T>

---@alias MiruDisposable MiruComputedState<any>|MiruAnimation

---@class (partial) MiruAnimatedState
---@field animation MiruAnimation
---@field effect MiruEffect?

---@type fun(node: MiruRenderNode)
local dispose_render_instances
---@type fun(component: MiruComponent): MiruComponent
local root_instance
---@type fun(component: MiruComponent): MiruCommand[]
local compile_render_tree
---@type fun(view: MiruView)
local flush_dirty_roots
---@type fun(spec: MiruTextStyleRegistry): MiruTextStyles
local build_text_styles
---@type fun(view: MiruView, root: MiruComponent)
local schedule_render_tree_compile

---@class (partial) MiruInstance
---@field args table

---@class (partial) MiruComponent
---@field ["public"] MiruInstance
---@field view MiruView
---@field parent MiruComponent?
---@field children MiruComponent[]
---@field layout MiruLayout
---@field disposables MiruDisposable[]?
---@field mounted boolean?
---@field effect MiruEffect?
---@field commands MiruCommand[]?
---@field render_node MiruRenderNode?
---@field layout_version MiruValue<integer>
---@field props table
---@field clickable MiruClickable?
---@field focusable MiruFocusable?
---@field scrollable MiruScrollable?
---@field dismissable MiruDismissable?
---@field dismissable_index integer?
---@field prop_bindings MiruPropBinding[]?
---@field targetable true?
---@field hovered MiruValue<boolean>?
---@field pressed MiruValue<boolean>?
---@field focused MiruValue<boolean>?
---@field ref MiruRef?
---@field slot_name string?

---@class (partial) MiruView
---@field scope MiruScope
---@field instances MiruComponent[]
---@field w number
---@field h number
---@field layout_version MiruValue<integer>
---@field pointer_x number?
---@field pointer_y number?
---@field hovered_instance MiruComponent?
---@field hovered_chain MiruComponent[]?
---@field clickable_hovered_instance MiruComponent?
---@field pressed_instance MiruComponent?
---@field pressed_button integer?
---@field focused_instance MiruComponent?
---@field pressed_scrollable_instance MiruComponent?
---@field pressed_scrollable_button integer?
---@field mouse_cursor soluna.MouseCursor?
---@field stats MiruStatistics
---@field provides table
---@field animations MiruAnimation[]
---@field dismissables MiruComponent[]
---@field effect_order integer
---@field slots table<string, MiruComponent?>
---@field frame integer
---@field dirty_roots table<MiruComponent, boolean>
---@field dirty_root_order MiruComponent[]
---@field text_style_registry MiruTextStyles?

---@class MiruContext
---@field view MiruView
---@field instance MiruComponent?
---@field disposables MiruDisposable[]?
---@field drawing boolean?
---@field rendering boolean?
---@field setup_prop_reads table<any, boolean>?

---@class MiruRenderContext
---@field view MiruView
---@field instance MiruComponent
---@field parent MiruRenderNode

---@class MiruPointerEvent
---@field target MiruInstance?
---@field current_target MiruInstance
---@field instance MiruInstance
---@field view MiruView
---@field x number
---@field y number
---@field client_x number
---@field client_y number
---@field local_x number
---@field local_y number
---@field button integer?
---@field scroll_x number?
---@field scroll_y number?

---@class MiruDismissable
---@field enabled? any
---@field on_dismiss? fun(event: MiruPointerEvent)

---@alias MiruCursor soluna.MouseCursor|"default"

---@class MiruClickable
---@field enabled? any
---@field cursor? MiruCursor
---@field on_click? fun(event: MiruPointerEvent)
---@field on_pointer_down? fun(event: MiruPointerEvent)
---@field on_pointer_up? fun(event: MiruPointerEvent)
---@field on_pointer_enter? fun(event: MiruPointerEvent)
---@field on_pointer_leave? fun(event: MiruPointerEvent)
---@field on_pointer_move? fun(event: MiruPointerEvent)

---@class MiruFocusable
---@field enabled? any
---@field on_focus? fun()
---@field on_blur? fun()
---@field on_char? fun(event: table)
---@field on_key? fun(event: table)
---@field on_clipboard_pasted? fun(event: table)

---@class MiruScrollable
---@field enabled? any
---@field on_scroll? fun(event: MiruPointerEvent)
---@field on_pointer_down? fun(event: MiruPointerEvent)
---@field on_pointer_up? fun(event: MiruPointerEvent)
---@field on_pointer_move? fun(event: MiruPointerEvent)

---@class MiruRect
---@field x number
---@field y number
---@field w number
---@field h number

---@class MiruStatistics
---@field render_count integer

---@class MiruPropBinding
---@field target table
---@field fields table<any, string>

---@class (partial) MiruRef
--- A component-owned geometry handle.
--- `rect()` returns the target geometry in the coordinate space of the component that created the ref.
---@field current any
---@field rect fun(self: MiruRef): MiruRect?
---@field window_rect fun(self: MiruRef): MiruRect?

---@class MiruModule
---@field batch MiruBatch
---@field new fun(args?: table): MiruView
---@field value fun(value: any): MiruValue<any>
---@field use fun(name: string): any
---@field text_styles fun(spec: MiruTextStyleRegistry)
---@field mount fun(chunk: string, props?: table, parent?: MiruInstance): MiruInstance
---@field slot fun(name: string, props?: table): MiruInstance
---@field expose fun(methods: table)
---@field box fun(props?: table, children?: fun()): MiruRenderNode
---@field hbox fun(props?: table, children?: fun()): MiruRenderNode
---@field vbox fun(props?: table, children?: fun()): MiruRenderNode
---@field canvas fun(props?: table, draw?: fun(width: number, height: number, frame?: integer)): MiruRenderNode
---@field text fun(text: any, props?: table): MiruRenderNode
---@field clickable fun(props?: MiruClickable)
---@field focusable fun(props?: MiruFocusable)
---@field scrollable fun(props?: MiruScrollable)
---@field dismissable fun(props?: MiruDismissable)
---@field hovered fun(): MiruValue<boolean>
---@field pressed fun(): MiruValue<boolean>
---@field focused fun(): MiruValue<boolean>
---@field ref fun(): MiruRef
---@field computed fun(fn: function): MiruComputed<any>
---@field animated fun(fn: MiruAnimatedTarget, opts?: table): MiruAnimation
---@field lerp fun(a: number, b: number, t: number): number
---@field lerp_color fun(a: integer, b: integer, t: number): integer

---@type MiruContext?
local active

---@type MiruRenderContext?
local active_render

---@type MiruCommand[]?
local active_batch

---@type table<MiruInstance, MiruComponent?>
local component_by_instance = setmetatable({}, {
	__mode = "kv",
})

---@type table<table, MiruComponent?>
local component_by_args = setmetatable({}, {
	__mode = "kv",
})

---@type table<MiruRef, MiruComponent?>
local ref_owners = setmetatable({}, {
	__mode = "kv",
})

---@type table<MiruRef, MiruComponent|MiruRenderNode|nil>
local ref_targets = setmetatable({}, {
	__mode = "kv",
})

---@param instance MiruInstance
---@return MiruComponent
local function component_of(instance)
	local component = component_by_instance[instance]
	assert(component, "stale Miru instance")
	return component
end

---@param target MiruComponent|MiruRenderNode?
---@return MiruInstance?
local function public_target(target)
	if not target or target.node then
		return nil
	end
	---@cast target MiruComponent
	return target.public
end

---@param view MiruView
---@param component MiruComponent
local function register_dismissable(view, component)
	if component.dismissable_index then
		return
	end
	local dismissables = view.dismissables
	local index = #dismissables + 1
	dismissables[index] = component
	component.dismissable_index = index
end

---@param component MiruComponent
local function unregister_dismissable(component)
	local index = component.dismissable_index
	if not index then
		return
	end
	local dismissables = component.view.dismissables
	local last = dismissables[#dismissables]
	dismissables[index] = last
	dismissables[#dismissables] = nil
	if last and last ~= component then
		last.dismissable_index = index
	end
	component.dismissable_index = nil
end

---@param name string
---@param ... any
---@return MiruCommand
local function command(name, ...args)
	return {
		name = name,
		args = args,
	}
end

---@param version MiruValue<integer>
local function bump_version(version)
	-- Version bumps must not subscribe the currently running render effect.
	version(rawget(version, "value") + 1)
end

---@param value number?
---@return integer
local function pixel_size(value)
	return floor((value or 0) + 0.5)
end

---@param value number
---@return number
local function clamp01(value)
	return min(max(value, 0), 1)
end

---@param a number
---@param b number
---@param t number
---@return number
local function lerp(a, b, t)
	return a + (b - a) * t
end

---@type table<any, fun(t: number): number>
local easings <const> = {
	linear = function(t)
		return t
	end,
	out_quad = function(t)
		return 1 - (1 - t) * (1 - t)
	end,
	out_cubic = function(t)
		local u = 1 - t
		return 1 - u * u * u
	end,
	in_out_cubic = function(t)
		if t < 0.5 then
			return 4 * t * t * t
		end
		local u = -2 * t + 2
		return 1 - u * u * u / 2
	end,
}

---@param opts table?
---@return fun(t: number): number
local function easing(opts)
	local name = opts and opts.easing or "out_cubic"
	if type(name) == "function" then
		return name
	end
	local curve = easings[name]
	---@diagnostic disable-next-line: unnecessary-assert, redundant-return-value
	return assert(curve, "unknown easing " .. tostring(name))
end

---@param color integer
---@return integer, integer, integer, integer
local function color_channels(color)
	return (color >> 24) & 0xff, (color >> 16) & 0xff, (color >> 8) & 0xff, color & 0xff
end

---@param a integer
---@param b integer
---@param t number
---@return integer
local function lerp_color(a, b, t)
	t = clamp01(t)
	local aa, ar, ag, ab = color_channels(a)
	local ba, br, bg, bb = color_channels(b)
	local ca = floor(lerp(aa, ba, t) + 0.5)
	local cr = floor(lerp(ar, br, t) + 0.5)
	local cg = floor(lerp(ag, bg, t) + 0.5)
	local cb = floor(lerp(ab, bb, t) + 0.5)
	return (ca << 24) | (cr << 16) | (cg << 8) | cb
end

---@param name string
---@return any
local function use_provide(name)
	---@cast active MiruContext
	local view = active.view
	view.scope:track(view.provides, name)
	local value = view.provides[name]
	if not value then
		error("missing Miru provide: " .. tostring(name), 2)
	end
	return value
end

---@type fun(target: any): MiruRect?
local rect_of

---@class (partial) MiruRef
local Ref = {}; do
	Ref.__index = Ref

	---@return MiruRect?
	function Ref:rect()
		local target = ref_targets[self]
		if not target then
			return nil
		end
		local owner = ref_owners[self]
		if not owner then
			return nil
		end
		if not owner.mounted then
			return nil
		end
		local rect = rect_of(target)
		local base = rect_of(owner)
		if not rect or not base then
			return nil
		end
		return {
			x = rect.x - base.x,
			y = rect.y - base.y,
			w = rect.w,
			h = rect.h,
		}
	end

	---@return MiruRect?
	function Ref:window_rect()
		local target = ref_targets[self]
		if not target then
			return nil
		end
		local owner = ref_owners[self]
		if not owner or not owner.mounted then
			return nil
		end
		local rect = rect_of(target)
		if not rect then
			return nil
		end
		return {
			x = rect.x,
			y = rect.y,
			w = rect.w,
			h = rect.h,
		}
	end
end

---@class (partial) MiruScope
local Scope = {}; do
	---@param effect MiruEffect
	local function cleanup(effect)
		for i = 1, #effect.deps do
			effect.deps[i][effect] = nil
			effect.deps[i] = nil
		end
	end

	Scope.__index = Scope

	---@class (partial) MiruEffect
	local Effect = {}; do
		Effect.__index = Effect
		function Effect:stop()
			if self.stopped then
				return
			end
			self.stopped = true
			self.queued = nil
			self.queue_order = nil
			cleanup(self)
		end
	end

	---@class (partial) MiruValue<T>
	local Value = {}; do
		---@generic T
		---@param self MiruValue<T>
		---@return T
		local function read(self)
			local scope = rawget(self, "scope")
			scope:track(self, "value")
			return rawget(self, "value")
		end

		---@generic T
		---@param self MiruValue<T>
		---@param value T
		local function write(self, value)
			local old = rawget(self, "value")
			if old == value then
				return
			end
			rawset(self, "value", value)
			rawget(self, "scope"):trigger(self, "value")
		end

		---@generic T
		---@return T?
		function Value:__call(...args)
			if args.n == 0 then
				return read(self)
			end
			write(self, table.unpack(args, 1, args.n))
		end

		---@generic T
		---@param key string
		---@return any
		function Value:__index(key)
			if key == "value" then
				return read(self)
			end
			return Value[key]
		end

		---@param key string
		---@param value any
		function Value:__newindex(key, value)
			if key == "value" then
				write(self, value)
				return
			end
			rawset(self, key, value)
		end
	end

	---@param target table
	---@param key string
	function Scope:track(target, key)
		local effect = self.active
		if not effect or effect.stopped then
			return
		end

		local deps = self.targets[target] or {}
		self.targets[target] = deps

		local dep = deps[key] or {}
		deps[key] = dep

		if dep[effect] then
			return
		end

		dep[effect] = true
		effect.deps[#effect.deps + 1] = dep
	end

	---@param effect MiruEffect
	function Scope:schedule(effect)
		if effect.stopped or effect.queued then
			return
		end
		effect.queued = true
		local tail = self.queue_tail + 1
		self.queue_tail = tail
		effect.queue_order = tail
		self.queue[tail] = effect
	end

	---@param target table
	---@param key string
	function Scope:trigger(target, key)
		local deps = self.targets[target]
		if not deps then
			return
		end

		local dep = deps[key]
		if not dep then
			return
		end

		for effect in pairs(dep) do
			self:schedule(effect)
		end
	end

	---@param effect MiruEffect
	function Scope:run(effect)
		if effect.stopped then
			return
		end
		cleanup(effect)
		local prev = self.active
		self.active = effect
		effect.fn()
		self.active = prev
	end

	---@generic T
	---@param value T
	---@return MiruValue<T>
	function Scope:value(value)
		return setmetatable({
			scope = self,
			value = value,
		}, Value)
	end

	---@param fn fun()
	---@param order integer?
	---@return MiruEffect
	function Scope:effect(fn, order)
		---@type MiruEffect
		local effect = setmetatable({
			scope = self,
			fn = fn,
			deps = {},
			order = order or 0,
		}, Effect)
		self:run(effect)
		return effect
	end

	---@param batch MiruEffect[]
	local function clear_batch(batch)
		for i = 1, #batch do
			batch[i] = nil
		end
	end

	---@param self MiruScope
	---@param batch MiruEffect[]
	local function flush(self, batch)
		while true do
			while self.queue_head <= self.queue_tail do
				local count = 0
				while self.queue_head <= self.queue_tail do
					local head = self.queue_head
					local effect = self.queue[head]
					self.queue[head] = nil
					self.queue_head = head + 1
					if effect and not effect.stopped then
						count = count + 1
						batch[count] = effect
					end
				end
				if count > 1 then
					table.sort(batch, function(a, b)
						if a.order == b.order then
							return (a.queue_order or 0) < (b.queue_order or 0)
						end
						return a.order < b.order
					end)
				end
				for i = 1, count do
					local effect = batch[i]
					---@cast effect MiruEffect
					if effect.queued and not effect.stopped then
						effect.queued = nil
						effect.queue_order = nil
						self:run(effect)
					end
				end
				clear_batch(batch)
			end
			if self.after_flush_batch then
				self.after_flush_batch()
			end
			if self.queue_head > self.queue_tail then
				break
			end
		end
		self.queue_head = 1
		self.queue_tail = 0
	end

	function Scope:flush()
		if self.flushing then
			error("recursive view flush", 2)
		end
		self.flushing = true
		local batch = self.flush_batch
		flush(self, batch)
		clear_batch(batch)
		self.flushing = nil
	end
end

---@class (partial) MiruAnimation
local Animation = {}; do
	Animation.__index = Animation

	---@return number
	function Animation:__call()
		return self.value()
	end

	---@param target number
	function Animation:jump(target)
		self.from = target
		self.to = target
		self.elapsed = 0
		self.active = nil
		self.value(target)
	end

	---@param target number
	function Animation:retarget(target)
		local current = rawget(self.value, "value") or target
		if current == target then
			self:jump(target)
			return
		end
		if self.duration <= 0 then
			self:jump(target)
			return
		end
		self.from = current
		self.to = target
		self.elapsed = 0
		self.active = true
		self.view:add_animation(self)
	end

	---@param dt number
	---@return boolean
	function Animation:step(dt)
		if self.stopped or not self.active then
			return false
		end
		self.elapsed = min(self.elapsed + max(dt, 0), self.duration)
		local t = clamp01(self.elapsed / self.duration)
		local value = lerp(self.from, self.to, self.easing(t))
		self.value(value)
		if t >= 1 then
			self:jump(self.to)
			return false
		end
		return true
	end

	function Animation:stop()
		self.stopped = true
		self.active = nil
		if self.effect then
			self.effect:stop()
			self.effect = nil
		end
	end
end

---@param batch MiruBatch
---@param item MiruCommand
local function replay_command(batch, item)
	local draw = item.draw
	if draw then
		draw(batch)
		return
	end
	---@type fun(batch: MiruBatch, ...: any)
	---@diagnostic disable-next-line: undefined-field
	local f = assert(batch[item.name])
	local args = item.args
	f(batch, table.unpack(args, 1, args.n))
end

---@param batch MiruBatch
---@param commands MiruCommand[]?
local function replay_commands(batch, commands)
	if not commands then
		return
	end
	for i = 1, #commands do
		replay_command(batch, commands[i])
	end
end

---@class (partial) MiruView
local View = {}; do
	View.__index = View

	---@type fun(view: MiruView, cursor?: soluna.MouseCursor)
	local set_mouse_cursor
	---@type fun(view: MiruView, target: MiruComponent?)
	local set_focused

	---@param value MiruValue<boolean>?
	---@param state boolean
	local function set_state(value, state)
		if value then
			value(state)
		end
	end

	---@param target MiruComponent?
	---@param boundary MiruComponent
	---@return boolean
	local function target_inside(target, boundary)
		while target do
			if target == boundary then
				return true
			end
			target = target.parent
		end
		return false
	end

	---@class (partial) MiruInstance
	local Instance = {}; do
		Instance.__index = Instance

		---@return number, number
		function Instance:origin()
			return component_of(self):origin()
		end

		---@return MiruRect?
		function Instance:rect()
			local component = component_by_instance[self]
			return component and rect_of(component) or nil
		end

		function Instance:destroy()
			local component = component_by_instance[self]
			if component then
				component:destroy()
			end
		end
	end

	---@class (partial) MiruComponent
	local Component = {}; do
		Component.__index = Component

		---@return number, number
		function Component:origin()
			local node = assert(self.render_node)
			local x, y = yoga.node_get(node.node)
			return x, y
		end

		---@return MiruRect?
		function Component:rect()
			return rect_of(self)
		end

		---@param batch MiruBatch
		function Component:draw(batch)
			replay_commands(batch, self.commands)
		end

		---@param disposing_render_tree boolean?
		function Component:destroy(disposing_render_tree)
			if not self.mounted then
				return
			end
			local view = self.view
			local render_node = self.render_node
			local slot_name = self.slot_name
			if slot_name and view.slots[slot_name] == self then
				view.slots[slot_name] = nil
			end
			local from_render_tree = disposing_render_tree
			local root = not from_render_tree and self.parent and root_instance(self) or nil
			self.render_node = nil
			if target_inside(view.hovered_instance, self) then
				for _, instance in ipairs(view.hovered_chain or {}) do
					set_state(instance.hovered, false)
				end
				view.hovered_instance = nil
				view.hovered_chain = nil
			elseif view.hovered_chain then
				for i = #view.hovered_chain, 1, -1 do
					if view.hovered_chain[i] == self then
						set_state(self.hovered, false)
						table.remove(view.hovered_chain, i)
						break
					end
				end
			end
			if view.clickable_hovered_instance == self then
				view.clickable_hovered_instance = nil
			end
			if not view.hovered_instance and not view.clickable_hovered_instance then
				set_mouse_cursor(view, nil)
			end
			if view.pressed_instance == self then
				view.pressed_instance = nil
				view.pressed_button = nil
			end
			if view.pressed_scrollable_instance == self then
				view.pressed_scrollable_instance = nil
				view.pressed_scrollable_button = nil
			end
			if view.focused_instance == self then
				set_focused(view, nil)
			end
			unregister_dismissable(self)
			self.mounted = nil
			if self.ref and ref_targets[self.ref] == self then
				ref_targets[self.ref] = nil
				self.ref.current = nil
			end
			self.ref = nil
			component_by_instance[self.public] = nil
			component_by_args[self.public.args] = nil
			if self.effect then
				self.effect:stop()
				self.effect = nil
			end
			if self.disposables then
				for i = #self.disposables, 1, -1 do
					self.disposables[i]:stop()
					self.disposables[i] = nil
				end
				self.disposables = nil
			end
			if render_node and not from_render_tree then
				render_node.instance = nil
				dispose_render_instances(render_node)
				if render_node.parent then
					for i = #render_node.parent.children, 1, -1 do
						if render_node.parent.children[i] == render_node then
							table.remove(render_node.parent.children, i)
							break
						end
					end
					yoga.node_remove(render_node.parent.node, render_node.node)
				else
					for i = #view.instances, 1, -1 do
						if view.instances[i] == self then
							table.remove(view.instances, i)
							break
						end
					end
				end
				yoga.node_free(render_node.node)
			end
			local parent = self.parent
			if parent then
				for i = #parent.children, 1, -1 do
					if parent.children[i] == self then
						table.remove(parent.children, i)
						break
					end
				end
			end
			if root and root.mounted then
				schedule_render_tree_compile(view, root)
			end
			self.commands = nil
		end
	end

	---@param holder table
	---@param ref MiruRef?
	---@param current MiruComponent|MiruRenderNode
	local function bind_ref(holder, ref, current)
		local old = holder.ref
		if old ~= ref and old and ref_targets[old] == current then
			ref_targets[old] = nil
			old.current = nil
		end
		holder.ref = ref
		if ref then
			ref_targets[ref] = current
			ref.current = public_target(current)
		end
	end

	---@type fun(component: MiruComponent, x: number, y: number, mode: MiruHitMode): MiruComponent?, number?, number?
	local hit_instance
	---@type fun(node: MiruRenderNode, x: number, y: number, mode: MiruHitMode): MiruComponent?, number?, number?
	local hit_render_node

	---@param view MiruView
	---@param cursor? soluna.MouseCursor
	function set_mouse_cursor(view, cursor)
		if view.mouse_cursor == cursor then
			return
		end
		view.mouse_cursor = cursor
		soluna.set_mouse_cursor(cursor)
	end

	---@param instance MiruComponent
	---@return boolean
	local function clickable_enabled(instance)
		local clickable = instance.clickable
		if not clickable then
			return false
		end
		local enabled = clickable.enabled
		return not rawequal(enabled, false)
	end

	---@param instance MiruComponent
	---@return boolean
	local function focusable_enabled(instance)
		local focusable = instance.focusable
		if not focusable then
			return false
		end
		local enabled = focusable.enabled
		return not rawequal(enabled, false)
	end

	---@param instance MiruComponent
	---@return boolean
	local function scrollable_enabled(instance)
		local scrollable = instance.scrollable
		if not scrollable then
			return false
		end
		local enabled = scrollable.enabled
		return not rawequal(enabled, false)
	end

	---@param instance MiruComponent?
	---@return soluna.MouseCursor?
	local function clickable_cursor(instance)
		local clickable = instance and instance.clickable or nil
		if not clickable then
			return nil
		end
		---@cast instance MiruComponent
		if not clickable_enabled(instance) then
			return DISABLED_CURSOR
		end
		local cursor = clickable.cursor
		if cursor == DEFAULT_CURSOR then
			return nil
		end
		return cursor or POINTER_CURSOR
	end

	---@param instance MiruComponent
	---@param mode MiruHitMode
	---@return boolean
	local function instance_hittable(instance, mode)
		if mode == "target" then
			return instance.targetable and true or false
		elseif mode == "clickable" then
			return instance.clickable and true or false
		elseif mode == "focusable" then
			return instance.focusable and true or false
		elseif mode == "scrollable" then
			return instance.scrollable and true or false
		end
		return false
	end

	---@param target MiruComponent?
	---@param current_target MiruComponent
	---@param x number
	---@param y number
	---@param button integer?
	---@return MiruPointerEvent
	local function pointer_event(target, current_target, x, y, client_x, client_y, button)
		local current_public = current_target.public
		return {
			target = target and target.public or nil,
			current_target = current_public,
			instance = current_public,
			view = current_target.view,
			x = x,
			y = y,
			client_x = client_x,
			client_y = client_y,
			local_x = x,
			local_y = y,
			button = button,
		}
	end

	---@param instance MiruComponent
	---@param name string
	---@param event MiruPointerEvent
	local function call_clickable(instance, name, event)
		local clickable = instance.clickable
		if not clickable then
			return
		end
		---@type fun(event: MiruPointerEvent)?
		---@diagnostic disable-next-line: undefined-field
		local callback = clickable[name]
		if callback then
			callback(event)
		end
	end

	---@param instance MiruComponent
	---@param name string
	---@param event? table
	local function call_focusable(instance, name, event)
		local focusable = instance.focusable
		if not focusable then
			return
		end
		---@type fun(event?: table)?
		---@diagnostic disable-next-line: undefined-field
		local callback = focusable[name]
		if callback then
			callback(event)
		end
	end

	---@param instance MiruComponent
	---@param name string
	---@param event MiruPointerEvent
	local function call_scrollable(instance, name, event)
		local scrollable = instance.scrollable
		if not scrollable then
			return
		end
		---@type fun(event: MiruPointerEvent)?
		---@diagnostic disable-next-line: undefined-field
		local callback = scrollable[name]
		if callback then
			callback(event)
		end
	end

	---@param view MiruView
	---@param target MiruComponent?
	function set_focused(view, target)
		if target and not focusable_enabled(target) then
			target = nil
		end
		local old = view.focused_instance
		if old == target then
			return
		end
		if old then
			set_state(old.focused, false)
			if old.mounted then
				call_focusable(old, "on_blur")
			end
		end
		view.focused_instance = target
		if target then
			set_state(target.focused, true)
			call_focusable(target, "on_focus")
		end
	end

	---@param target MiruComponent?
	---@param current_target MiruComponent
	---@param x number
	---@param y number
	---@param button integer?
	---@return MiruPointerEvent
	local function pointer_event_at(target, current_target, x, y, button)
		local ox, oy = current_target:origin()
		return pointer_event(target, current_target, x - ox, y - oy, x, y, button)
	end

	---@param instance MiruComponent
	---@return boolean
	local function dismissable_enabled(instance)
		local dismissable = instance.dismissable
		if not dismissable then
			return false
		end
		local enabled = dismissable.enabled
		return not rawequal(enabled, false)
	end

	---@param instance MiruComponent
	---@param target MiruComponent?
	---@param x number
	---@param y number
	---@param button integer?
	local function call_dismissable(instance, target, x, y, button)
		local dismissable = instance.dismissable
		if not dismissable then
			return
		end
		local callback = dismissable.on_dismiss
		if callback then
			callback(pointer_event_at(target, instance, x, y, button))
		end
	end

	---@param view MiruView
	---@param target MiruComponent?
	---@param x number
	---@param y number
	---@param button integer?
	local function notify_dismissable(view, target, x, y, button)
		local dismissables = view.dismissables
		for i = #dismissables, 1, -1 do
			local instance = dismissables[i]
			if instance.mounted and dismissable_enabled(instance) and not target_inside(target, instance) then
				call_dismissable(instance, target, x, y, button)
			end
		end
	end

	rect_of = function(target)
		if not target then
			return nil
		end
		if target.node then
			---@cast target MiruRenderNode
			local x, y, w, h = yoga.node_get(target.node)
			return {
				x = x,
				y = y,
				w = w,
				h = h,
			}
		end
		---@cast target MiruComponent
		local node = assert(target.render_node)
		local x, y, w, h = yoga.node_get(node.node)
		return {
			x = x,
			y = y,
			w = w,
			h = h,
		}
	end

	---@param instance MiruComponent
	---@param x number
	---@param y number
	---@param mode MiruHitMode
	---@return MiruComponent?, number?, number?
	hit_instance = function(instance, x, y, mode)
		if not instance.mounted then
			return nil, nil, nil
		end
		if instance.render_node then
			local target, tx, ty = hit_render_node(instance.render_node, x, y, mode)
			if target then
				return target, tx, ty
			end
		end
		return nil, nil, nil
	end

	---@param node MiruRenderNode
	---@param x number
	---@param y number
	---@param mode MiruHitMode
	---@return MiruComponent?, number?, number?
	hit_render_node = function(node, x, y, mode)
		local nx, ny, nw, nh = yoga.node_get(node.node)
		local props = node.props
		local clips_overflow = props and (props.overflow == "hidden" or props.overflow == "scroll")
		local inside_clip = x >= nx and x <= nx + nw and y >= ny and y <= ny + nh
		if clips_overflow and not inside_clip then
			return nil, nil, nil
		end
		for i = #node.children, 1, -1 do
			local child = node.children[i]
			local target, tx, ty = hit_render_node(child, x, y, mode)
			if target then
				return target, tx, ty
			end
		end
		if node.kind == "component" and node.instance then
			local lx = x - nx
			local ly = y - ny
			local component = node.instance
			if lx >= 0 and lx <= nw and ly >= 0 and ly <= nh and instance_hittable(component, mode) then
				return component, lx, ly
			end
		end
		return nil, nil, nil
	end

	---@param view MiruView
	---@param x number
	---@param y number
	---@param mode MiruHitMode
	---@return MiruComponent?, number?, number?
	local function hit_view(view, x, y, mode)
		for i = #view.instances, 1, -1 do
			local target, tx, ty = hit_instance(view.instances[i], x, y, mode)
			if target then
				return target, tx, ty
			end
		end
		return nil, nil, nil
	end

	---@param view MiruView
	---@param x number
	---@param y number
	---@return MiruComponent?, number?, number?
	local function hit_target_view(view, x, y)
		return hit_view(view, x, y, "target")
	end

	---@param view MiruView
	---@param target MiruComponent?
	local function set_hovered(view, target)
		local old = view.hovered_instance
		if old == target then
			return
		end
		local next_chain = {}
		local current = target
		while current do
			next_chain[#next_chain + 1] = current
			current = current.parent
		end
		for _, instance in ipairs(view.hovered_chain or {}) do
			if not target_inside(target, instance) then
				set_state(instance.hovered, false)
			end
		end
		view.hovered_instance = target
		view.hovered_chain = next_chain
		for _, instance in ipairs(next_chain) do
			set_state(instance.hovered, true)
		end
	end

	---@param view MiruView
	---@param target MiruComponent?
	---@param x number?
	---@param y number?
	local function set_clickable_hovered(view, target, x, y)
		local old = view.clickable_hovered_instance
		if old == target then
			return
		end
		if old then
			if old.mounted then
				call_clickable(old, "on_pointer_leave", pointer_event_at(old, old, x or 0, y or 0))
			end
		end
		view.clickable_hovered_instance = target
		if target then
			call_clickable(target, "on_pointer_enter", pointer_event_at(target, target, x or 0, y or 0))
		end
	end

	local layout_keys <const> = {
		"width",
		"height",
		"minWidth",
		"maxWidth",
		"minHeight",
		"maxHeight",
		"flex",
		"justify",
		"alignItems",
		"alignContent",
		"alignSelf",
		"margin",
		"padding",
		"border",
		"gap",
		"wrap",
		"display",
		"position",
		"overflow",
		"top",
		"bottom",
		"left",
		"right",
		"aspectRatio",
	}

	---@param props table?
	---@param direction string?
	---@return table
	local function layout_style(props, direction)
		props = props or {}
		local style = {}
		if direction then
			style.direction = direction
		end
		for i = 1, #layout_keys do
			local key = layout_keys[i]
			local value = props[key]
			if value then
				style[key] = value
			end
		end
		return style
	end

	---@param node MiruRenderNode
	function dispose_render_instances(node)
		bind_ref(node, nil, node)
		if node.instance then
			local instance = node.instance
			node.instance = nil
			if instance.render_node == node then
				instance.render_node = nil
			end
			instance:destroy(true)
		end
		for i = 1, #node.children do
			dispose_render_instances(node.children[i])
		end
	end

	---@param parent MiruRenderNode
	---@param index integer
	local function remove_render_child(parent, index)
		local node = parent.children[index]
		if not node then
			return
		end
		dispose_render_instances(node)
		yoga.node_remove(parent.node, node.node)
		yoga.node_free(node.node)
		table.remove(parent.children, index)
	end

	---@param parent MiruRenderNode
	---@param index integer
	local function remove_render_children_from(parent, index)
		for i = #parent.children, index, -1 do
			remove_render_child(parent, i)
		end
	end

	local mount_component
	local patch_props

	-- Render nodes patch the Yoga tree by sibling order plus optional key.
	-- Component nodes keep their setup instance and only patch props on rerender.
	---@param ctx MiruRenderContext
	---@param kind string
	---@param key any
	---@param props table?
	---@param direction string?
	---@return MiruRenderNode
	local function render_element(ctx, kind, key, props, direction)
		local parent = ctx.parent
		local index = parent.cursor
		parent.cursor = index + 1

		local node = parent.children[index]
		if node and (node.kind ~= kind or node.key ~= key) then
			remove_render_children_from(parent, index)
			node = nil
		end
		if not node then
			node = {
				kind = kind,
				key = key,
				node = yoga.node_new(parent.node),
				parent = parent,
				owner = ctx.instance,
				children = {},
				cursor = 1,
			}
			parent.children[index] = node
		end
		node.props = props
		bind_ref(node, props and props.ref, node)
		yoga.node_set(node.node, layout_style(props, direction))
		return node
	end

	---@param ctx MiruRenderContext
	---@param node MiruRenderNode
	---@param children fun()?
	local function render_children(ctx, node, children)
		local prev = ctx.parent
		ctx.parent = node
		node.cursor = 1
		if children then
			children()
		end
		remove_render_children_from(node, node.cursor)
		ctx.parent = prev
	end

	---@param component MiruComponent
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	local function set_instance_layout(component, x, y, w, h)
		local layout = component.layout
		if layout.x == x and layout.y == y and layout.w == w and layout.h == h then
			return
		end
		layout.x = x
		layout.y = y
		layout.w = w
		layout.h = h
		bump_version(component.layout_version)
	end

	---@param node MiruRenderNode
	---@param width number
	---@param height number
	local function run_canvas(node, width, height)
		local draw = node.draw
		if not draw then
			node.commands = nil
			return
		end
		local commands = node.commands or {}
		for i = 1, #commands do
			commands[i] = nil
		end
		node.commands = commands
		local owner = assert(node.owner)
		local prev = active_batch
		local prev_active = active
		active_batch = commands
		active = {
			view = owner.view,
			instance = owner,
			drawing = true,
		}
		draw(width, height, owner.view.frame)
		active = prev_active
		active_batch = prev
	end

	---@type table<string, true?>
	local TEXT_STYLE_RESERVED <const> = {
		font = true,
		default_font = true,
		default = true,
	}
	local DEFAULT_TEXT_SIZE <const> = 16
	local DEFAULT_TEXT_COLOR <const> = 0xff000000
	local DEFAULT_TEXT_ALIGN <const> = "LT"

	local TextLayout = {}
	TextLayout.__index = TextLayout

	local function text_style_tag(id)
		if id == 0 then
			return "[s]"
		end
		return "[s" .. tostring(id) .. "]"
	end

	local function escape_text_chunk(text)
		return tostring(text or ""):gsub("%[", "[[")
	end

	---@param styles MiruTextStyles
	---@param align string
	---@return table
	local function text_builder(styles, align)
		local builders = styles.builders
		local builder = builders[align]
		if builder then
			return builder
		end
		local block, layout = mattext.block(styles.styles, align)
		builder = {
			block = block,
			layout = layout,
		}
		builders[align] = builder
		return builder
	end

	local function text_style_id(styles, name)
		name = name or styles.default
		local id = styles.ids[name]
		assert(id, "unknown Miru text style " .. tostring(name))
		return id
	end

	local function text_style_key(base_id, style)
		return table.concat({
			base_id,
			style.font or "",
			style.size or "",
			style.color or "",
			style.line_height or "",
		}, ":")
	end

	---@param styles MiruTextStyles
	---@param props table
	---@return MiruTextStyles, integer
	local function text_node_styles(styles, props)
		local base_id = text_style_id(styles, props.style)
		if not (props.font or props.size or props.color or props.line_height) then
			return styles, base_id
		end

		local base = assert(styles.specs[base_id + 1], "missing Miru base text style")
		local style = {
			font = props.font or base.font,
			size = props.size or base.size,
			color = props.color or base.color,
			line_height = props.line_height or base.line_height,
		}
		local key = text_style_key(base_id, style)
		local derived = styles.derived and styles.derived[key]
		if derived then
			return derived, #derived.specs - 1
		end

		local style_array = {}
		for i = 1, #styles.specs do
			style_array[i] = styles.specs[i]
		end
		style_array[#style_array + 1] = style
		derived = {
			font = styles.font,
			styles = mattext.styles(styles.font, style_array),
			specs = style_array,
			ids = styles.ids,
			default = styles.default,
			builders = {},
		}
		local cache = styles.derived
		if cache then
			cache[key] = derived
		end
		return derived, #style_array - 1
	end

	local function append_style(chunks, current, id)
		if current.value == id then
			return
		end
		chunks[#chunks + 1] = text_style_tag(id)
		current.value = id
	end

	local function append_named_string(chunks, styles, text, base_id, current)
		text = tostring(text or "")
		local position = 1
		while true do
			local open = text:find("%[", position)
			if not open then
				chunks[#chunks + 1] = escape_text_chunk(text:sub(position))
				return
			end
			chunks[#chunks + 1] = escape_text_chunk(text:sub(position, open - 1))
			local next_char = text:sub(open + 1, open + 1)
			if next_char == "[" then
				chunks[#chunks + 1] = "[["
				position = open + 2
			else
				local close = text:find("%]", open + 1)
				if close then
					local name = text:sub(open + 1, close - 1)
					if name == "n" then
						append_style(chunks, current, base_id)
					else
						local id = styles.ids[name]
						if id then
							append_style(chunks, current, id)
						else
							chunks[#chunks + 1] = "[" .. name .. "]"
						end
					end
					position = close + 1
				else
					chunks[#chunks + 1] = "[["
					position = open + 1
				end
			end
		end
	end

	local function compile_text(text, styles, base_id)
		local chunks = {}
		local current = {
			value = 0,
		}
		append_style(chunks, current, base_id)
		append_named_string(chunks, styles, text, base_id, current)
		return table.concat(chunks)
	end

	local function text_alignment(value)
		local align = tostring(value or DEFAULT_TEXT_ALIGN):upper()
		local horizontal = "L"
		local vertical = "T"
		for i = 1, #align do
			local c = align:sub(i, i)
			if c == "C" or c == "R" then
				horizontal = c
			elseif c == "V" or c == "B" then
				vertical = c
			end
		end
		return horizontal .. "T", vertical
	end

	local function text_vertical_offset(vertical, content_height, viewport_height)
		if not viewport_height or viewport_height <= content_height then
			return 0
		end
		if vertical == "V" then
			return floor((viewport_height - content_height) / 2)
		elseif vertical == "B" then
			return viewport_height - content_height
		end
		return 0
	end

	function TextLayout:draw(batch, x, y, width, height)
		x = x or 0
		y = y or 0
		local scroll_y = pixel_size(self.scroll_y)
		local viewport_width = width and pixel_size(width) or nil
		local viewport_height = height and pixel_size(height) or nil
		local offset_y = scroll_y == 0 and text_vertical_offset(self.vertical_align, self.height, viewport_height) or 0
		if scroll_y > 0
			or (viewport_width and viewport_width < self.width)
			or (viewport_height and viewport_height < self.height)
		then
			if viewport_width and viewport_width > 0 and viewport_height and viewport_height > 0 then
				batch:add(matclip.rect(viewport_width, viewport_height), x, y)
				batch:add(self.stream, x, y + offset_y - scroll_y)
				batch:add(matclip.rect())
			end
			return
		end
		batch:add(self.stream, x, y + offset_y)
	end

	---@param spec MiruTextStyleRegistry
	---@return MiruTextStyles
	function build_text_styles(spec)
		assert(type(spec) == "table", "Miru text_styles requires a table")
		local fontcobj = assert(spec.font, "Miru text_styles requires .font")
		local default_font = assert(spec.default_font, "Miru text_styles requires .default_font")
		local default_name = spec.default or "body"
		local names = {}
		for name, value in pairs(spec) do
			if not TEXT_STYLE_RESERVED[name] and type(value) == "table" and name ~= default_name then
				names[#names + 1] = name
			end
		end
		table.sort(names)
		table.insert(names, 1, default_name)

		---@type table<string, table?>
		local resolved = {}
		---@type table<string, true?>
		local resolving = {}
		local function resolve(name)
			local style = resolved[name]
			if style then
				return style
			end
			assert(not resolving[name], "cyclic Miru text style " .. tostring(name))
			local source = assert(spec[name], "missing Miru text style " .. tostring(name))
			resolving[name] = true
			local parent
			if source.based_on then
				parent = resolve(source.based_on)
			elseif name ~= default_name then
				parent = resolve(default_name)
			end
			style = {
				font = source.font or parent and parent.font or default_font,
				size = source.size or parent and parent.size or DEFAULT_TEXT_SIZE,
				color = source.color or parent and parent.color or DEFAULT_TEXT_COLOR,
				line_height = source.line_height or parent and parent.line_height,
			}
			resolving[name] = nil
			resolved[name] = style
			return style
		end

		local ids = {}
		local style_array = {}
		for i = 1, #names do
			local name = names[i]
			local style = resolve(name)
			ids[name] = i - 1
			style_array[i] = style
		end
		return {
			font = fontcobj,
			styles = mattext.styles(fontcobj, style_array),
			specs = style_array,
			ids = ids,
			default = default_name,
			builders = {},
			derived = {},
		}
	end

	---@param node MiruRenderNode
	---@return MiruTextStyles
	local function text_styles(node)
		local owner = assert(node.owner)
		local registry = owner.view.text_style_registry
		assert(registry, "missing Miru text styles")
		return registry
	end

	---@param node MiruRenderNode
	---@param width number
	---@param _height number
	---@return MiruTextLayout
	local function build_text_layout(node, width, _height)
		local styles = text_styles(node)
		local props = node.props or {}
		local align, vertical_align = text_alignment(props.align)
		local base_id
		styles, base_id = text_node_styles(styles, props)
		local builder = text_builder(styles, align)
		local w = max(1, pixel_size(width))
		local layout_width = w
		if props.wrap == false then
			layout_width = max(layout_width, TEXT_NOWRAP_WIDTH)
		end
		local text = compile_text(node.text, styles, base_id)
		local stream = builder.block(text, layout_width)
		local query = builder.layout(text, layout_width)
		---@type MiruTextLayout
		local layout = setmetatable({
			stream = stream,
			query = query,
			width = layout_width,
			height = query:height(),
			line_height = query:line_height(),
			line_count = query:line_count(),
			scroll_y = props.scroll_y,
			vertical_align = vertical_align,
		}, TextLayout)
		node.text_layout = layout
		node.text_metrics = layout
		return layout
	end

	---@param node MiruRenderNode
	---@return boolean
	local function resolve_text_layout(node)
		local _, _, width, height = yoga.node_get(node.node)
		build_text_layout(node, width, height)
		local props = node.props
		if props and props.height then
			return false
		end
		local measured_height = max(0, pixel_size(assert(node.text_metrics).height))
		if pixel_size(height) == measured_height then
			return false
		end
		local style = layout_style(props)
		style.height = measured_height
		yoga.node_set(node.node, style)
		return true
	end

	---@param node MiruRenderNode
	---@return boolean
	local function resolve_text_layouts(node)
		local changed = false
		if node.kind == "text" and resolve_text_layout(node) then
			changed = true
		end
		for i = 1, #node.children do
			if resolve_text_layouts(node.children[i]) then
				changed = true
			end
		end
		return changed
	end

	---@param background any
	---@param width number
	---@param height number
	---@return MiruCommand?
	local function background_command(background, width, height)
		if not background then
			return nil
		end
		---@type integer
		local w = pixel_size(width)
		---@type integer
		local h = pixel_size(height)
		if w <= 0 or h <= 0 then
			return nil
		end
		assert(type(background) == "number")
		---@cast background integer
		local color = background
		return command("add", matquad.quad(w, h, color), 0, 0)
	end

	---@param node MiruRenderNode
	---@param width number
	---@param height number
	---@return MiruCommand
	local function text_command(node, width, height)
		local layout = assert(node.text_layout)
		return {
			name = "text",
			args = {},
			draw = function(batch)
				layout:draw(batch, 0, 0, pixel_size(width), pixel_size(height))
			end,
		}
	end

	---@param props table?
	---@return number, number, number, number
	local function draw_transform(props)
		if not props then
			return 0, 0, 1, 0
		end
		return props.translateX or 0, props.translateY or 0, props.scale or 1, props.rotation or 0
	end

	---@param node MiruRenderNode
	---@param out MiruCommand[]
	---@param parent_x number
	---@param parent_y number
	local function compile_render_node(node, out, parent_x, parent_y)
		local x, y, w, h = yoga.node_get(node.node)
		local local_x = x - parent_x
		local local_y = y - parent_y
		local props = node.props
		local translate_x, translate_y, scale, rotation = draw_transform(props)
		local draw_x = local_x + translate_x
		local draw_y = local_y + translate_y
		if node.kind == "component" or node.kind == "slot" then
			set_instance_layout(assert(node.instance), 0, 0, w, h)
		end

		if scale ~= 1 or rotation ~= 0 then
			out[#out + 1] = command("layer", scale, rotation, draw_x, draw_y)
		else
			out[#out + 1] = command("layer", draw_x, draw_y)
		end
		if props and props.background then
			local bg = background_command(props.background, w, h)
			if bg then
				out[#out + 1] = bg
			end
		end
		local clips_overflow = props
			and (props.overflow == "hidden" or props.overflow == "scroll")
			and w > 0
			and h > 0
			and (node.kind == "text" or node.kind == "canvas" or #node.children > 0)
		if clips_overflow then
			out[#out + 1] = command("add", matclip.rect(w, h), 0, 0)
		end
		if node.kind == "text" then
			out[#out + 1] = text_command(node, w, h)
		end
		if node.kind == "canvas" then
			if props and props.live then
				out[#out + 1] = {
					name = "canvas",
					args = {},
					draw = function(batch)
						run_canvas(node, w, h)
						replay_commands(batch, node.commands)
					end,
				}
			else
				run_canvas(node, w, h)
				local commands = node.commands
				if commands then
					for i = 1, #commands do
						out[#out + 1] = commands[i]
					end
				end
			end
		end
		for i = 1, #node.children do
			compile_render_node(node.children[i], out, x, y)
		end
		if clips_overflow then
			out[#out + 1] = command("add", matclip.rect())
		end
		out[#out + 1] = command "layer"
	end

	---@param component MiruComponent
	---@return MiruCommand[]
	function compile_render_tree(component)
		local root = assert(component.render_node)
		if not root.parent then
			local style = layout_style(root.props)
			if not style.width then
				style.width = component.view.w
			end
			if not style.height then
				style.height = component.view.h
			end
			yoga.node_set(root.node, style)
		end
		yoga.node_calc(root.node)
		if resolve_text_layouts(root) then
			yoga.node_calc(root.node)
		end

		local out = {}
		local prev = active
		if not prev then
			active = {
				view = component.view,
				instance = component,
				drawing = true,
			}
		end
		compile_render_node(root, out, 0, 0)
		active = prev
		return out
	end

	---@param view MiruView
	function flush_dirty_roots(view)
		local order = view.dirty_root_order
		local dirty = view.dirty_roots
		for i = 1, #order do
			local root = order[i]
			order[i] = nil
			dirty[root] = nil
			if root.mounted and root.render_node then
				local prev_active = active
				local prev_effect = view.scope.active
				active = {
					view = view,
					instance = root,
				}
				view.scope.active = root.effect
				local commands = compile_render_tree(root)
				active = prev_active
				view.scope.active = prev_effect
				root.commands = commands
			end
		end
	end

	---@param view MiruView
	---@param root MiruComponent
	function schedule_render_tree_compile(view, root)
		if not root.mounted then
			return
		end
		if not view.dirty_roots[root] then
			view.dirty_roots[root] = true
			view.dirty_root_order[#view.dirty_root_order + 1] = root
		end
		if not view.scope.flushing then
			flush_dirty_roots(view)
		end
	end

	---@param props table?
	---@return MiruLayout
	local function layout(props)
		props = props or {}
		return {
			x = props.x,
			y = props.y,
			w = props.width,
			h = props.height,
		}
	end

	---@param component MiruComponent
	---@param key string
	---@param value any
	local function set_prop(component, key, value)
		local props = component.props
		if props[key] == value then
			return
		end
		props[key] = value
		local prop_bindings = component.prop_bindings
		if prop_bindings then
			for i = 1, #prop_bindings do
				local binding = prop_bindings[i]
				local field = rawget(binding.fields, key)
				if field then
					binding.target[field] = value
				end
			end
		end
		component.view.scope:trigger(props, key)
	end

	---@param component MiruComponent
	---@param props table?
	function patch_props(component, props)
		props = props or {}
		for key in pairs(component.props) do
			local value = props[key]
			if not value and not rawequal(value, false) then
				set_prop(component, key, nil)
			end
		end
		for key, value in pairs(props) do
			set_prop(component, key, value)
		end
	end

	local args_metatable <const> = {
		__index = function(args, key)
			local component = component_by_args[args]
			assert(component, "stale Miru args")
			local props = component.props
			local context = active
			if context and context.instance == component and context.setup_prop_reads then
				context.setup_prop_reads[key] = true
			else
				component.view.scope:track(props, key)
			end
			return props[key]
		end,
		__newindex = function(args, key, value)
			local component = component_by_args[args]
			assert(component, "stale Miru args")
			set_prop(component, key, value)
		end,
		__pairs = function(args)
			local component = component_by_args[args]
			assert(component, "stale Miru args")
			return next, component.props
		end,
	}

	---@param component MiruComponent
	---@return table
	local function component_args(component)
		local args = setmetatable({}, args_metatable)
		component_by_args[args] = component
		return args
	end

	---@param component MiruComponent
	---@return MiruComponent
	function root_instance(component)
		while component.parent do
			component = component.parent
		end
		return component
	end

	---@param view MiruView
	---@param chunk string
	---@param props table?
	---@param parent MiruComponent?
	---@param render_node MiruRenderNode
	---@return MiruComponent
	function mount_component(view, chunk, props, parent, render_node)
		local path = assert(file.searchpath(chunk, view.provides.component_path))
		local factory = components[path]
		if not factory then
			local source = assert(file.load(path))
			---@diagnostic disable-next-line: assign-type-mismatch
			factory = assert(load(source, "@" .. path, "t"))
			assert(type(factory) == "function")
			components[path] = factory
		end

		local order = view.effect_order + 1
		view.effect_order = order

		local public = setmetatable({}, Instance)
		---@type MiruComponent
		local component = setmetatable({
			public = public,
			view = view,
			parent = parent,
			children = {},
			layout = layout(props),
			disposables = {},
			mounted = true,
			layout_version = view.scope:value(0),
			props = {},
			render_node = render_node,
		}, Component)
		component_by_instance[public] = component
		render_node.instance = component
		public.args = component_args(component)
		patch_props(component, props)
		render_node.props = component.props
		bind_ref(component, props and props.ref, component)

		local prev = active
		local prev_effect = view.scope.active
		---@type MiruContext
		active = {
			view = view,
			instance = component,
			disposables = component.disposables,
			setup_prop_reads = {},
		}
		view.scope.active = nil
		local draw = factory(public.args)
		view.scope.active = prev_effect
		active = prev
		assert(type(draw) == "function")
		local ctx

		component.effect = view.scope:effect(function()
			if not component.mounted then
				return
			end
			local nested_render = active_render
			if not component.parent then
				view.layout_version()
			end
			component.layout_version()
			---@diagnostic disable-next-line: redefined-local
			local prev = active
			local prev_render = active_render
			---@type MiruContext
			ctx = ctx or {
				view = view,
				instance = component,
				drawing = true,
				rendering = true,
			}
			local parent_node = assert(component.render_node)
			local render_ctx = {
				view = view,
				instance = component,
				parent = parent_node,
			}
			active = ctx
			active_render = render_ctx
			view.stats.render_count = view.stats.render_count + 1
			render_ctx.parent.cursor = 1
			draw()
			remove_render_children_from(render_ctx.parent, render_ctx.parent.cursor)
			if not nested_render then
				schedule_render_tree_compile(view, root_instance(component))
			end
			active = prev
			active_render = prev_render
		end, order)

		return component
	end

	---@param chunk string
	---@param props table?
	---@param parent MiruInstance?
	---@return MiruInstance
	function View:mount(chunk, props, parent)
		local parent_component = parent and component_of(parent) or nil
		local parent_node = parent_component and assert(parent_component.render_node) or nil
		local style = layout_style(props)
		local node = {
			kind = "component",
			key = nil,
			chunk = chunk,
			node = yoga.node_new(parent_node and parent_node.node),
			parent = parent_node,
			owner = parent_component,
			children = {},
			cursor = 1,
			props = props,
		}
		yoga.node_set(node.node, style)
		local component = mount_component(self, chunk, props, parent_component, node)
		if parent_node then
			---@cast parent_component MiruComponent
			parent_node.children[#parent_node.children + 1] = node
			parent_component.children[#parent_component.children + 1] = component
			local root = root_instance(parent_component)
			if root.mounted then
				schedule_render_tree_compile(self, root)
			end
		else
			self.instances[#self.instances + 1] = component
		end
		return component.public
	end

	---@param props table?
	---@param direction string?
	---@param children fun()?
	---@return MiruRenderNode
	function View:render_element(props, direction, children)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local node = render_element(ctx, "box", props and props.key, props, direction)
		render_children(ctx, node, children)
		return node
	end

	---@param props table?
	---@param draw fun(width: number, height: number)?
	---@return MiruRenderNode
	function View:render_canvas(props, draw)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local node = render_element(ctx, "canvas", props and props.key, props)
		node.draw = draw
		render_children(ctx, node)
		return node
	end

	---@param text any
	---@param props table?
	---@return MiruRenderNode
	function View:render_text(text, props)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local node = render_element(ctx, "text", props and props.key, props)
		node.text = text
		remove_render_children_from(node, 1)
		return node
	end

	---@param chunk string
	---@param props table?
	---@param key any
	---@return MiruInstance
	function View:render_component(chunk, props, key)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local parent = ctx.parent
		local index = parent.cursor
		parent.cursor = index + 1

		local node = parent.children[index]
		if node and (node.kind ~= "component" or node.key ~= key or node.chunk ~= chunk) then
			remove_render_children_from(parent, index)
			node = nil
		end
		if not node then
			node = {
				kind = "component",
				key = key,
				chunk = chunk,
				node = yoga.node_new(parent.node),
				parent = parent,
				owner = ctx.instance,
				children = {},
				cursor = 1,
			}
			parent.children[index] = node
			mount_component(self, chunk, props, ctx.instance, node)
		else
			patch_props(assert(node.instance), props)
		end
		local component = assert(node.instance)
		component.render_node = node
		node.props = component.props
		bind_ref(component, props and props.ref, component)
		yoga.node_set(node.node, layout_style(props))
		return component.public
	end

	---@param name string
	---@param props table?
	---@return MiruInstance
	function View:render_slot(name, props)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local parent = ctx.parent
		local index = parent.cursor
		parent.cursor = index + 1

		local node = parent.children[index]
		if node and (node.kind ~= "slot" or node.key ~= name) then
			remove_render_children_from(parent, index)
			node = nil
		end
		if not node then
			local public = setmetatable({
				args = {},
			}, Instance)
			---@type MiruComponent
			local component = setmetatable({
				public = public,
				view = self,
				parent = ctx.instance,
				children = {},
				layout = {},
				disposables = {},
				mounted = true,
				layout_version = self.scope:value(0),
				props = {},
				slot_name = name,
			}, Component)
			component_by_instance[public] = component
			node = {
				kind = "slot",
				key = name,
				node = yoga.node_new(parent.node),
				parent = parent,
				owner = ctx.instance,
				children = {},
				cursor = 1,
				instance = component,
			}
			component.render_node = node
			parent.children[index] = node
			self.slots[name] = component
		end
		local component = assert(node.instance)
		component.render_node = node
		self.slots[name] = component
		bind_ref(component, props and props.ref, component)
		yoga.node_set(node.node, layout_style(props))
		return component.public
	end

	---@param animation MiruAnimation
	function View:add_animation(animation)
		if animation.listed then
			return
		end
		animation.listed = true
		local animations = self.animations
		animations[#animations + 1] = animation
	end

	---@param dt number
	local function step_animations(self, dt)
		local animations = self.animations
		local i = 1
		while i <= #animations do
			local animation = animations[i]
			if animation.stopped or not animation:step(dt) then
				animation.listed = nil
				animations[i] = animations[#animations]
				animations[#animations] = nil
			else
				i = i + 1
			end
		end
	end

	---@param dt number?
	function View:update(dt)
		self.frame = self.frame + 1
		self.scope:flush()
		step_animations(self, dt or 0)
		return self.scope:flush()
	end

	---@param w number
	---@param h number
	function View:resize(w, h)
		if self.w == w and self.h == h then
			return
		end
		self.w = w
		self.h = h
		bump_version(self.layout_version)
		if self.pointer_x and self.pointer_y then
			self:pointer(self.pointer_x, self.pointer_y)
		end
	end

	---@param x number
	---@param y number
	function View:pointer(x, y)
		self.pointer_x = x
		self.pointer_y = y
		local target, tx, ty = hit_view(self, x, y, "clickable")
		local hover_target = hit_target_view(self, x, y)
		local active_target = target and clickable_enabled(target) and target or nil
		set_hovered(self, hover_target)
		set_clickable_hovered(self, active_target, x, y)
		set_mouse_cursor(self, clickable_cursor(target))
		if active_target then
			call_clickable(active_target, "on_pointer_move",
				pointer_event(active_target, active_target, tx or 0, ty or 0, x, y))
		end
		local pressed_scrollable = self.pressed_scrollable_instance
		if pressed_scrollable and pressed_scrollable.mounted then
			call_scrollable(pressed_scrollable, "on_pointer_move",
				pointer_event_at(pressed_scrollable, pressed_scrollable, x, y))
		else
			local scrollable, sx, sy = hit_view(self, x, y, "scrollable")
			if scrollable and scrollable_enabled(scrollable) then
				call_scrollable(scrollable, "on_pointer_move",
					pointer_event(scrollable, scrollable, sx or 0, sy or 0, x, y))
			end
		end
	end

	---@param x number?
	---@param y number?
	---@return MiruInstance?
	function View:click(x, y)
		x = x or self.pointer_x
		y = y or self.pointer_y
		if not x or not y then
			return
		end
		local event_target = hit_target_view(self, x, y)
		local target, tx, ty = hit_view(self, x, y, "clickable")
		notify_dismissable(self, event_target, x, y)
		if target and clickable_enabled(target) then
			call_clickable(target, "on_click", pointer_event(event_target, target, tx or 0, ty or 0, x, y))
			return target.public
		end
	end

	---@param button integer
	---@param state integer
	function View:mouse_button(button, state)
		local x = self.pointer_x
		local y = self.pointer_y
		if not x or not y then
			return
		end
		local event_target = hit_target_view(self, x, y)
		local target, tx, ty = hit_view(self, x, y, "clickable")
		local focus_target = hit_view(self, x, y, "focusable")
		local scroll_target, sx, sy = hit_view(self, x, y, "scrollable")
		local active_target = target and clickable_enabled(target) and target or nil
		local active_scroll_target = scroll_target and scrollable_enabled(scroll_target) and scroll_target or nil
		if state == 1 then
			notify_dismissable(self, event_target, x, y, button)
			set_focused(self, focus_target)
			local old = self.pressed_instance
			if old and old ~= active_target then
				set_state(old.pressed, false)
			end
			self.pressed_instance = active_target
			self.pressed_button = active_target and button or nil
			if active_target then
				set_state(active_target.pressed, true)
				call_clickable(active_target, "on_pointer_down",
					pointer_event(event_target, active_target, tx or 0, ty or 0, x, y, button))
			end
			self.pressed_scrollable_instance = active_scroll_target
			self.pressed_scrollable_button = active_scroll_target and button or nil
			if active_scroll_target then
				call_scrollable(active_scroll_target, "on_pointer_down",
					pointer_event(event_target, active_scroll_target, sx or 0, sy or 0, x, y, button))
			end
			return
		end

		local pressed = self.pressed_instance
		local pressed_button = self.pressed_button
		local pressed_scrollable = self.pressed_scrollable_instance
		local pressed_scrollable_button = self.pressed_scrollable_button
		self.pressed_instance = nil
		self.pressed_button = nil
		self.pressed_scrollable_instance = nil
		self.pressed_scrollable_button = nil
		if pressed and pressed.mounted then
			set_state(pressed.pressed, false)
			call_clickable(pressed, "on_pointer_up", pointer_event_at(pressed, pressed, x, y, button))
			if pressed == active_target and pressed_button == button then
				call_clickable(pressed, "on_click", pointer_event(event_target, pressed, tx or 0, ty or 0, x, y, button))
			end
		end
		if pressed_scrollable and pressed_scrollable.mounted and pressed_scrollable_button == button then
			call_scrollable(pressed_scrollable, "on_pointer_up",
				pointer_event_at(pressed_scrollable, pressed_scrollable, x, y, button))
		end
	end

	---@param event table
	function View:mouse_scroll(event)
		local x = self.pointer_x
		local y = self.pointer_y
		if not x or not y then
			return
		end
		local event_target = hit_target_view(self, x, y)
		local target, tx, ty = hit_view(self, x, y, "scrollable")
		if not target or not scrollable_enabled(target) then
			return
		end
		local out = pointer_event(event_target, target, tx or 0, ty or 0, x, y)
		out.scroll_x = event.scroll_x or event.x or 0
		out.scroll_y = event.scroll_y or event.y or 0
		call_scrollable(target, "on_scroll", out)
	end

	---@param event table
	function View:char(event)
		local target = self.focused_instance
		if target and target.mounted and focusable_enabled(target) then
			call_focusable(target, "on_char", event)
		end
	end

	---@param event table
	function View:key(event)
		local target = self.focused_instance
		if target and target.mounted and focusable_enabled(target) then
			call_focusable(target, "on_key", event)
		end
	end

	---@param event table
	function View:clipboard_pasted(event)
		local target = self.focused_instance
		if target and target.mounted and focusable_enabled(target) then
			call_focusable(target, "on_clipboard_pasted", event)
		end
	end

	---@param batch MiruBatch
	function View:draw(batch)
		for i = 1, #self.instances do
			self.instances[i]:draw(batch)
		end
	end

	---@return MiruStatistics
	function View:statistics()
		return self.stats
	end

	---@param name string
	---@param value any
	function View:provide(name, value)
		self.provides[name] = value
		self.scope:trigger(self.provides, name)
	end

	---@param spec MiruTextStyleRegistry
	function View:text_styles(spec)
		self.text_style_registry = build_text_styles(spec)
		bump_version(self.layout_version)
	end

	---@param name string
	---@return MiruInstance
	function View:slot(name)
		return assert(self.slots[name]).public
	end
end

local M = {}

---@param args table?
---@return MiruView
function M.new(args)
	args = args or {}
	---@type MiruScope
	local scope = setmetatable({
		targets = setmetatable({}, {
			__mode = "k",
		}),
		queue = {},
		queue_head = 1,
		queue_tail = 0,
		flush_batch = {},
	}, Scope)
	local provides = {
		component_path = args.component_path or COMPONENT_PATH,
	}
	for key, value in pairs(args.provides or {}) do
		provides[key] = value
	end
	---@type MiruView
	local view = setmetatable({
		scope = scope,
		instances = {},
		w = args.width or 0,
		h = args.height or 0,
		layout_version = scope:value(0),
		animations = {},
		dismissables = {},
		effect_order = 0,
		dirty_roots = {},
		dirty_root_order = {},
		stats = {
			render_count = 0,
		},
		provides = provides,
		slots = {},
		frame = 0,
	}, View)
	scope.after_flush_batch = function()
		flush_dirty_roots(view)
	end
	return view
end

---@class (partial) MiruComputedState<T>
local Computed = {}; do
	Computed.__index = Computed

	---@generic T
	---@return T
	function Computed:__call()
		return self.value()
	end

	function Computed:stop()
		if not self.effect then
			return
		end
		self.effect:stop()
		self.effect = nil
	end
end

---@generic T
---@param value T
---@return MiruValue<T>
function M.value(value)
	---@cast active MiruContext
	return active.view.scope:value(value)
end

---@param name string
---@return any
function M.use(name)
	return use_provide(name)
end

---@param spec MiruTextStyleRegistry
function M.text_styles(spec)
	local context = assert(active, "text_styles requires an active Miru context")
	context.view:text_styles(spec)
end

---@param fn MiruAnimatedTarget
---@param opts table?
---@return MiruAnimation
function M.animated(fn, opts)
	---@cast active MiruContext
	assert(active.disposables)
	local view = active.view
	opts = opts or {}
	---@type MiruAnimation
	local animation = setmetatable({
		view = view,
		value = view.scope:value(0),
		from = 0,
		to = 0,
		elapsed = 0,
		duration = opts.duration or 0.14,
		easing = easing(opts),
	}, Animation)
	local first = true
	---@type MiruContext
	local ctx = {
		view = view,
	}
	animation.effect = view.scope:effect(function()
		local prev = active
		active = ctx
		local target = fn()
		active = prev
		assert(type(target) == "number", "animated target must be a number")
		if first then
			first = false
			if opts.appear then
				animation:jump(opts.from or 0)
				animation:retarget(target)
			else
				animation:jump(target)
			end
			return
		end
		animation:retarget(target)
	end)
	active.disposables[#active.disposables + 1] = animation
	return animation
end

local clickable_prop_keys <const> = {
	enabled = true,
	cursor = true,
	on_click = true,
	on_pointer_down = true,
	on_pointer_up = true,
	on_pointer_enter = true,
	on_pointer_leave = true,
	on_pointer_move = true,
}

local focusable_prop_keys <const> = {
	enabled = true,
	on_focus = true,
	on_blur = true,
	on_char = true,
	on_key = true,
	on_clipboard_pasted = true,
}

local scrollable_prop_keys <const> = {
	enabled = true,
	on_scroll = true,
	on_pointer_down = true,
	on_pointer_up = true,
	on_pointer_move = true,
}

---@param component MiruComponent
local function mark_targetable(component)
	component.targetable = true
end

---@param component MiruComponent
---@param target table
---@param props table?
---@param prop_keys table<any, boolean>
local function register_prop_bindings(component, target, props, prop_keys)
	if not props then
		return
	end
	local context = active
	local reads = context and context.instance == component and context.setup_prop_reads or nil
	if not reads then
		return
	end
	local fields
	for key in pairs(reads) do
		local value = props[key]
		if prop_keys[key] and value == component.props[key] then
			fields = fields or {}
			fields[key] = key
		end
	end
	if not fields then
		return
	end
	local prop_bindings = component.prop_bindings
	if not prop_bindings then
		prop_bindings = {}
		component.prop_bindings = prop_bindings
	end
	prop_bindings[#prop_bindings + 1] = {
		target = target,
		fields = fields,
	}
end

---@param props MiruClickable?
function M.clickable(props)
	---@cast active MiruContext
	local component = assert(active.instance)
	mark_targetable(component)
	local clickable = props or {}
	component.clickable = clickable
	register_prop_bindings(component, clickable, props, clickable_prop_keys)
end

---@param props MiruFocusable?
function M.focusable(props)
	---@cast active MiruContext
	local component = assert(active.instance)
	mark_targetable(component)
	local focusable = props or {}
	component.focusable = focusable
	register_prop_bindings(component, focusable, props, focusable_prop_keys)
end

---@param props MiruScrollable?
function M.scrollable(props)
	---@cast active MiruContext
	local component = assert(active.instance)
	mark_targetable(component)
	local scrollable = props or {}
	component.scrollable = scrollable
	register_prop_bindings(component, scrollable, props, scrollable_prop_keys)
end

---@param props MiruDismissable?
function M.dismissable(props)
	---@cast active MiruContext
	local component = assert(active.instance)
	if props then
		mark_targetable(component)
		component.dismissable = props
		register_dismissable(active.view, component)
	else
		unregister_dismissable(component)
		component.dismissable = nil
	end
end

---@return MiruValue<boolean>
function M.hovered()
	---@cast active MiruContext
	local component = assert(active.instance)
	mark_targetable(component)
	local hovered = component.hovered
	if hovered then
		return hovered
	end
	hovered = active.view.scope:value(false)
	component.hovered = hovered
	return hovered
end

---@return MiruValue<boolean>
function M.pressed()
	---@cast active MiruContext
	local component = assert(active.instance)
	local pressed = component.pressed
	if pressed then
		return pressed
	end
	pressed = active.view.scope:value(false)
	component.pressed = pressed
	return pressed
end

---@return MiruValue<boolean>
function M.focused()
	---@cast active MiruContext
	local component = assert(active.instance)
	local focused = component.focused
	if focused then
		return focused
	end
	focused = active.view.scope:value(false)
	component.focused = focused
	return focused
end

---@return MiruRef
function M.ref()
	local context = assert(active)
	local ref = setmetatable({}, Ref)
	ref_owners[ref] = assert(context.instance)
	return ref
end

---@param methods table
function M.expose(methods)
	---@cast active MiruContext
	local public = assert(active.instance).public
	for key, value in pairs(methods) do
		assert(not public[key])
		public[key] = function(_, ...args)
			return value(table.unpack(args, 1, args.n))
		end
	end
end

---@param chunk string
---@param props table?
---@return MiruInstance
function M.mount(chunk, props)
	local ctx = assert(active_render, "mount can only be called while rendering")
	return ctx.view:render_component(chunk, props, props and props.key)
end

---@param name string
---@param props table?
---@return MiruInstance
function M.slot(name, props)
	if active_render then
		return active_render.view:render_slot(name, props)
	end
	local context = assert(active)
	return context.view:slot(name)
end

---@param props table?
---@param children fun()?
---@param direction string?
---@return MiruRenderNode
local function element(props, children, direction)
	local ctx = assert(active_render, "element can only be used while rendering")
	return ctx.view:render_element(props, direction, children)
end

---@param props table?
---@param children fun()?
---@return MiruRenderNode
function M.box(props, children)
	return element(props, children)
end

---@param props table?
---@param children fun()?
---@return MiruRenderNode
function M.hbox(props, children)
	return element(props, children, "row")
end

---@param props table?
---@param children fun()?
---@return MiruRenderNode
function M.vbox(props, children)
	return element(props, children, "column")
end

---@param props table?
---@param draw fun(width: number, height: number)?
---@return MiruRenderNode
function M.canvas(props, draw)
	local ctx = assert(active_render, "canvas can only be used while rendering")
	return ctx.view:render_canvas(props, draw)
end

---Named text styles use `[name]` / `[n]`. Other complete tagged-text controls
---pass through to the Soluna material text layout engine.
---@param text any
---@param props table?
---@return MiruRenderNode
function M.text(text, props)
	local ctx = assert(active_render, "text can only be used while rendering")
	return ctx.view:render_text(text, props)
end

---@param a number
---@param b number
---@param t number
---@return number
function M.lerp(a, b, t)
	return lerp(a, b, clamp01(t))
end

---@param a integer
---@param b integer
---@param t number
---@return integer
function M.lerp_color(a, b, t)
	return lerp_color(a, b, t)
end

local Batch = {}; do
	local methods = {}

	---@param name string
	function Batch.__index(_, name)
		local method = methods[name] or function(_, ...args)
			local commands = assert(active_batch, "batch can only be used inside canvas")
			commands[#commands + 1] = command(name, table.unpack(args, 1, args.n))
		end
		methods[name] = method
		return method
	end
end

local batch = setmetatable({}, Batch)
---@cast batch MiruBatch
M.batch = batch

---@generic T
---@param fn fun(): T, ...
---@return MiruComputed<T>
function M.computed(fn)
	---@cast active MiruContext
	assert(active.disposables)
	local view = active.view
	---@type MiruValue<T>
	local value = view.scope:value(nil)
	---@type MiruContext
	local ctx = {
		view = view,
	}
	local effect = view.scope:effect(function()
		local prev = active
		active = ctx
		local result = fn()
		active = prev
		value(result)
	end)
	---@type MiruComputedState<T>
	local computed = setmetatable({
		effect = effect,
		value = value,
	}, Computed)
	active.disposables[#active.disposables + 1] = computed
	---@cast computed MiruComputed<T>
	return computed
end

---@cast M MiruModule
return M
