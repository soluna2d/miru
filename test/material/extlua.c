#include <lua.h>
#include <lauxlib.h>

LUA_API void luaapi_init(lua_State *L);
void sokolapi_init(lua_State *L);
void solunaapi_init(lua_State *L);
int luaopen_test_material_rounded_rect(lua_State *L);

#if defined(_WIN32)
#define MIRU_TEST_EXPORT __declspec(dllexport)
#else
#define MIRU_TEST_EXPORT __attribute__((visibility("default")))
#endif

MIRU_TEST_EXPORT int
miru_test_init(lua_State *L) {
	luaapi_init(L);
	sokolapi_init(L);
	solunaapi_init(L);
	luaL_Reg libs[] = {
		{ "test.material.rounded_rect_native", luaopen_test_material_rounded_rect },
		{ NULL, NULL },
	};
	luaL_newlib(L, libs);
	return 1;
}
