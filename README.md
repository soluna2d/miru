# miru

Miru is a lightweight reactive UI runtime for Soluna 2D.

## Build

The repository keeps Soluna as a git submodule and uses the LuaMake binary pinned by Soluna. The following commands build a macOS arm64 release:

```sh
git submodule update --init --recursive

cd soluna
./bin/luamake-bin/bin/osx_arm64/luamake soluna
cd ..

./soluna/bin/luamake-bin/bin/osx_arm64/luamake
```

Add `-mode debug` to both LuaMake commands for a debug build.

## Tests And Gallery

All tests and examples use the unified `test.dl` entry. Run the complete smoke suite with:

```sh
./soluna/bin/macos/release/soluna test.dl
```

Run one focused smoke test with:

```sh
TEST_KIND=smoke TEST_NAME=interaction ./soluna/bin/macos/release/soluna test.dl
```

Start the interactive component gallery with:

```sh
TEST_KIND=feature TEST_NAME=gallery ./soluna/bin/macos/release/soluna test.dl
```

Run the automated gallery interaction regression with:

```sh
TEST_KIND=feature TEST_NAME=gallery TEST_FRAMES=11 ./soluna/bin/macos/release/soluna test.dl
```
