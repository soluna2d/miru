# Signal Native Runtime Tasks

## 0. Repository Baseline

- [x] Keep imported `miru.lua` history as the starting point.
- [ ] Add a minimal module README that states Miru is signal-native and has no old `core.view` compatibility guarantee.
- [x] Add a minimal test entry for running Miru runtime tests outside Soluna Playground.
- [ ] Decide whether examples live in `examples/` or `test/fixture/`.

## 1. Reactive Kernel

- [x] Replace the current eager render-scope tracker with an owner-based reactive graph.
- [x] Implement `signal(initial)`.
- [x] Implement lazy `memo(fn)` with dependency cleanup.
- [x] Implement `effect(fn)` with cleanup registration.
- [x] Implement `batch(fn)` with deterministic flush.
- [x] Implement `untrack(fn)`.
- [x] Implement `get(value)` for static-or-reactive values.
- [x] Add tests for chained memo invalidation.
- [x] Add tests for branch dependency cleanup.
- [x] Add tests for effect disposal.
- [x] Add tests for batched writes running effects once.

## 2. Runtime Ownership

- [x] Define owner scopes for root, component, host binding, control-flow range, canvas and animation.
- [x] Ensure every owner can register cleanup callbacks.
- [x] Stop all owned effects when a node/range/component is destroyed.
- [x] Add diagnostics for reading signals directly in component build scope.
- [x] Add tests for component-owned signals driving explicit binding and dirty owners.

## 3. Retained Tree

- [ ] Define retained node records for root, component wrapper, host node, text node, canvas node and range anchor.
- [ ] Keep a single Yoga tree per root.
- [ ] Remove per-component Yoga root calculation from the new runtime path.
- [ ] Add node insertion, removal and move helpers that update both retained tree and Yoga tree.
- [ ] Add tests for intrinsic child size affecting parent layout.
- [ ] Add tests for child `width = "100%"` / `height = "100%"` using parent layout.
- [ ] Add tests for destroy detaching Yoga nodes.

## 4. Host Prop Binding

- [ ] Split prop keys into structure, layout, paint, transform, interaction and internal categories.
- [x] Store raw props and resolved props separately.
- [x] Create binding effects for reactive prop values.
- [ ] Mark layout dirty only when resolved layout props change.
- [ ] Mark paint dirty only when resolved draw props change.
- [ ] Rebuild text command only when text or text rendering inputs change.
- [ ] Add tests for draw-only prop changes skipping Yoga.
- [ ] Add tests for layout prop changes running Yoga once.
- [ ] Add tests for many prop writes coalescing before draw.

## 5. Control Flow

- [ ] Implement `when(condition, children, fallback)`.
- [ ] Implement `switch(discriminator, cases, fallback)`.
- [ ] Implement keyed `each(list, key, children)`.
- [ ] Preserve child owner state during keyed reorder.
- [ ] Dispose removed keyed children immediately and deterministically.
- [ ] Add tests for insert, remove, reorder and update.
- [ ] Add tests for nested control-flow cleanup.

## 6. Text And Canvas

- [x] Make `text(source, props)` accept static source or reactive source.
- [ ] Add text command cache keyed by text rendering inputs.
- [ ] Run `canvas(draw)` in its own reactive binding scope.
- [ ] Rebuild a canvas command list when its signal dependencies change.
- [ ] Rebuild a canvas command list when its Yoga size changes.
- [ ] Keep `miru.batch` drawing API local to canvas draw execution.
- [ ] Add tests proving canvas dependency changes do not rebuild parent component.
- [ ] Add tests proving canvas size changes rebuild only the canvas command list plus root commands.

## 7. Scheduler And Dirty Flush

- [ ] Define dirty bits for structure, layout, paint, canvas and commands.
- [ ] Implement root-level flush ordering.
- [ ] Ensure `update(dt)` flushes signals, effects and animations without drawing.
- [ ] Ensure `draw(batch)` calls `ensure_layout()` and `ensure_commands()` exactly when needed.
- [ ] Add runtime statistics for component builds, binding runs, Yoga runs, canvas rebuilds and command compiles.
- [ ] Add tests for coalesced root command compilation.

## 8. Interaction

- [ ] Implement refs against retained tree geometry.
- [ ] Implement hit testing on the retained calculated tree.
- [ ] Implement `clickable`.
- [ ] Implement `dismissable`.
- [ ] Implement `hovered()` as a signal owned by the component.
- [ ] Implement `pressed()` as a signal owned by the component.
- [ ] Add tests for nested pointer local coordinates.
- [ ] Add tests for z-order hit preference.
- [ ] Add tests for dismissable owner-chain containment.

## 9. Animation And Transition

- [ ] Implement `tween(target, opts)` returning a signal.
- [ ] Drive active tweens from `update(dt)`.
- [ ] Implement transition lifecycle using retained control-flow ranges.
- [ ] Ensure transition exit keeps nodes mounted until leave completes.
- [ ] Add tests for target retargeting.
- [ ] Add tests for transition cleanup after destroy.

## 10. Verification Matrix

- [ ] Run all reactive kernel tests.
- [ ] Run all retained tree layout tests.
- [ ] Run interaction tests.
- [ ] Run animation and transition tests.
- [ ] Run a performance benchmark with many independent row signals.
- [ ] Verify one row signal update does not rebuild sibling rows.
- [ ] Verify frame/cursor signal updates do not rebuild owner component.
- [ ] Verify large batched updates produce one Yoga calculation and one command compile per dirty root.

## 11. Showcase Feature Test

- [x] Add `test/feature/test_showcase.lua`.
- [x] Keep showcase implementation files under `test/feature/showcase/`.
- [x] Add rounded rect test material under `test/material`.
- [ ] Build the showcase from real component shapes rather than synthetic demo-only widgets.
- [ ] Adapt component showcase/test_components style cases where they still represent Miru behavior.
- [ ] Adapt real-world component shapes such as button, switch, dropdown, text field and preference panels.
- [ ] Add an on-screen metrics panel for component builds, binding runs, Yoga runs, text rebuilds, canvas rebuilds and root command compiles.
- [ ] Add manual scenarios for hover/pressed/open, text input cursor/frame, single keyed row update, draw-only prop update, layout prop update and batched writes.
- [ ] Add focused assertions for the key metrics while keeping the feature test useful for visual inspection.
