local matquad = require "soluna.material.quad"
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
---@field instance MiruInstance?
---@field owner MiruInstance?
---@field draw fun(width: number, height: number, frame?: integer)?
---@field commands MiruCommand[]?
---@field props table?
---@field text any
---@field text_layout MiruTextLayout?
---@field ref MiruRef?
---@field slot_name string?

---@class MiruTextEngine
---@field layout fun(args: table): MiruTextLayout?
---@field draw? fun(batch: MiruBatch, layout: MiruTextLayout, x: number, y: number, width: number, height: number)

---@class MiruTextLayout
---@field height number
---@field width? number
---@field line_height? number
---@field line_count? number
---@field draw? fun(self: MiruTextLayout, batch: MiruBatch, x?: number, y?: number)

---@class MiruLayout
---@field x number?
---@field y number?
---@field w number?
---@field h number?

---@alias MiruHitMode "clickable"|"component"

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
---@type fun(instance: MiruInstance): MiruInstance
local root_instance
---@type fun(instance: MiruInstance): MiruCommand[]
local compile_render_tree
---@type fun(view: MiruView)
local flush_dirty_roots
---@type fun(view: MiruView, root: MiruInstance)
local schedule_render_tree_compile

---@class (partial) MiruInstance
---@field view MiruView
---@field parent MiruInstance?
---@field children MiruInstance[]
---@field layout MiruLayout
---@field disposables MiruDisposable[]?
---@field mounted boolean?
---@field effect MiruEffect?
---@field commands MiruCommand[]?
---@field render_node MiruRenderNode?
---@field layout_version MiruValue<integer>
---@field props table
---@field args table
---@field clickable MiruClickable?
---@field clickable_prop_bindings table<any, string>?
---@field dismissable MiruDismissable?
---@field dismissable_index integer?
---@field hovered MiruValue<boolean>?
---@field pressed MiruValue<boolean>?
---@field ref MiruRef?
---@field slot_name string?

---@class (partial) MiruView
---@field scope MiruScope
---@field instances MiruInstance[]
---@field w number
---@field h number
---@field layout_version MiruValue<integer>
---@field pointer_x number?
---@field pointer_y number?
---@field hovered_instance MiruInstance?
---@field pressed_instance MiruInstance?
---@field pressed_button integer?
---@field stats MiruStatistics
---@field provides table
---@field animations MiruAnimation[]
---@field dismissables MiruInstance[]
---@field effect_order integer
---@field slots table<string, MiruInstance?>
---@field frame integer
---@field dirty_roots table<MiruInstance, boolean>
---@field dirty_root_order MiruInstance[]

---@class MiruContext
---@field view MiruView
---@field instance MiruInstance?
---@field disposables MiruDisposable[]?
---@field drawing boolean?
---@field rendering boolean?
---@field setup_prop_reads table<any, boolean>?

---@class MiruRenderContext
---@field view MiruView
---@field instance MiruInstance
---@field parent MiruRenderNode

---@class MiruPointerEvent
---@field target MiruInstance?
---@field current_target MiruInstance
---@field instance MiruInstance
---@field view MiruView
---@field x number
---@field y number
---@field local_x number
---@field local_y number
---@field button integer?

---@class MiruDismissable
---@field enabled? any
---@field on_dismiss? fun(event: MiruPointerEvent)

---@class MiruClickable
---@field enabled? any
---@field on_click? fun(event: MiruPointerEvent)
---@field on_pointer_down? fun(event: MiruPointerEvent)
---@field on_pointer_up? fun(event: MiruPointerEvent)
---@field on_pointer_enter? fun(event: MiruPointerEvent)
---@field on_pointer_leave? fun(event: MiruPointerEvent)
---@field on_pointer_move? fun(event: MiruPointerEvent)

---@class MiruRect
---@field x number
---@field y number
---@field w number
---@field h number

---@class MiruStatistics
---@field render_count integer

---@class (partial) MiruRef
--- A component-owned geometry handle.
--- `rect()` returns the target geometry in the coordinate space of the component that created the ref.
---@field owner MiruInstance
---@field current any
---@field rect fun(self: MiruRef): MiruRect?

