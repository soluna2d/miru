local lm = require "luamake"
local platform = require "bee.platform"

local function detect_emcc()
	if lm.compiler == "emcc" then
		return true
	end
	if type(lm.cc) == "string" and lm.cc:find("emcc", 1, true) then
		return true
	end
	return false
end

local osplat = (function()
	if lm.os == "windows" then
		if lm.compiler == "gcc" then
			return "mingw"
		end
		if lm.cc == "clang-cl" then
			return "clang-cl"
		end
		return "msvc"
	end
	return lm.os
end)()

local plat = (function()
	if detect_emcc() then
		return "emcc"
	end
	return osplat
end)()

lm.platform = plat
lm.basedir = lm:path "."
lm.bindir = "."
lm.osbindir = "."

lm:conf {
	c = "c11",
	flags = {
		lm.mode ~= "debug" and "-O2",
	},
	gcc = {
		flags = {
			"-Wall",
			"-fPIC",
		},
	},
	clang = {
		flags = {
			"-Wall",
			"-fPIC",
		},
	},
	msvc = {
		flags = {
			"-W3",
			"-utf-8",
			"/wd4244",
			"/wd4267",
			"/wd4996",
		},
	},
}

local function shdc_plat()
	if lm.os == "windows" then
		return "win32"
	end
	if lm.os == "linux" then
		return platform.Arch == "arm64" and "linux_arm64" or "linux"
	end
	if lm.os == "macos" then
		return platform.Arch == "arm64" and "osx_arm64" or "osx"
	end
	return "unknown"
end

local shdc_paths = {
	windows = "$PATH/$NAME.exe",
	macos = "$PATH/$NAME",
	linux = "$PATH/$NAME",
}

---@diagnostic disable-next-line: unnecessary-assert
local shdc = assert(shdc_paths[lm.os]):gsub("%$(%u+)", {
	PATH = tostring(lm.basedir / "soluna/bin/sokol-tools-bin/bin" / shdc_plat()),
	NAME = "sokol-shdc",
})

local function shader_lang()
	if plat == "msvc" or plat == "clang-cl" or plat == "mingw" then
		return "hlsl4"
	end
	if plat == "macos" then
		return "metal_macos"
	end
	if plat == "emcc" then
		return "wgsl"
	end
	if plat == "linux" then
		return "glsl430"
	end
	return "unknown"
end

local function compile_shader(src, name)
	local dep = name .. "_shader"
	local target = "build/" .. name
	lm:runlua(dep) {
		script = "soluna/clibs/soluna/shader2c.lua",
		inputs = src,
		outputs = {
			target,
		},
		args = {
			shdc,
			"$in",
			"$out",
			shader_lang(),
		},
	}
	return dep
end

local rounded_shader = compile_shader("test/src/rounded_rect.glsl", "rounded_rect.glsl.h")

lm:dll "miru_test" {
	sources = {
		"soluna/extlua/extlua.c",
		"soluna/extlua/materialapi.c",
		"test/src/miru_test.c",
		"test/src/material_rounded_rect.c",
	},
	objdeps = {
		rounded_shader,
	},
	includes = {
		"soluna/3rd/lua",
		"soluna/3rd",
		"soluna/extlua",
		"build",
	},
}

lm:default "miru_test"
