# Signal Native Runtime Plan

## 目标

Miru 是从 Soluna Playground 的 `core/view.lua` 独立出来的 Lua UI runtime。新库入口文件为 `miru.lua`，面向 Soluna 2D 的 layout、drawing、input 和 animation 场景。

本计划不保留旧 API 兼容负担。导入的 `miru.lua` 历史只是演进基础，目标实现应直接转向 signal-native retained UI graph，而不是在旧的 component render effect 模型上叠加新名字。

最终效果：

- component build function 负责建立稳定 UI graph。
- signal 变化只更新依赖它的 binding、host node、canvas command 或 control-flow range。
- layout、paint、canvas 和 structure dirty 分离。
- Yoga layout 和 draw command compilation 在统一 flush 阶段延迟执行。
- 高频状态如 hover、pressed、frame、cursor、scroll 和 animation 不触发无关 component rebuild。

## 关键约束

- 不实现 Vue-style proxy table。
- 不兼容 `view.value`、旧 render effect 语义或旧 component rerender 行为。
- 不引入 DOM 概念；Miru 的输出仍然是 Soluna batch command。
- 不把 app/domain state 框架塞进 Miru。Miru 只提供 UI graph、signal、layout、draw 和 input primitives。
- 公共 API 必须能清楚区分 static value、signal value、event callback 和 control-flow children。

## 推荐模型

### Reactive Kernel

Miru 内部提供独立 reactive scope：

```lua
local count = miru.signal(0)
local label = miru.memo(function()
	return "Count: " .. tostring(count())
end)

miru.effect(function()
	print(label())
end)
```

核心 primitive：

- `miru.signal(initial)`：返回 callable getter/setter。
- `miru.memo(fn)`：lazy cached derived signal，依赖变更时失效，读取时重算。
- `miru.effect(fn)`：用于 runtime binding 和用户显式 side effect。
- `miru.batch(fn)`：合并同步写入并延迟 flush。
- `miru.untrack(fn)`：读取 signal 但不订阅当前 effect。
- `miru.get(value)`：统一读取 static value 或 signal/memo。

effect 必须有 owner scope。component、host binding、control-flow range、animation 都拥有自己的 cleanup scope，销毁节点时同步停止相关 effect。

### Component Build

component chunk 仍然返回一个 build function，但 build function 只在 mount 时执行一次。

```lua
local miru = require "miru"

local args = ...
local count = miru.signal(0)

return function()
	miru.hbox({
		width = args.width,
		height = 36,
	}, function()
		miru.text(miru.memo(function()
			return "Count: " .. tostring(count())
		end))
	end)
end
```

裸读 signal 不应订阅 component build。debug 模式下，在 component build scope 直接读取 signal 可以报错或记录 diagnostic，避免退化为 component rerender model。

### Host Binding

host node 保留 raw props 和 resolved props。prop 值可以是 static value 或 signal/memo。runtime 在 host node 上为动态 prop 建立 binding effect。

```lua
miru.box({
	width = miru.memo(function()
		return expanded() and 320 or 180
	end),
	background = miru.memo(function()
		return active() and theme.color.selection or theme.color.surface
	end),
})
```

prop 更新按 dirty 类型分类：

- structure dirty：children/control-flow range 改变。
- layout dirty：width、height、flex、position、padding 等 Yoga props 改变。
- paint dirty：background、text、color、transform 等 draw props 改变。
- canvas dirty：canvas draw function 读取的 signal 改变。

### Control Flow

动态结构必须通过显式 control-flow primitive 表达，不能依赖 component rerender：

```lua
miru.when(open, function()
	miru.mount("menu", {
		items = items,
	})
end)

miru.each(rows, function(row)
	return row.id
end, function(row)
	miru.mount("row", {
		row = row,
	})
end)
```

需要的 primitive：

- `miru.when(condition, children, fallback?)`
- `miru.switch(discriminator, cases, fallback?)`
- `miru.each(list, key, children)`
- `miru.dynamic(component, props?)` only if runtime use cases prove it is needed

`each` 必须 keyed。无 key 的 list diff 容易隐藏 O(n) 重建和状态错位，不适合作为默认。

### Layout And Draw

Miru 应使用一个 Yoga tree per root。component wrapper、slot/range anchor 和 host nodes 都在同一棵 Yoga tree 中。

runtime flush 顺序：

1. Flush reactive writes and queued effects.
2. Apply structure changes.
3. Apply layout prop changes and mark Yoga dirty.
4. Run Yoga once per dirty root.
5. Rebuild dirty canvas command lists.
6. Compile dirty draw command tree once per dirty root.
7. Draw compiled commands to Soluna batch.

