---
name: miru
description: Use when modifying the Miru Lua UI runtime, components, examples, tests, native material glue, or Soluna integration in this repository.
---

# Miru

Miru is a reactive UI runtime for Soluna 2D. The current implementation uses component chunks, component-owned reactive state, a unified Yoga tree, and a compiled batch command tree. It does not implement a virtual DOM or use proxy tables as a general state model.

## Design Checklist

Before editing runtime behavior, components, examples, or tests, identify:

- **Owner**: root, feature component, visual component, interaction helper, or host callback.
- **Role**: reusable product component, demo-specific component, visual primitive, interaction helper, or runtime fixture.
- **Built-ins**: prefer `miru.value`, `miru.computed`, `miru.animated`, `miru.hovered`, `miru.pressed`, `miru.focused`, `miru.ref`, `miru.clickable`, `miru.focusable`, `miru.scrollable`, and `miru.dismissable`.
- **Event flow**: children report interaction intent through callback props; the parent that owns state performs the mutation.
- **Geometry**: create `miru.ref()` inside the geometry owner. Use `ref:rect()` inside components and `ref:window_rect()` only for host bridges that need window coordinates.
- **Drawing**: keep tightly aligned backgrounds, text, icons, and selection visuals in one owner-controlled coordinate system.

## Component Model

A component chunk receives props and returns a render function:

```lua
local miru = require "miru"

local args = ...
local count = miru.value(0)

return function()
	miru.clickable {
		on_click = function()
			count(count() + 1)
		end,
	}
	miru.text("Count: " .. tostring(count()), {
		width = args.width,
	})
end
```

Reactive values read by the render function invalidate and rerender the owning component. Ordinary props are snapshots from the parent's current render. Consecutive events in one frame must not accumulate state through a stale prop snapshot; report intent to the actual state owner instead.

## Text

Register text styles before mounting any component that contains `miru.text`:

```lua
view:text_styles {
	font = font.cobj(),
	default_font = fontid,
	default = "body",
	body = {
		size = 15,
		line_height = 20,
		color = 0xff111827,
	},
}
```

Miru uses `soluna.material.text` directly. Do not restore the old `miru.new { text_engine = ... }` contract. Text nodes support named styles, node-local font/size/color/line-height overrides, vertical alignment, wrapping, scroll offsets, and overflow clipping.

## Interaction And Geometry

- Route host mouse input through `view:pointer`, `view:mouse_button`, and `view:mouse_scroll`.
- Route host text input through `view:char`, `view:key`, and `view:clipboard_pasted`; the focused component consumes it.
- Use `miru.dismissable` for dropdowns, popovers, and menus instead of implementing a global outside-click registry.
- `overflow = "hidden"` and `overflow = "scroll"` constrain both drawing and hit testing.
- Pointer event `x/y` values are local to the current component; `client_x/client_y` values are window coordinates.

## Canvas And Native Materials

A `miru.canvas` draw callback records commands. Use the `miru.batch:add`, `miru.batch:layer`, and related proxies there; the commands execute against the real batch during `view:draw(batch)`.

Native materials use the current Soluna `materialapi` contract:

- The C extension initializes `luaapi_init` and `materialapi_init`.
- The C module creates streams with `material_push` and exports `hooks` plus `instance_size`.
- The Lua material binds the instance buffer, storage view, SR buffer, and hooks through `soluna.material.ext.new`.

Do not restore the removed `sokolapi`, `solunaapi`, or legacy stream submission APIs.

## Verification

Run focused tests before the complete smoke suite and automated gallery regression:

```sh
./soluna/bin/luamake-bin/bin/osx_arm64/luamake -mode debug
TEST_KIND=smoke TEST_NAME=interaction ./soluna/bin/macos/debug/soluna test.dl
./soluna/bin/macos/debug/soluna test.dl
TEST_KIND=feature TEST_NAME=gallery TEST_FRAMES=11 ./soluna/bin/macos/debug/soluna test.dl
```

After Lua API or annotation changes, run clean headless Neovim diagnostics with `emmylua_ls` on the touched files. Format only touched files, then review the complete diff and run `git diff --check`.
