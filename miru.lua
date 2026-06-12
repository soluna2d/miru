local font = require "core.font"
local sfont = require "soluna.font"
local matquad = require "soluna.material.quad"
local mattext = require "soluna.material.text"
local yoga = require "soluna.layout.yoga"
local floor = math.floor
local min = math.min
local max = math.max
---@class SolunaFile
---@field searchpath fun(name: string, path: string): string?
---@field load fun(path: string): string?
---@type SolunaFile
---@diagnostic disable-next-line: assign-type-mismatch
local file = require "soluna.file"

local COMPONENT_PATH <const> = "?.lua;?/init.lua"

---@class ViewCommand
---@field name string
---@field args table
---@field draw fun(batch: ViewBatch)?

---@alias ViewAnimatedTarget fun(): number

---@class (partial) ViewAnimation
---@overload fun(): number
---@field view View
---@field value ViewValue<number>
---@field from number
---@field to number
---@field elapsed number
---@field duration number
---@field easing fun(t: number): number
---@field active boolean?
---@field listed boolean?
---@field stopped boolean?
---@field effect ViewEffect?
---@field owner_scope ViewOwner?

---@class ViewTransitionRenderState
---@field show boolean
---@field progress number
---@field phase string

---@class ViewTransitionState
---@field animation ViewAnimation
---@field show boolean
---@field mounted boolean

---@class ViewRenderNode
---@field kind string
---@field key any
---@field chunk string?
---@field node lightuserdata
---@field parent ViewRenderNode?
---@field children ViewRenderNode[]
---@field cursor integer
---@field instance ViewInstance?
---@field owner ViewInstance?
---@field draw fun(width: number, height: number)?
---@field commands ViewCommand[]?
---@field props table?
---@field raw_props table?
---@field direction string?
---@field text any
---@field text_source any
---@field ref ViewRef?
---@field transition ViewTransitionState?
---@field prop_effect ViewEffect?
---@field text_effect ViewEffect?
---@field owner_scope ViewOwner?
---@field canvas_owner ViewOwner?

---@class ViewLayout
---@field x number?
---@field y number?
---@field w number?
---@field h number?

---@alias ViewHitMode "clickable"|"component"

---@class ViewBatch
---@field layer fun(self: ViewBatch, ...: number)
---@field add fun(self: ViewBatch, ...: any)

---@class (partial) ViewEffect
---@field scope ViewScope
---@field fn fun()
---@field deps table[]
---@field order integer
---@field queued boolean?
---@field queue_order integer?
---@field stopped boolean?

---@class (partial) ViewScope
---@field targets table
---@field active ViewEffect?
---@field queue table<integer, ViewEffect?>
---@field queue_head integer
---@field queue_tail integer

---@class (partial) ViewValue<T>
---@overload fun(): T
---@overload fun(value: T)
---@field scope ViewScope
---@field value T

---@alias ViewComputed<T> fun(): T

---@class (partial) ViewComputedState<T>
---@field effect ViewEffect?
---@field value ViewValue<T>

---@alias ViewDisposable ViewComputedState<any>|ViewAnimation

---@class (partial) ViewAnimatedState
---@field animation ViewAnimation
---@field effect ViewEffect?

---@type fun(node: ViewRenderNode)
local dispose_render_instances
---@type fun(instance: ViewInstance): ViewInstance
local root_instance
---@type fun(instance: ViewInstance): ViewCommand[]
local compile_render_tree

---@class (partial) ViewInstance
---@field view View
---@field parent ViewInstance?
---@field layout ViewLayout
---@field disposables ViewDisposable[]?
---@field mounted boolean?
---@field effect ViewEffect?
---@field commands ViewCommand[]?
---@field render_node ViewRenderNode?
---@field layout_version ViewValue<integer>
---@field build_count integer
---@field props table
---@field args table
---@field clickable ViewClickable?
---@field dismissable ViewDismissable?
---@field dismissable_index integer?
---@field hovered ViewValue<boolean>?
---@field pressed ViewValue<boolean>?
---@field ref ViewRef?
---@field owner_scope ViewOwner?

---@class (partial) View
---@field scope ViewScope
---@field instances ViewInstance[]
---@field w number
---@field h number
---@field layout_version ViewValue<integer>
---@field pointer_x number?
---@field pointer_y number?
---@field hovered_instance ViewInstance?
---@field pressed_instance ViewInstance?
---@field pressed_button integer?
---@field stats ViewStatistics
---@field resources table
---@field animations ViewAnimation[]
---@field dismissables ViewInstance[]
---@field effect_order integer

---@class ViewContext
---@field view View
---@field instance ViewInstance?
---@field disposables ViewDisposable[]?
---@field drawing boolean?
---@field rendering boolean?
---@field owner ViewOwner?

---@class ViewRenderContext
---@field view View
---@field instance ViewInstance
---@field parent ViewRenderNode

---@class ViewPointerEvent
---@field target ViewInstance?
---@field current_target ViewInstance
---@field x number
---@field y number
---@field button integer?

---@class ViewDismissable
---@field enabled? any
---@field on_dismiss? fun(event: ViewPointerEvent)

---@class ViewClickable
---@field enabled? any
---@field on_click? fun(event: ViewPointerEvent)
---@field on_pointer_down? fun(event: ViewPointerEvent)
---@field on_pointer_up? fun(event: ViewPointerEvent)
---@field on_pointer_enter? fun(event: ViewPointerEvent)
---@field on_pointer_leave? fun(event: ViewPointerEvent)
---@field on_pointer_move? fun(event: ViewPointerEvent)