`miru:draw(batch)` 可以调用 `ensure_layout()` 和 `ensure_commands()`，但不能在每个 signal effect 内重复 compile root commands。

### Text And Canvas

`miru.text(source, props)` 支持 source 为 static value 或 signal/memo。text stream 生成应按 text、font、size、color、align、width、height 建立稳定缓存。

`miru.canvas(props, draw)` 的 draw function 在 canvas binding scope 中运行。它读取 signal 时只订阅该 canvas，不订阅 component。canvas 尺寸来自 Yoga layout，尺寸变化和 signal 变化都只重建该 canvas 的 command list。

### Interaction

interaction state 应是 signal：

- `miru.hovered()`
- `miru.pressed()`
- `miru.focused()`
- `miru.ref()`
- `miru.clickable(props)`
- `miru.dismissable(props)`

Pointer hit test 使用已计算的 retained tree。输入事件只更新相关 interaction signal，后续 binding effect 决定哪些 visual state 更新。

### Animation

Animation 应基于 signal/memo，而不是 component render effect：

```lua
local progress = miru.tween(function()
	return open() and 1 or 0
end, {
	duration = 0.14,
})
```

`miru.tween` 输出 signal。每帧 step 只写 progress signal，由 host binding 或 canvas binding 消费。

## API 草案

最低公共 API：

```lua
miru.new(args)
miru.signal(initial)
miru.memo(fn)
miru.effect(fn)
miru.batch(fn)
miru.untrack(fn)
miru.get(value)

miru.mount(chunk, props?)
miru.box(props?, children?)
miru.hbox(props?, children?)
miru.vbox(props?, children?)
miru.text(source, props?)
miru.canvas(props?, draw?)

miru.when(condition, children, fallback?)
miru.switch(discriminator, cases, fallback?)
miru.each(list, key, children)

miru.ref()
miru.clickable(props?)
miru.dismissable(props?)
miru.hovered()
miru.pressed()
miru.tween(target, opts?)
miru.transition(props, children)
```

## 成功标准

- Updating one signal used by one text node rebuilds only that text command.
- Updating one draw-only prop does not run Yoga.
- Updating one layout prop runs Yoga once for the root and does not rebuild unaffected canvas lists.
- Updating a focused cursor/frame signal does not rebuild the owning component.
- `each` preserves child state across insert, remove, reorder and update by key.
- Destroying a component/range stops all owned signals, effects, refs, interaction state and animations.
- Pointer events use retained tree geometry and still produce owner-local coordinates.
- Batch updates coalesce so many signal writes in one tick produce one flush.

## 测试策略

Test layers:

- Reactive kernel tests: signal, memo laziness, effect cleanup, batch, untrack.
- Host binding tests: text, layout prop, paint prop, canvas dependency isolation.
- Control-flow tests: when, switch, keyed each lifecycle and ordering.
- Layout tests: unified Yoga tree, intrinsic size, parent-size propagation, refs.
- Interaction tests: hover, pressed, click, dismissable, pointer local coordinates.
- Animation tests: tween signal, transition lifecycle, frame coalescing.
- Performance tests: counters for component builds, binding runs, Yoga runs, command compiles.

The key metric is not total FPS. The key metric is whether an update touches only the graph nodes that semantically depend on the changed signal.

### Showcase Metrics Feature Test

最终需要一个可交互的 feature test，用来直观看到 signal-native runtime 的实际效果。这个测试不是人工拼出来的 demo 面板，而应该优先使用真实组件样本：现有 component showcase/test_components 形态，以及 Ishiku 中实际使用过的 button、switch、dropdown、text_field、preference 等组件形态。

建议入口：

```text
test/feature/test_showcase_metrics.lua
```

运行后应展示一组典型组件和一个 metrics 面板。metrics 至少包含：

- component build count
- binding run count
- Yoga layout count
- text command rebuild count
- canvas rebuild count
- root command compile count

测试应提供几类可手动触发的场景：

- hover/pressed/open 这类局部交互状态。
- text field cursor/frame、selection、input text 更新。
- keyed list 中单个 row 的 signal 更新。
- draw-only prop 更新。
- layout prop 更新。
- 批量 signal 写入。

验收重点是让人能直观看到更新粒度：局部状态变化只推动相关 binding/text/canvas/layout 计数，而不是让无关组件或整棵树一起 rebuild。自动断言可以覆盖关键指标，但这个 feature test 的主要价值是可运行、可观察、可比较。