---@class MiruModule
---@field batch MiruBatch
---@field new fun(args?: table): MiruView
---@field value fun(value: any): MiruValue<any>
---@field use fun(name: string): any
---@field mount fun(chunk: string, props?: table, parent?: MiruInstance): MiruInstance
---@field slot fun(name: string, props?: table): MiruInstance
---@field expose fun(methods: table)
---@field box fun(props?: table, children?: fun()): MiruRenderNode
---@field hbox fun(props?: table, children?: fun()): MiruRenderNode
---@field vbox fun(props?: table, children?: fun()): MiruRenderNode
---@field canvas fun(props?: table, draw?: fun(width: number, height: number, frame?: integer)): MiruRenderNode
---@field text fun(text: any, props?: table): MiruRenderNode
---@field clickable fun(props?: MiruClickable)
---@field dismissable fun(props?: MiruDismissable)
---@field hovered fun(): MiruValue<boolean>
---@field pressed fun(): MiruValue<boolean>
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

---@param view MiruView
---@param instance MiruInstance
local function register_dismissable(view, instance)
	if instance.dismissable_index then
		return
	end
	local dismissables = view.dismissables
	local index = #dismissables + 1
	dismissables[index] = instance
	instance.dismissable_index = index
end

---@param instance MiruInstance
local function unregister_dismissable(instance)
	local index = instance.dismissable_index
	if not index then
		return
	end
	local dismissables = instance.view.dismissables
	local last = dismissables[#dismissables]
	dismissables[index] = last
	dismissables[#dismissables] = nil
	if last and last ~= instance then
		last.dismissable_index = index
	end
	instance.dismissable_index = nil
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
	return assert(view.provides[name])
end

---@type fun(target: any): MiruRect?
local rect_of

---@class (partial) MiruRef
local Ref = {}; do
	Ref.__index = Ref

	---@return MiruRect?
	function Ref:rect()
		local target = self.current
		if not target then
			return nil
		end
		local owner = self.owner
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

	---@class (partial) MiruInstance
	local Instance = {}; do
		Instance.__index = Instance

		---@return number, number
		function Instance:origin()
			local node = assert(self.render_node)
			local x, y = yoga.node_get(node.node)
			return x, y
		end

		---@return MiruRect?
		function Instance:rect()
			return rect_of(self)
		end

		---@param event table
		---@return table
		function Instance:local_event(event)
			if event.x == nil or event.y == nil then
				return event
			end
			local rect = assert(rect_of(self))
			local out = {}
			for key, value in pairs(event) do
				out[key] = value
			end
			out.x = event.x - rect.x
			out.y = event.y - rect.y
			return out
		end

		---@param batch MiruBatch
		function Instance:draw(batch)
			replay_commands(batch, self.commands)
		end

		---@param disposing_render_tree boolean?
		function Instance:destroy(disposing_render_tree)
			if not self.mounted then
				return
			end
			local view = self.view
			local render_node = self.render_node
			local slot_name = self.slot_name
			if slot_name and view.slots[slot_name] == self then
				view.slots[slot_name] = nil
			end
			local from_render_tree = disposing_render_tree == true
			local root = not from_render_tree and self.parent and root_instance(self) or nil
			self.render_node = nil
			if view.hovered_instance == self then
				view.hovered_instance = nil
			end
			if view.pressed_instance == self then
				view.pressed_instance = nil
				view.pressed_button = nil
			end
			unregister_dismissable(self)
			self.mounted = nil
			if self.ref and self.ref.current == self then
				self.ref.current = nil
			end
			self.ref = nil
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
	---@param current any
	local function bind_ref(holder, ref, current)
		local old = holder.ref
		if old ~= ref and old and old.current == current then
			old.current = nil
		end
		holder.ref = ref
		if ref then
			ref.current = current
		end
	end

	---@type fun(instance: MiruInstance, x: number, y: number, mode: MiruHitMode): MiruInstance?, number?, number?
	local hit_instance
	---@type fun(node: MiruRenderNode, x: number, y: number, mode: MiruHitMode): MiruInstance?, number?, number?
	local hit_render_node

	---@param value MiruValue<boolean>?
	---@param state boolean
	local function set_state(value, state)
		if value then
			value(state)
		end
	end

	---@param instance MiruInstance
	---@return boolean
	local function clickable_enabled(instance)
		local clickable = instance.clickable
		if not clickable then
			return false
		end
		local enabled = clickable.enabled
		return enabled == nil or enabled ~= false
	end

	---@param instance MiruInstance
	---@param mode MiruHitMode
	---@return boolean
	local function instance_hittable(instance, mode)
		return mode == "component" or clickable_enabled(instance)
	end

	---@param target MiruInstance?
	---@param current_target MiruInstance
	---@param x number
	---@param y number
	---@param button integer?
	---@return MiruPointerEvent
	local function pointer_event(target, current_target, x, y, button)
		return {
			target = target,
			current_target = current_target,
			instance = current_target,
			view = current_target.view,
			x = x,
			y = y,
			local_x = x,
			local_y = y,
			button = button,
		}
	end

	---@param instance MiruInstance
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

	---@param target MiruInstance?
	---@param current_target MiruInstance
	---@param x number
	---@param y number
	---@param button integer?
	---@return MiruPointerEvent
	local function pointer_event_at(target, current_target, x, y, button)
		local ox, oy = current_target:origin()
		return pointer_event(target, current_target, x - ox, y - oy, button)
	end

	---@param instance MiruInstance
	---@return boolean
	local function dismissable_enabled(instance)
		local dismissable = instance.dismissable
		if not dismissable then
			return false
		end
		local enabled = dismissable.enabled
		return enabled == nil or enabled ~= false
	end

	---@param target MiruInstance?
	---@param boundary MiruInstance
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

	---@param instance MiruInstance
	---@param target MiruInstance?
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
	---@param target MiruInstance?
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
		---@cast target MiruInstance
		local node = assert(target.render_node)
		local x, y, w, h = yoga.node_get(node.node)
		return {
			x = x,
			y = y,
			w = w,
			h = h,
		}
	end

	---@param instance MiruInstance
	---@param x number
	---@param y number
	---@param mode MiruHitMode
	---@return MiruInstance?, number?, number?
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
	---@return MiruInstance?, number?, number?
	hit_render_node = function(node, x, y, mode)
		for i = #node.children, 1, -1 do
			local child = node.children[i]
			local target, tx, ty = hit_render_node(child, x, y, mode)
			if target then
				return target, tx, ty
			end
		end
		if node.kind == "component" and node.instance then
			local cx, cy, cw, ch = yoga.node_get(node.node)
			local lx = x - cx
			local ly = y - cy
			local instance = node.instance
			if lx >= 0 and lx <= cw and ly >= 0 and ly <= ch and instance_hittable(instance, mode) then
				return instance, lx, ly
			end
		end
		return nil, nil, nil
	end

	---@param view MiruView
	---@param x number
	---@param y number
	---@param mode MiruHitMode
	---@return MiruInstance?, number?, number?
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
	---@return MiruInstance?, number?, number?
	local function hit_clickable_view(view, x, y)
		return hit_view(view, x, y, "clickable")
	end

	---@param view MiruView
	---@param x number
	---@param y number
	---@return MiruInstance?, number?, number?
	local function hit_component_view(view, x, y)
		return hit_view(view, x, y, "component")
	end

	---@param view MiruView
	---@param target MiruInstance?
	---@param x number?
	---@param y number?
	local function set_hovered(view, target, x, y)
		local old = view.hovered_instance
		if old == target then
			return
		end
		if old then
			set_state(old.hovered, false)
			if old.mounted then
				call_clickable(old, "on_pointer_leave", pointer_event_at(old, old, x or 0, y or 0))
			end
		end
		view.hovered_instance = target
		if target then
			set_state(target.hovered, true)
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
			if value ~= nil then
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

	---@param instance MiruInstance
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	local function set_instance_layout(instance, x, y, w, h)
		local layout = instance.layout
		if layout.x == x and layout.y == y and layout.w == w and layout.h == h then
			return
		end
		layout.x = x
		layout.y = y
		layout.w = w
		layout.h = h
		bump_version(instance.layout_version)
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

	---@param node MiruRenderNode
	---@return MiruTextEngine
	local function text_engine(node)
		local owner = assert(node.owner)
		local engine = owner.view.provides.text_engine
		assert(engine, "missing Miru text engine")
		assert(type(engine.layout) == "function", "Miru text engine requires layout(args)")
		return engine
	end

	---@param node MiruRenderNode
	---@param width number
	---@param height number
	---@return table
	local function text_layout_args(node, width, height)
		local out = {}
		local props = node.props
		if props then
			for key, value in pairs(props) do
				out[key] = value
			end
		end
		out.text = node.text
		out.width = max(1, pixel_size(width))
		out.height = pixel_size(height)
		return out
	end

	---@param node MiruRenderNode
	---@param width number
	---@param height number
	---@return MiruTextLayout
	local function build_text_layout(node, width, height)
		local layout = assert(text_engine(node).layout(text_layout_args(node, width, height)),
			"Miru text engine layout must return a layout")
		assert(type(layout.height) == "number", "Miru text layout requires numeric height")
		node.text_layout = layout
		return layout
	end

	---@param node MiruRenderNode
	---@return boolean
	local function resolve_text_layout(node)
		local _, _, width, height = yoga.node_get(node.node)
		local layout = build_text_layout(node, width, height)
		local props = node.props
		if props and props.height ~= nil then
			return false
		end
		local measured_height = max(0, pixel_size(layout.height))
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
				local engine = text_engine(node)
				if engine.draw then
					engine.draw(batch, layout, 0, 0, pixel_size(width), pixel_size(height))
					return
				end
				local draw = assert(layout.draw, "Miru text layout requires draw(batch, x, y) or engine.draw")
				draw(layout, batch, 0, 0)
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
		if props and props.background ~= nil then
			local bg = background_command(props.background, w, h)
			if bg then
				out[#out + 1] = bg
			end
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
		out[#out + 1] = command "layer"
	end

	---@param instance MiruInstance
	---@return MiruCommand[]
	function compile_render_tree(instance)
		local root = assert(instance.render_node)
		if not root.parent then
			local style = layout_style(root.props)
			if style.width == nil then
				style.width = instance.view.w
			end
			if style.height == nil then
				style.height = instance.view.h
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
				view = instance.view,
				instance = instance,
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
	---@param root MiruInstance
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

	---@param instance MiruInstance
	---@param key string
	---@param value any
	local function set_prop(instance, key, value)
		local props = instance.props
		if props[key] == value then
			return
		end
		props[key] = value
		local clickable_bindings = instance.clickable_prop_bindings
		if clickable_bindings then
			local field = clickable_bindings[key]
			if field and instance.clickable then
				instance.clickable[field] = value
			end
		end
		instance.view.scope:trigger(props, key)
	end

	---@param instance MiruInstance
	---@param props table?
	function patch_props(instance, props)
		props = props or {}
		for key in pairs(instance.props) do
			if props[key] == nil then
				set_prop(instance, key, nil)
			end
		end
		for key, value in pairs(props) do
			set_prop(instance, key, value)
		end
	end

	---@param instance MiruInstance
	---@return table
	local function component_args(instance)
		return setmetatable({}, {
			__index = function(_, key)
				local props = instance.props
				local context = active
				if context and context.instance == instance and context.setup_prop_reads then
					context.setup_prop_reads[key] = true
				else
					instance.view.scope:track(props, key)
				end
				return props[key]
			end,
			__newindex = function(_, key, value)
				set_prop(instance, key, value)
			end,
			__pairs = function()
				return next, instance.props
			end,
		})
	end

	---@param instance MiruInstance
	---@return MiruInstance
	function root_instance(instance)
		while instance.parent do
			instance = instance.parent
		end
		return instance
	end

	---@param view MiruView
	---@param chunk string
	---@param props table?
	---@param parent MiruInstance?
	---@param render_node MiruRenderNode
	---@return MiruInstance
	function mount_component(view, chunk, props, parent, render_node)
		local path = assert(file.searchpath(chunk, view.provides.component_path))
		local source = assert(file.load(path))
		---@diagnostic disable-next-line: assign-type-mismatch
		chunk = assert(load(source, "@" .. path, "t"))
		assert(type(chunk) == "function")

		local order = view.effect_order + 1
		view.effect_order = order

		---@type MiruInstance
		local instance = setmetatable({
			view = view,
			parent = parent,
			children = {},
			layout = layout(props),
			disposables = {},
			mounted = true,
			layout_version = view.scope:value(0),
			props = {},
			render_node = render_node,
		}, Instance)
		render_node.instance = instance
		local args = component_args(instance)
		instance.args = args
		patch_props(instance, props)
		render_node.props = instance.props
		bind_ref(instance, props and props.ref, instance)

		local prev = active
		local prev_effect = view.scope.active
		---@type MiruContext
		active = {
			view = view,
			instance = instance,
			disposables = instance.disposables,
			setup_prop_reads = {},
		}
		view.scope.active = nil
		local draw = chunk(args)
		view.scope.active = prev_effect
		active = prev
		assert(type(draw) == "function")
		local ctx

		instance.effect = view.scope:effect(function()
			if not instance.mounted then
				return
			end
			local nested_render = active_render ~= nil
			if not instance.parent then
				view.layout_version()
			end
			instance.layout_version()
			---@diagnostic disable-next-line: redefined-local
			local prev = active
			local prev_render = active_render
			---@type MiruContext
			ctx = ctx or {
				view = view,
				instance = instance,
				drawing = true,
				rendering = true,
			}
			local parent_node = assert(instance.render_node)
			local render_ctx = {
				view = view,
				instance = instance,
				parent = parent_node,
			}
			active = ctx
			active_render = render_ctx
			view.stats.render_count = view.stats.render_count + 1
			render_ctx.parent.cursor = 1
			draw()
			remove_render_children_from(render_ctx.parent, render_ctx.parent.cursor)
			if not nested_render then
				schedule_render_tree_compile(view, root_instance(instance))
			end
			active = prev
			active_render = prev_render
		end, order)

		return instance
	end

	---@param chunk string
	---@param props table?
	---@param parent MiruInstance?
	---@return MiruInstance
	function View:mount(chunk, props, parent)
		local parent_node = parent and assert(parent.render_node) or nil
		local style = layout_style(props)
		local node = {
			kind = "component",
			key = nil,
			chunk = chunk,
			node = yoga.node_new(parent_node and parent_node.node),
			parent = parent_node,
			owner = parent,
			children = {},
			cursor = 1,
			props = props,
		}
		yoga.node_set(node.node, style)
		local instance = mount_component(self, chunk, props, parent, node)
		if parent_node then
			local parent_instance = assert(parent)
			parent_node.children[#parent_node.children + 1] = node
			parent_instance.children[#parent_instance.children + 1] = instance
			local root = root_instance(parent_instance)
			if root.mounted then
				schedule_render_tree_compile(self, root)
			end
		else
			self.instances[#self.instances + 1] = instance
		end
		return instance
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
		local instance = assert(node.instance)
		instance.render_node = node
		node.props = instance.props
		bind_ref(instance, props and props.ref, instance)
		yoga.node_set(node.node, layout_style(props))
		return instance
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
			---@type MiruInstance
			local instance = setmetatable({
				view = self,
				parent = ctx.instance,
				children = {},
				layout = {},
				disposables = {},
				mounted = true,
				layout_version = self.scope:value(0),
				props = {},
				args = {},
				slot_name = name,
			}, Instance)
			node = {
				kind = "slot",
				key = name,
				node = yoga.node_new(parent.node),
				parent = parent,
				owner = ctx.instance,
				children = {},
				cursor = 1,
				instance = instance,
			}
			instance.render_node = node
			parent.children[index] = node
			self.slots[name] = instance
		end
		local instance = assert(node.instance)
		instance.render_node = node
		self.slots[name] = instance
		bind_ref(instance, props and props.ref, instance)
		yoga.node_set(node.node, layout_style(props))
		return instance
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
		if self.pointer_x ~= nil and self.pointer_y ~= nil then
			self:pointer(self.pointer_x, self.pointer_y)
		end
	end

	---@param x number
	---@param y number
	function View:pointer(x, y)
		self.pointer_x = x
		self.pointer_y = y
		local target, tx, ty = hit_clickable_view(self, x, y)
		set_hovered(self, target, x, y)
		if target then
			call_clickable(target, "on_pointer_move", pointer_event(target, target, tx or 0, ty or 0))
		end
	end

	---@param x number?
	---@param y number?
	---@return MiruInstance?
	function View:click(x, y)
		x = x or self.pointer_x
		y = y or self.pointer_y
		if x == nil or y == nil then
			return
		end
		local event_target = hit_component_view(self, x, y)
		local target, tx, ty = hit_clickable_view(self, x, y)
		notify_dismissable(self, event_target, x, y)
		if target then
			call_clickable(target, "on_click", pointer_event(event_target, target, tx or 0, ty or 0))
		end
		return target
	end

	---@param button integer
	---@param state integer
	function View:mouse_button(button, state)
		local x = self.pointer_x
		local y = self.pointer_y
		if x == nil or y == nil then
			return
		end
		local event_target = hit_component_view(self, x, y)
		local target, tx, ty = hit_clickable_view(self, x, y)
		if state == 1 then
			notify_dismissable(self, event_target, x, y, button)
			local old = self.pressed_instance
			if old and old ~= target then
				set_state(old.pressed, false)
			end
			self.pressed_instance = target
			self.pressed_button = target and button or nil
			if target then
				set_state(target.pressed, true)
				call_clickable(target, "on_pointer_down", pointer_event(event_target, target, tx or 0, ty or 0, button))
			end
			return
		end

		local pressed = self.pressed_instance
		local pressed_button = self.pressed_button
		self.pressed_instance = nil
		self.pressed_button = nil
		if not pressed then
			return
		end
		if not pressed.mounted then
			return
		end
		set_state(pressed.pressed, false)
		call_clickable(pressed, "on_pointer_up", pointer_event_at(pressed, pressed, x, y, button))
		if pressed == target and pressed_button == button and clickable_enabled(pressed) then
			call_clickable(pressed, "on_click", pointer_event(event_target, pressed, tx or 0, ty or 0, button))
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

	---@param name string
	---@return MiruInstance
	function View:slot(name)
		return assert(self.slots[name])
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
	if args.text_engine ~= nil then
		provides.text_engine = args.text_engine
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
	on_click = true,
	on_pointer_down = true,
	on_pointer_up = true,
	on_pointer_enter = true,
	on_pointer_leave = true,
	on_pointer_move = true,
}

---@param instance MiruInstance
---@param props table?
---@param prop_keys table<any, boolean>
---@return table<any, string>?
local function setup_prop_bindings(instance, props, prop_keys)
	if not props then
		return nil
	end
	local context = active
	local reads = context and context.instance == instance and context.setup_prop_reads or nil
	if not reads then
		return nil
	end
	local bindings
	for key in pairs(reads) do
		local value = props[key]
		if prop_keys[key] and value == instance.props[key] then
			bindings = bindings or {}
			bindings[key] = key
		end
	end
	return bindings
end

---@param props MiruClickable?
function M.clickable(props)
	---@cast active MiruContext
	local instance = assert(active.instance)
	instance.clickable = props or {}
	instance.clickable_prop_bindings = setup_prop_bindings(instance, props, clickable_prop_keys)
end

---@param props MiruDismissable?
function M.dismissable(props)
	---@cast active MiruContext
	local instance = assert(active.instance)
	if props then
		instance.dismissable = props
		register_dismissable(active.view, instance)
	else
		unregister_dismissable(instance)
		instance.dismissable = nil
	end
end

---@return MiruValue<boolean>
function M.hovered()
	---@cast active MiruContext
	local instance = assert(active.instance)
	local hovered = instance.hovered
	if hovered then
		return hovered
	end
	hovered = active.view.scope:value(false)
	instance.hovered = hovered
	return hovered
end

---@return MiruValue<boolean>
function M.pressed()
	---@cast active MiruContext
	local instance = assert(active.instance)
	local pressed = instance.pressed
	if pressed then
		return pressed
	end
	pressed = active.view.scope:value(false)
	instance.pressed = pressed
	return pressed
end

---@return MiruRef
function M.ref()
	local context = assert(active)
	return setmetatable({
		owner = assert(context.instance),
	}, Ref)
end

	---@param methods table
	function M.expose(methods)
		---@cast active MiruContext
		local instance = assert(active.instance)
		for key, value in pairs(methods) do
			assert(instance[key] == nil)
			instance[key] = function(_, ...args)
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