---@class ViewRect
---@field x number
---@field y number
---@field w number
---@field h number

---@class ViewStatistics
---@field render_count integer
---@field binding_count integer
---@field command_compile_count integer

---@class (partial) ViewRef
---A component-owned geometry handle. `rect()` returns owner-local coordinates.
---@field owner ViewInstance
---@field current any
---@field rect fun(self: ViewRef): ViewRect?

---@class ViewModule
---@field batch ViewBatch
---@field new fun(args?: table): View
---@field value fun(value: any): ViewValue<any>
---@field resource fun(name: string): any
---@field mount fun(chunk: string, props?: table): ViewInstance
---@field box fun(props?: table, children?: fun()): ViewRenderNode
---@field hbox fun(props?: table, children?: fun()): ViewRenderNode
---@field vbox fun(props?: table, children?: fun()): ViewRenderNode
---@field canvas fun(props?: table, draw?: fun(width: number, height: number)): ViewRenderNode
---@field text fun(text: any, props?: table): ViewRenderNode
---@field clickable fun(props?: ViewClickable)
---@field dismissable fun(props?: ViewDismissable)
---@field hovered fun(): ViewValue<boolean>
---@field pressed fun(): ViewValue<boolean>
---@field ref fun(): ViewRef
---@field computed fun(fn: function): ViewComputed<any>
---@field signal fun(value: any): ViewValue<any>
---@field memo fun(fn: function): ViewComputed<any>
---@field effect fun(fn: function): ViewEffect
---@field untrack fun(fn: function): any
---@field get fun(value: any): any
---@field animated fun(fn: ViewAnimatedTarget, opts?: table): ViewAnimation
---@field transition fun(props: table, children: fun(state: ViewTransitionRenderState))
---@field lerp fun(a: number, b: number, t: number): number
---@field lerp_color fun(a: integer, b: integer, t: number): integer
---@field cleanup fun(fn: fun())

---@class ViewOwner
---@field kind string
---@field view View
---@field parent ViewOwner?
---@field instance ViewInstance?
---@field node ViewRenderNode?
---@field cleanups any[]
---@field stopped boolean?

---@type ViewContext?
local active

---@type ViewRenderContext?
local active_render

---@type ViewCommand[]?
local active_batch

---@param owner ViewOwner
---@param base ViewContext?
---@return ViewContext
local function owner_context(owner, base)
	base = base or active
	return {
		view = owner.view,
		instance = owner.instance or (base and base.instance),
		owner = owner,
		disposables = owner.cleanups,
		drawing = base and base.drawing,
		rendering = base and base.rendering,
	}
end

---@param view View
---@param kind string
---@param parent ViewOwner?
---@param instance ViewInstance?
---@param node ViewRenderNode?
---@return ViewOwner
local function new_owner(view, kind, parent, instance, node)
	return {
		kind = kind,
		view = view,
		parent = parent,
		instance = instance,
		node = node,
		cleanups = {},
	}
end

---@param cleanup any
local function run_cleanup(cleanup)
	if type(cleanup) == "function" then
		cleanup()
		return
	end
	if cleanup and cleanup.stop then
		cleanup:stop()
	end
end

---@param owner ViewOwner?
local function stop_owner(owner)
	if not owner or owner.stopped then
		return
	end
	owner.stopped = true
	for i = #owner.cleanups, 1, -1 do
		local cleanup = owner.cleanups[i]
		owner.cleanups[i] = nil
		run_cleanup(cleanup)
	end
end

