# Miru

Miru is a lightweight reactive UI framework for [Soluna 2D](https://github.com/cloudwu/soluna). It keeps component state, dependency tracking, interaction routing, Yoga layout, animation, and Soluna material streams in one Lua runtime file.

The documentation site includes a live WebAssembly workbench built from the same Lua example used by the native application.

## Capabilities

- Callable reactive values and computed dependencies
- Stateful Lua component modules
- Yoga-backed box, horizontal, vertical, absolute, flex, and overflow layout
- Measured styled text and custom Soluna canvas streams
- Click, hover, press, focus, keyboard, clipboard, wheel, and outside-dismiss interaction
- Duration/easing animation and color interpolation
- Context providers, refs, exposed component methods, and slots

## Run The Native Example

Initialize the Soluna submodule and build Soluna for macOS arm64:

```sh
git submodule update --init --recursive
cd soluna
./bin/luamake-bin/bin/osx_arm64/luamake -mode release soluna
cd ..
./soluna/bin/macos/release/soluna example/main.game
```

Use the corresponding LuaMake and Soluna paths for Linux or Windows.

## Build The Documentation Site

Build Soluna's Emscripten runtime first, then package the static site:

```sh
cd soluna
./bin/luamake-bin/bin/osx_arm64/luamake -mode release -compiler emcc
cd ..
node example/scripts/build-site.mjs
```

The output is written to `dist/`. Serve it over HTTP; the included COI service worker establishes the cross-origin isolation required by the Soluna WebAssembly runtime.

```sh
pnpm dev
```

The local server listens on <http://127.0.0.1:4173> and sets COOP/COEP headers so the WebAssembly runtime can start without a service-worker reload.

GitHub Actions builds the same artifact and deploys it with GitHub Pages on pushes to `main`.

## Repository Layout

```text
miru.lua                 Framework runtime
example/main.game        Native application settings
example/main.lua         Soluna application bridge
example/gallery.lua      Interactive component workbench
example/components/      Reusable component examples
example/site/            Documentation shell
example/scripts/         WebAssembly site packaging
soluna/                  Soluna git submodule
```

The example components are intentionally application-owned. Miru provides primitives and lifecycle semantics rather than a fixed visual design system.
