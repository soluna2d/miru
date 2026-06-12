---
name: miru
description: Use when modifying the Miru Lua UI runtime, plans, examples, tests, or skills in this repository. Covers signal-native retained UI graph design, miru.lua, Soluna batch/Yoga integration, component ownership, host bindings, control flow, refs, interaction state, canvas drawing, animation, and focused verification.
---

# Miru

Miru is a standalone Lua UI runtime for Soluna 2D. It was seeded from Soluna Playground's `core/view.lua`, but the target design is signal-native and has no compatibility obligation to the old view API.

## Design Checklist

Before editing runtime behavior, examples, or tests, identify:

- **Owner**: root, component, host node, control-flow range, canvas, animation, or external caller.
- **Role**: reactive kernel, retained tree, layout bridge, drawing bridge, interaction primitive, component primitive, test fixture, or planning document.
- **Signal boundary**: distinguish static values, signal/memo values, callbacks, and control-flow children.
- **Structure boundary**: component build establishes stable structure; dynamic structure must go through explicit control-flow primitives.
- **Binding boundary**: host props, text, canvas draw commands, and animation targets update through binding effects, not component rerender.
- **Dirty class**: classify changes as structure, layout, paint, canvas, or command dirty.
- **Geometry**: refs and pointer events read from the retained calculated tree and expose owner-local coordinates.
- **API surface**: add runtime APIs only when they support the signal-native model or a current testable use case.

## Current Direction

Follow the active plan:

- `plans/2026-06-12_signal_native_runtime/plan.md`
- `plans/2026-06-12_signal_native_runtime/tasks.md`

The target model:

```text
signal write
-> affected memo/effect invalidation
-> affected host binding/control-flow/canvas update
-> dirty root classification
-> one layout pass if needed
-> one command compilation if needed
-> Soluna batch draw
```

Do not implement Vue-style proxy tables or component rerender as the main reactive path.

## Component Shape

Component chunks still return a build function, but the build function should be treated as mount-time graph construction, not a render effect.

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

Signal reads in component build scope should not silently subscribe the component. Dynamic values belong in `miru.memo`, `miru.effect`, host prop bindings, canvas draw scopes, or explicit control-flow primitives.

## Reactive Primitives

Prefer these names for new runtime design:

- `miru.signal(initial)`
- `miru.memo(fn)`
- `miru.effect(fn)`
- `miru.batch(fn)`
- `miru.untrack(fn)`
- `miru.get(value)`

`memo` should be lazy and cached. `effect` should belong to an owner scope and clean up dependencies on rerun or disposal.

## Retained Tree

Use one retained tree and one Yoga tree per mounted root.

- Component wrappers, host nodes, text nodes, canvas nodes, and control-flow anchors participate in the same tree.
- Component build creates nodes once.
- `when`, `switch`, and keyed `each` own dynamic structure.
- Destroying a component or range must dispose owned effects, refs, interaction state, canvas commands, animations, and Yoga nodes.

## Host Binding

Host node props store raw and resolved values separately.

- Layout props mark layout dirty.
- Draw-only props mark paint/command dirty.
- Canvas dependency changes mark only the canvas dirty.
- Multiple writes in one batch should produce one root flush.

Callbacks are ordinary functions and must not be confused with reactive getters.

## Interaction

Interaction state should be signal-backed:

- `miru.hovered()`
- `miru.pressed()`
- `miru.ref()`
- `miru.clickable(props)`
- `miru.dismissable(props)`

Hit testing should use calculated retained-tree geometry. Pointer events should report owner-local coordinates.

## Verification

When changing `miru.lua`, add or update focused tests for the changed primitive first.

Prioritize verification in this order:

1. Reactive kernel tests: signal, memo, effect cleanup, batch, untrack.
2. Retained tree tests: insertion, removal, keyed reorder, destroy cleanup.
3. Layout tests: Yoga dirty classification, intrinsic size, parent-size propagation.
4. Binding tests: text, layout prop, paint prop, canvas dependency isolation.
5. Interaction tests: hover, pressed, click, dismissable, ref coordinates.
6. Animation tests: tween signal, transition lifecycle, cleanup.

If the repository does not yet have a runnable test harness for a changed area, add the smallest harness needed before claiming the behavior is verified.