---@param owner ViewOwner
---@param cleanup any
local function add_owner_cleanup(owner, cleanup)
	if owner.stopped then
		run_cleanup(cleanup)
		return
	end
	owner.cleanups[#owner.cleanups + 1] = cleanup
end

---@generic T
---@param owner ViewOwner
---@param fn fun(): T
---@return T
local function run_with_owner(owner, fn)
	local prev = active
	active = owner_context(owner, prev)
	local ok, result = pcall(fn)
	active = prev
	if not ok then
		error(result, 0)
	end
	return result
end

---@param owner ViewOwner
---@param fn fun()
---@return ViewEffect
local function owner_effect(owner, fn)
	local effect = owner.view.scope:effect(function()
		return run_with_owner(owner, fn)
	end)
	add_owner_cleanup(owner, effect)
	return effect
end

---@param owner ViewOwner
---@param fn fun()
---@return ViewEffect
local function owner_lazy_effect(owner, fn)
	local effect = owner.view.scope:lazy_effect(function()
		return run_with_owner(owner, fn)
	end)
	add_owner_cleanup(owner, effect)
	return effect
end

---@param scope ViewScope
local function assert_reactive_read_allowed(scope)
	local context = active
	if context and context.rendering and not scope.active then
		error("signal read during component build; pass reactive values to bindings or wrap derived values in miru.memo",
			3)
	end
end

---@param view View
---@param instance ViewInstance
local function register_dismissable(view, instance)
	if instance.dismissable_index then
		return
	end
	local dismissables = view.dismissables
	local index = #dismissables + 1
	dismissables[index] = instance
	instance.dismissable_index = index
end

---@param instance ViewInstance
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
---@return ViewCommand
local function command(name, ...args)
	return {
		name = name,
		args = args,
	}
end

---@param version ViewValue<integer>
local function bump_version(version)
	-- Version bumps must not subscribe the currently running render effect.
	version(rawget(version, "value") + 1)
end

---@param value any
---@return boolean
local function is_reactive(value)
	return type(value) == "table" and rawget(value, "scope") ~= nil
end

---@param value any
---@return any
local function read_value(value)
	if is_reactive(value) then
		return value()
	end
	return value
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
local function read_resource(name)
	---@cast active ViewContext
	local view = active.view
	view.scope:track(view.resources, name)
	return assert(view.resources[name])
end

---@type fun(target: any): ViewRect?
local rect_of

---@class (partial) ViewRef
local Ref = {}; do
	Ref.__index = Ref

	---@return ViewRect?
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

---@class (partial) ViewScope
local Scope = {}; do
	---@param effect ViewEffect
	local function cleanup(effect)
		for i = 1, #effect.deps do
			effect.deps[i][effect] = nil
			effect.deps[i] = nil
		end
	end

	Scope.__index = Scope

	---@class (partial) ViewEffect
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

	---@class (partial) ViewValue<T>
	local Value = {}; do
		---@generic T
		---@param self ViewValue<T>
		---@return T
		local function read(self)
			local scope = rawget(self, "scope")
			assert_reactive_read_allowed(scope)
			scope:track(self, "value")
			return rawget(self, "value")
		end

		---@generic T
		---@param self ViewValue<T>
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

	---@param effect ViewEffect
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
		if self.auto_flush and self.batch_depth == 0 and not self.flushing then
			self:flush()
		end
	end

	---@param effect ViewEffect
	function Scope:run(effect)
		if effect.stopped then
			return
		end
		cleanup(effect)
		local prev = self.active
		self.active = effect
		local ok, err = pcall(effect.fn)
		self.active = prev
		if not ok then
			error(err, 0)
		end
	end

	---@generic T
	---@param value T
	---@return ViewValue<T>
	function Scope:value(value)
		return setmetatable({
			scope = self,
			value = value,
		}, Value)
	end

	---@param fn fun()
	---@param order integer?
	---@return ViewEffect
	function Scope:effect(fn, order)
		---@type ViewEffect
		local effect = setmetatable({
			scope = self,
			fn = fn,
			deps = {},
			order = order or 0,
		}, Effect)
		self:run(effect)
		return effect
	end

	---@param fn fun()
	---@param order integer?
	---@return ViewEffect
	function Scope:lazy_effect(fn, order)
		---@type ViewEffect
		return setmetatable({
			scope = self,
			fn = fn,
			deps = {},
			order = order or 0,
		}, Effect)
	end

	function Scope:flush()
		self.flushing = true
		while self.queue_head <= self.queue_tail do
			---@type ViewEffect[]
			local batch = {}
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
				---@cast effect ViewEffect
				if effect.queued and not effect.stopped then
					effect.queued = nil
					effect.queue_order = nil
					self:run(effect)
				end
			end
		end
		self.queue_head = 1
		self.queue_tail = 0
		self.flushing = nil
	end

	---@generic T
	---@param fn fun(): T
	---@return T
	function Scope:batch(fn)
		self.batch_depth = (self.batch_depth or 0) + 1
		local ok, result = pcall(fn)
		self.batch_depth = self.batch_depth - 1
		if not ok then
			error(result, 0)
		end
		if self.auto_flush and self.batch_depth == 0 then
			self:flush()
		end
		return result
	end

	---@generic T
	---@param effect ViewEffect
	---@param fn fun(): T
	---@return T
	function Scope:compute(effect, fn)
		cleanup(effect)
		local prev = self.active
		self.active = effect
		local ok, result = pcall(fn)
		self.active = prev
		if not ok then
			error(result, 0)
		end
		return result
	end
end

---@param auto_flush boolean?
---@return ViewScope
local function new_scope(auto_flush)
	return setmetatable({
		targets = setmetatable({}, {
			__mode = "k",
		}),
		queue = {},
		queue_head = 1,
		queue_tail = 0,
		batch_depth = 0,
		auto_flush = auto_flush,
	}, Scope)
end

local reactive_scope = new_scope(true)

---@class (partial) ViewAnimation
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
		if self.owner_scope then
			stop_owner(self.owner_scope)
			self.owner_scope = nil
		end
		if self.effect then
			self.effect:stop()
			self.effect = nil
		end
	end
end

---@class (partial) View
local View = {}; do
	View.__index = View

	---@class (partial) ViewInstance
	local Instance = {}; do
		Instance.__index = Instance

		---@return number, number
		function Instance:origin()
			local node = assert(self.render_node)
			local x, y = yoga.node_get(node.node)
			return x, y
		end

		---@param batch ViewBatch
		function Instance:draw(batch)
			if not self.commands then
				self.commands = compile_render_tree(self)
			end
			for i = 1, #self.commands do
				local item = self.commands[i]
				local draw = item.draw
				if draw then
					draw(batch)
				else
					---@type fun(batch: ViewBatch, ...: any)
					---@diagnostic disable-next-line: undefined-field
					local f = assert(batch[item.name])
					local args = item.args
					f(batch, table.unpack(args, 1, args.n))
				end
			end
		end

		---@param disposing_render_tree boolean?
		function Instance:destroy(disposing_render_tree)
			if not self.mounted then
				return
			end
			local view = self.view
			local render_node = self.render_node
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
			stop_owner(self.owner_scope)
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
			if root and root.mounted then
				root.commands = compile_render_tree(root)
			end
			self.commands = nil
		end
	end

	---@param holder table
	---@param ref ViewRef?
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

	---@type fun(props: table?, direction: string?): table
	local layout_style

	---@param props table?
	---@return boolean
	local function has_reactive_props(props)
		for _, value in pairs(props or {}) do
			if is_reactive(value) then
				return true
			end
		end
		return false
	end

	---@param node ViewRenderNode
	local function mark_node_commands_dirty(node)
		local owner = node.owner or node.instance
		if not owner or not owner.mounted then
			return
		end
		root_instance(owner).commands = nil
	end

	---@param node ViewRenderNode
	---@return table
	local function resolve_props(node)
		local raw = node.raw_props
		local resolved = {}
		for key, value in pairs(raw or {}) do
			resolved[key] = read_value(value)
		end
		return resolved
	end

	---@param node ViewRenderNode
	---@param resolved table
	---@return boolean
	local function props_changed(node, resolved)
		local current = node.props
		if not current then
			return true
		end
		for key, value in pairs(resolved) do
			if current[key] ~= value then
				return true
			end
		end
		for key in pairs(current) do
			if resolved[key] == nil then
				return true
			end
		end
		return false
	end

	---@param node ViewRenderNode
	local function apply_resolved_props(node)
		local resolved = resolve_props(node)
		if not props_changed(node, resolved) then
			return
		end
		node.props = resolved
		bind_ref(node, resolved.ref, node)
		yoga.node_set(node.node, layout_style(resolved, node.direction))
		mark_node_commands_dirty(node)
	end

	---@param node ViewRenderNode
	local function stop_node_bindings(node)
		stop_owner(node.canvas_owner)
		node.canvas_owner = nil
		stop_owner(node.owner_scope)
		if node.prop_effect then
			node.prop_effect:stop()
			node.prop_effect = nil
		end
		if node.text_effect then
			node.text_effect:stop()
			node.text_effect = nil
		end
	end

	---@param view View
	---@param node ViewRenderNode
	---@param props table?
	---@param direction string?
	local function bind_node_props(view, node, props, direction)
		node.raw_props = props
		node.direction = direction
		if has_reactive_props(props) then
			if not node.prop_effect then
				node.prop_effect = owner_effect(assert(node.owner_scope), function()
					view.stats.binding_count = view.stats.binding_count + 1
					apply_resolved_props(node)
				end)
			else
				apply_resolved_props(node)
			end
			return
		end
		if node.prop_effect then
			node.prop_effect:stop()
			node.prop_effect = nil
		end
		apply_resolved_props(node)
	end

	---@param view View
	---@param node ViewRenderNode
	---@param source any
	local function bind_node_text(view, node, source)
		node.text_source = source
		if is_reactive(source) then
			if not node.text_effect then
				node.text_effect = owner_effect(assert(node.owner_scope), function()
					view.stats.binding_count = view.stats.binding_count + 1
					local text = read_value(node.text_source)
					if node.text == text then
						return
					end
					node.text = text
					mark_node_commands_dirty(node)
				end)
			else
				local text = read_value(source)
				if node.text ~= text then
					node.text = text
					mark_node_commands_dirty(node)
				end
			end
			return
		end
		if node.text_effect then
			node.text_effect:stop()
			node.text_effect = nil
		end
		if node.text ~= source then
			node.text = source
			mark_node_commands_dirty(node)
		end
	end

	---@type fun(instance: ViewInstance, x: number, y: number, mode: ViewHitMode): ViewInstance?, number?, number?
	local hit_instance
	---@type fun(node: ViewRenderNode, x: number, y: number, mode: ViewHitMode): ViewInstance?, number?, number?
	local hit_render_node

	---@param value ViewValue<boolean>?
	---@param state boolean
	local function set_state(value, state)
		if value then
			value(state)
		end
	end

	---@param instance ViewInstance
	---@return boolean
	local function clickable_enabled(instance)
		local clickable = instance.clickable
		if not clickable then
			return false
		end
		local enabled = clickable.enabled
		return enabled == nil or enabled ~= false
	end

	---@param instance ViewInstance
	---@param mode ViewHitMode
	---@return boolean
	local function instance_hittable(instance, mode)
		return mode == "component" or clickable_enabled(instance)
	end

	---@param target ViewInstance?
	---@param current_target ViewInstance
	---@param x number
	---@param y number
	---@param button integer?
	---@return ViewPointerEvent
	local function pointer_event(target, current_target, x, y, button)
		return {
			target = target,
			current_target = current_target,
			x = x,
			y = y,
			button = button,
		}
	end

	---@param instance ViewInstance
	---@param name string
	---@param event ViewPointerEvent
	local function call_clickable(instance, name, event)
		local clickable = instance.clickable
		if not clickable then
			return
		end
		---@type fun(event: ViewPointerEvent)?
		---@diagnostic disable-next-line: undefined-field
		local callback = clickable[name]
		if callback then
			callback(event)
		end
	end

	---@param target ViewInstance?
	---@param current_target ViewInstance
	---@param x number
	---@param y number
	---@param button integer?
	---@return ViewPointerEvent
	local function pointer_event_at(target, current_target, x, y, button)
		local ox, oy = current_target:origin()
		return pointer_event(target, current_target, x - ox, y - oy, button)
	end

	---@param instance ViewInstance
	---@return boolean
	local function dismissable_enabled(instance)
		local dismissable = instance.dismissable
		if not dismissable then
			return false
		end
		local enabled = dismissable.enabled
		return enabled == nil or enabled ~= false
	end

	---@param target ViewInstance?
	---@param boundary ViewInstance
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

	---@param instance ViewInstance
	---@param target ViewInstance?
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

	---@param view View
	---@param target ViewInstance?
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
			---@cast target ViewRenderNode
			local x, y, w, h = yoga.node_get(target.node)
			return {
				x = x,
				y = y,
				w = w,
				h = h,
			}
		end
		---@cast target ViewInstance
		local node = assert(target.render_node)
		local x, y, w, h = yoga.node_get(node.node)
		return {
			x = x,
			y = y,
			w = w,
			h = h,
		}
	end

	---@param instance ViewInstance
	---@param x number
	---@param y number
	---@param mode ViewHitMode
	---@return ViewInstance?, number?, number?
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

	---@param node ViewRenderNode
	---@param x number
	---@param y number
	---@param mode ViewHitMode
	---@return ViewInstance?, number?, number?
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

	---@param view View
	---@param x number
	---@param y number
	---@param mode ViewHitMode
	---@return ViewInstance?, number?, number?
	local function hit_view(view, x, y, mode)
		for i = #view.instances, 1, -1 do
			local target, tx, ty = hit_instance(view.instances[i], x, y, mode)
			if target then
				return target, tx, ty
			end
		end
		return nil, nil, nil
	end

	---@param view View
	---@param x number
	---@param y number
	---@return ViewInstance?, number?, number?
	local function hit_clickable_view(view, x, y)
		return hit_view(view, x, y, "clickable")
	end

	---@param view View
	---@param x number
	---@param y number
	---@return ViewInstance?, number?, number?
	local function hit_component_view(view, x, y)
		return hit_view(view, x, y, "component")
	end

	---@param view View
	---@param target ViewInstance?
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
	layout_style = function(props, direction)
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

	---@param node ViewRenderNode
	function dispose_render_instances(node)
		stop_node_bindings(node)
		bind_ref(node, nil, node)
		if node.transition then
			node.transition.animation:stop()
			node.transition = nil
		end
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

	---@param parent ViewRenderNode
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

	---@param parent ViewRenderNode
	---@param index integer
	local function remove_render_children_from(parent, index)
		for i = #parent.children, index, -1 do
			remove_render_child(parent, i)
		end
	end

	local mount_component
	local patch_props

	---@type table<any, boolean>
	local transition_prop_keys <const> = {
		show = true,
		duration = true,
		easing = true,
		appear = true,
	}

	---@param props table?
	---@param mounted boolean
	---@return table
	local function transition_style(props, mounted)
		local style = {}
		for key, value in pairs(props or {}) do
			local internal = transition_prop_keys[key] == true
			if not internal then
				style[key] = value
			end
		end
		if mounted then
			style.display = style.display or "flex"
		else
			style.display = "none"
		end
		return style
	end

	---@param view View
	---@param props table?
	---@return ViewTransitionState
	local function create_transition(view, props)
		props = props or {}
		local show = props.show == true
		local initial = show and 1 or 0
		---@type ViewAnimation
		local animation = setmetatable({
			view = view,
			value = view.scope:value(initial),
			from = initial,
			to = initial,
			elapsed = 0,
			duration = props.duration or 0.14,
			easing = easing(props),
		}, Animation)
		---@type ViewTransitionState
		local state = {
			animation = animation,
			show = show,
			mounted = show,
		}
		if show and props.appear then
			animation:jump(0)
			animation:retarget(1)
		end
		return state
	end

	---@param state ViewTransitionState
	---@param props table?
	local function update_transition(state, props)
		props = props or {}
		local show = props.show == true
		local target = show and 1 or 0
		state.animation.duration = props.duration or 0.14
		state.animation.easing = easing(props)
		state.show = show
		if show then
			state.mounted = true
		end
		if state.animation.to ~= target then
			state.animation:retarget(target)
		end
	end

	---@param state ViewTransitionState
	---@return ViewTransitionRenderState
	local function transition_render_state(state)
		local progress = rawget(state.animation.value, "value")
		local phase
		if state.show then
			phase = progress >= 1 and "entered" or "enter"
		else
			phase = progress <= 0 and "left" or "leave"
		end
		if phase == "left" then
			state.mounted = false
		end
		return {
			show = state.show,
			progress = progress,
			phase = phase,
		}
	end

	-- Render nodes patch the Yoga tree by sibling order plus optional key.
	-- Component nodes keep their setup instance and only patch props on rerender.
	---@param kind string
	---@return string
	local function node_owner_kind(kind)
		if kind == "canvas" then
			return "canvas"
		end
		if kind == "transition" then
			return "control-flow"
		end
		return "host"
	end

	---@param ctx ViewRenderContext
	---@return ViewOwner?
	local function current_render_owner(ctx)
		if active and active.owner then
			return active.owner
		end
		return ctx.instance.owner_scope
	end

	---@param ctx ViewRenderContext
	---@param kind string
	---@param key any
	---@param props table?
	---@param direction string?
	---@return ViewRenderNode
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
			node.owner_scope = new_owner(ctx.view, node_owner_kind(kind), current_render_owner(ctx), ctx.instance, node)
			parent.children[index] = node
		end
		bind_node_props(ctx.view, node, props, direction)
		return node
	end

	---@param ctx ViewRenderContext
	---@param node ViewRenderNode
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

	---@param instance ViewInstance
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

	---@param node ViewRenderNode
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
		local prev = active_batch
		active_batch = commands
		stop_owner(node.canvas_owner)
		node.canvas_owner = new_owner(assert(node.owner_scope).view, "canvas", node.owner_scope, node.owner, node)
		local ok, err = pcall(function()
			return run_with_owner(assert(node.canvas_owner), function()
				return draw(width, height)
			end)
		end)
		active_batch = prev
		if not ok then
			error(err, 0)
		end
	end

	---@param props table?
	---@return number, number, number, number
	local function draw_transform(props)
		if not props then
			return 0, 0, 1, 0
		end
		return props.translateX or 0, props.translateY or 0, props.scale or 1, props.rotation or 0
	end

	---@param node ViewRenderNode
	---@param out ViewCommand[]
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
		local component_instance
		if node.kind == "component" then
			component_instance = assert(node.instance)
			set_instance_layout(component_instance, 0, 0, w, h)
		end

		if scale ~= 1 or rotation ~= 0 then
			out[#out + 1] = command("layer", scale, rotation, draw_x, draw_y)
		else
			out[#out + 1] = command("layer", draw_x, draw_y)
		end
		if props and props.background ~= nil then
			local background = props.background
			if background then
				out[#out + 1] = command("add", matquad.quad(pixel_size(w), pixel_size(h), background), 0, 0)
			end
		end
		if node.kind == "text" then
			local text = node.text
			local font_resource = read_resource "font"
			local fontid = assert(font_resource.loaded).id
			local cobj = assert(font_resource.ptr)
			local size = props and props.size or 16
			local color = props and props.color or 0xffffffff
			local align = props and props.align or "LC"
			local block = mattext.block(cobj, fontid, size, color, align)
			out[#out + 1] = command("add", block(tostring(text or ""), pixel_size(w), pixel_size(h)), 0, 0)
		end
		if node.kind == "canvas" then
			run_canvas(node, w, h)
			local commands = node.commands
			if commands then
				for i = 1, #commands do
					out[#out + 1] = commands[i]
				end
			end
		end
		for i = 1, #node.children do
			compile_render_node(node.children[i], out, x, y)
		end
		out[#out + 1] = command "layer"
	end

	---@param instance ViewInstance
	---@return ViewCommand[]
	function compile_render_tree(instance)
		local prev = active
		active = {
			view = instance.view,
		}
		local ok, result = pcall(function()
			instance.view.stats.command_compile_count = instance.view.stats.command_compile_count + 1
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

			local out = {}
			compile_render_node(root, out, 0, 0)
			return out
		end)
		active = prev
		if not ok then
			error(result, 0)
		end
		return result
	end

	---@param props table?
	---@return ViewLayout
	local function layout(props)
		props = props or {}
		return {
			x = props.x,
			y = props.y,
			w = props.width,
			h = props.height,
		}
	end

	---@param instance ViewInstance
	---@param key string
	---@param value any
	local function set_prop(instance, key, value)
		local props = instance.props
		if props[key] == value then
			return
		end
		props[key] = value
		instance.view.scope:trigger(props, key)
	end

	---@param instance ViewInstance
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

	---@param instance ViewInstance
	---@return table
	local function component_args(instance)
		return setmetatable({}, {
			__index = function(_, key)
				local props = instance.props
				instance.view.scope:track(props, key)
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

	---@param instance ViewInstance
	---@return ViewInstance
	function root_instance(instance)
		while instance.parent do
			instance = instance.parent
		end
		return instance
	end

	---@param view View
	---@param chunk string
	---@param props table?
	---@param parent ViewInstance?
	---@param render_node ViewRenderNode
	---@return ViewInstance
	function mount_component(view, chunk, props, parent, render_node)
		local path = assert(file.searchpath(chunk, view.resources.component_path))
		local source = assert(file.load(path))
		---@diagnostic disable-next-line: assign-type-mismatch
		chunk = assert(load(source, "@" .. path, "t"))
		assert(type(chunk) == "function")

		---@type ViewInstance
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
			build_count = 0,
		}, Instance)
		instance.owner_scope = new_owner(view, parent and "component" or "root",
			render_node.owner_scope or (parent and parent.owner_scope), instance, render_node)
		render_node.instance = instance
		local args = component_args(instance)
		instance.args = args
		patch_props(instance, props)
		bind_ref(instance, props and props.ref, instance)

		local prev = active
		---@type ViewContext
		active = {
			view = view,
			instance = instance,
			disposables = instance.disposables,
			owner = instance.owner_scope,
		}
		local result = table.pack(pcall(chunk, args))
		---@cast result table<integer, any>
		active = prev
		if not result[1] then
			error(result[2], 0)
		end
		local draw = result[2]
		assert(type(draw) == "function")

		local nested_render = active_render ~= nil
		prev = active
		local prev_render = active_render
		local prev_effect = view.scope.active
		---@type ViewContext
		active = {
			view = view,
			instance = instance,
			drawing = true,
			rendering = true,
			owner = instance.owner_scope,
		}
		active_render = {
			view = view,
			instance = instance,
			parent = assert(instance.render_node),
		}
		view.scope.active = nil
		local ok, err = pcall(function()
			instance.build_count = instance.build_count + 1
			view.stats.render_count = view.stats.render_count + 1
			active_render.parent.cursor = 1
			draw()
			remove_render_children_from(active_render.parent, active_render.parent.cursor)
			if not nested_render then
				local root = root_instance(instance)
				root.commands = compile_render_tree(root)
			end
		end)
		view.scope.active = prev_effect
		active = prev
		active_render = prev_render
		if not ok then
			error(err, 0)
		end

		return instance
	end

	---@param chunk string
	---@param props table?
	---@return ViewInstance
	function View:mount(chunk, props)
		local node = {
			kind = "component",
			key = nil,
			chunk = chunk,
			node = yoga.node_new(),
			parent = nil,
			owner = nil,
			children = {},
			cursor = 1,
			props = props,
		}
		yoga.node_set(node.node, layout_style(props))
		local instance = mount_component(self, chunk, props, nil, node)
		self.instances[#self.instances + 1] = instance
		return instance
	end

	---@param props table?
	---@param direction string?
	---@param children fun()?
	---@return ViewRenderNode
	function View:render_element(props, direction, children)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local node = render_element(ctx, "box", props and props.key, props, direction)
		render_children(ctx, node, children)
		return node
	end

	---@param props table?
	---@param draw fun(width: number, height: number)?
	---@return ViewRenderNode
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
	---@return ViewRenderNode
	function View:render_text(text, props)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local node = render_element(ctx, "text", props and props.key, props)
		bind_node_text(self, node, text)
		remove_render_children_from(node, 1)
		return node
	end

	---@param chunk string
	---@param props table?
	---@param key any
	---@return ViewInstance
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
			node.owner_scope = new_owner(self, "host", current_render_owner(ctx), ctx.instance, node)
			parent.children[index] = node
			mount_component(self, chunk, props, ctx.instance, node)
		else
			patch_props(assert(node.instance), props)
		end
		local instance = assert(node.instance)
		instance.render_node = node
		bind_ref(instance, props and props.ref, instance)
		bind_node_props(self, node, props)
		return instance
	end

	---@param props table
	---@param children fun(state: ViewTransitionRenderState)
	---@return ViewRenderNode
	function View:render_transition(props, children)
		local ctx = assert(active_render)
		assert(ctx.view == self)
		local parent = ctx.parent
		local index = parent.cursor
		parent.cursor = index + 1

		local key = props.key
		local node = parent.children[index]
		if node and (node.kind ~= "transition" or node.key ~= key) then
			remove_render_children_from(parent, index)
			node = nil
		end
		if not node then
			node = {
				kind = "transition",
				key = key,
				node = yoga.node_new(parent.node),
				parent = parent,
				owner = ctx.instance,
				children = {},
				cursor = 1,
				transition = create_transition(self, props),
			}
			node.owner_scope = new_owner(self, "control-flow", current_render_owner(ctx), ctx.instance, node)
			parent.children[index] = node
		else
			update_transition(assert(node.transition), props)
		end

		local state = transition_render_state(assert(node.transition))
		local mounted = state.phase ~= "left"
		node.props = transition_style(props, mounted)
		bind_ref(node, props.ref, node)
		yoga.node_set(node.node, layout_style(node.props))
		if mounted then
			local prev = ctx.parent
			ctx.parent = node
			node.cursor = 1
			run_with_owner(assert(node.owner_scope), function()
				children(state)
			end)
			remove_render_children_from(node, node.cursor)
			ctx.parent = prev
		else
			remove_render_children_from(node, 1)
		end
		return node
	end

	---@param animation ViewAnimation
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
	---@return ViewInstance?
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

	---@param batch ViewBatch
	function View:draw(batch)
		for i = 1, #self.instances do
			self.instances[i]:draw(batch)
		end
	end

	---@return ViewStatistics
	function View:statistics()
		return self.stats
	end

	---@param name string
	---@param resource any
	function View:set_resource(name, resource)
		self.resources[name] = resource
		self.scope:trigger(self.resources, name)
	end
end

local M = {}

---@param args table?
---@return View
function M.new(args)
	args = args or {}
	---@type ViewScope
	local scope = new_scope()
	---@type View
	return setmetatable({
		scope = scope,
		instances = {},
		w = args.w or args.width or 0,
		h = args.h or args.height or 0,
		layout_version = scope:value(0),
		animations = {},
		dismissables = {},
		effect_order = 0,
		stats = {
			render_count = 0,
			binding_count = 0,
			command_compile_count = 0,
		},
		resources = {
			font = {
				loaded = font.load(),
				ptr = sfont.cobj(),
			},
			component_path = args.component_path or COMPONENT_PATH,
		},
	}, View)
end

---@class (partial) ViewComputedState<T>
local Computed = {}; do
	Computed.__index = Computed

	---@generic T
	---@return T
	function Computed:__call()
		if self.read then
			return self:read()
		end
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
---@return ViewValue<T>
function M.value(value)
	---@cast active ViewContext
	return active.view.scope:value(value)
end

---@generic T
---@param value T
---@return ViewValue<T>
function M.signal(value)
	local scope = active and active.view.scope or reactive_scope
	return scope:value(value)
end

---@param fn fun()
---@return ViewEffect
function M.effect(fn)
	if active and active.owner then
		return owner_effect(active.owner, fn)
	end
	local scope = active and active.view.scope or reactive_scope
	return scope:effect(fn)
end

---@generic T
---@param fn fun(): T
---@return ViewComputed<T>
function M.memo(fn)
	local owner = active and active.owner
	local scope = owner and owner.view.scope or active and active.view.scope or reactive_scope
	---@type ViewComputedState<T>
	local memo = setmetatable({
		scope = scope,
		dirty = true,
	}, Computed)
	local function invalidate()
		if memo.dirty then
			return
		end
		memo.dirty = true
		scope:trigger(memo, "value")
	end
	if owner then
		memo.effect = owner_lazy_effect(owner, invalidate)
	else
		memo.effect = scope:lazy_effect(invalidate)
	end
	function memo:read()
		assert_reactive_read_allowed(scope)
		if self.dirty then
			self.value = scope:compute(assert(self.effect), function()
				if owner then
					return run_with_owner(owner, fn)
				end
				return fn()
			end)
			self.dirty = false
		end
		scope:track(self, "value")
		return self.value
	end

	---@cast memo ViewComputed<T>
	return memo
end

---@generic T
---@param fn fun(): T
---@return T
function M.untrack(fn)
	local scope = active and active.view.scope or reactive_scope
	local prev = scope.active
	scope.active = nil
	local ok, result = pcall(fn)
	scope.active = prev
	if not ok then
		error(result, 0)
	end
	return result
end

---@generic T
---@param value T|ViewValue<T>|ViewComputed<T>
---@return T
function M.get(value)
	return read_value(value)
end

---@param name string
---@return any
function M.resource(name)
	return read_resource(name)
end

---@param fn ViewAnimatedTarget
---@param opts table?
---@return ViewAnimation
function M.animated(fn, opts)
	---@cast active ViewContext
	local parent_owner = assert(active.owner, "animated can only be used inside an owner")
	local view = active.view
	opts = opts or {}
	---@type ViewAnimation
	local animation = setmetatable({
		view = view,
		value = view.scope:value(0),
		from = 0,
		to = 0,
		elapsed = 0,
		duration = opts.duration or 0.14,
		easing = easing(opts),
	}, Animation)
	local owner = new_owner(view, "animation", parent_owner, active.instance, nil)
	animation.owner_scope = owner
	local first = true
	animation.effect = owner_effect(owner, function()
		local target = fn()
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
	add_owner_cleanup(parent_owner, animation)
	return animation
end

---@param fn fun()
function M.cleanup(fn)
	---@cast active ViewContext
	add_owner_cleanup(assert(active.owner, "cleanup can only be used inside an owner"), fn)
end

---@param props ViewClickable?
function M.clickable(props)
	---@cast active ViewContext
	local instance = assert(active.instance)
	instance.clickable = props or {}
end

---@param props ViewDismissable?
function M.dismissable(props)
	---@cast active ViewContext
	local instance = assert(active.instance)
	if props then
		instance.dismissable = props
		register_dismissable(active.view, instance)
	else
		unregister_dismissable(instance)
		instance.dismissable = nil
	end
end

---@return ViewValue<boolean>
function M.hovered()
	---@cast active ViewContext
	local instance = assert(active.instance)
	local hovered = instance.hovered
	if hovered then
		return hovered
	end
	hovered = active.view.scope:value(false)
	instance.hovered = hovered
	return hovered
end

---@return ViewValue<boolean>
function M.pressed()
	---@cast active ViewContext
	local instance = assert(active.instance)
	local pressed = instance.pressed
	if pressed then
		return pressed
	end
	pressed = active.view.scope:value(false)
	instance.pressed = pressed
	return pressed
end

---@return ViewRef
function M.ref()
	local context = assert(active)
	return setmetatable({
		owner = assert(context.instance),
	}, Ref)
end

---@param chunk string
---@param props table?
---@return ViewInstance
function M.mount(chunk, props)
	local ctx = assert(active_render, "mount can only be called while rendering")
	return ctx.view:render_component(chunk, props, props and props.key)
end

---@param props table?
---@param children fun()?
---@param direction string?
---@return ViewRenderNode
local function element(props, children, direction)
	local ctx = assert(active_render, "element can only be used while rendering")
	return ctx.view:render_element(props, direction, children)
end

---@param props table?
---@param children fun()?
---@return ViewRenderNode
function M.box(props, children)
	return element(props, children)
end

---@param props table?
---@param children fun()?
---@return ViewRenderNode
function M.hbox(props, children)
	return element(props, children, "row")
end

---@param props table?
---@param children fun()?
---@return ViewRenderNode
function M.vbox(props, children)
	return element(props, children, "column")
end

---@param props table
---@param children fun(state: ViewTransitionRenderState)
---@return ViewRenderNode
function M.transition(props, children)
	local ctx = assert(active_render, "transition can only be used while rendering")
	return ctx.view:render_transition(props, children)
end

---@param props table?
---@param draw fun(width: number, height: number)?
---@return ViewRenderNode
function M.canvas(props, draw)
	local ctx = assert(active_render, "canvas can only be used while rendering")
	return ctx.view:render_canvas(props, draw)
end

---@param text any
---@param props table?
---@return ViewRenderNode
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

	---@generic T
	---@param _ ViewBatch
	---@param fn fun(): T
	---@return T
	function Batch.__call(_, fn)
		local scope = active and active.view.scope or reactive_scope
		return scope:batch(fn)
	end

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
---@cast batch ViewBatch
M.batch = batch

---@generic T
---@param fn fun(): T, ...
---@return ViewComputed<T>
function M.computed(fn)
	---@cast active ViewContext
	local owner = assert(active.owner, "computed can only be used inside an owner")
	local view = active.view
	---@type ViewValue<T>
	local value = view.scope:value(nil)
	local effect = owner_effect(owner, function()
		local result = fn()
		value(result)
	end)
	---@type ViewComputedState<T>
	local computed = setmetatable({
		effect = effect,
		value = value,
	}, Computed)
	---@cast computed ViewComputed<T>
	return computed
end

---@cast M ViewModule
return M
