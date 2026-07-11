#include <lua.h>
#include <lauxlib.h>
#include <math.h>
#include <stdint.h>

#include "materialapi.h"
#include "rounded_rect.glsl.h"

struct color {
	unsigned char channel[4];
};

struct rounded_payload {
	uint16_t width;
	uint16_t height;
	uint16_t radius;
	uint16_t unused0;
	uint32_t color;
};

typedef char rounded_payload_size_check[sizeof(struct rounded_payload) == MATERIAL_DATA_SIZE ? 1 : -1];

struct rounded_inst {
	float position[3];
	float shape[4];
	struct color color;
};

static int material_id = 0;

static lua_Number
check_number_field(lua_State *L, const char *name) {
	lua_Number value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		luaL_error(L, "Missing rounded rect field: %s", name);
		return 0.0;
	}
	value = luaL_checknumber(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Number
opt_number_field(lua_State *L, const char *name, lua_Number fallback) {
	lua_Number value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		lua_pop(L, 1);
		return fallback;
	}
	value = luaL_checknumber(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Integer
check_integer_field(lua_State *L, const char *name) {
	lua_Integer value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		luaL_error(L, "Missing rounded rect field: %s", name);
		return 0;
	}
	value = luaL_checkinteger(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Integer
opt_integer_field(lua_State *L, const char *name, lua_Integer fallback) {
	lua_Integer value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		lua_pop(L, 1);
		return fallback;
	}
	value = luaL_checkinteger(L, -1);
	lua_pop(L, 1);
	return value;
}

static struct color
color_from_u32(uint32_t color) {
	struct color c;
	if (!(color & 0xff000000u)) {
		color |= 0xff000000u;
	}
	c.channel[0] = (unsigned char)((color >> 16) & 0xff);
	c.channel[1] = (unsigned char)((color >> 8) & 0xff);
	c.channel[2] = (unsigned char)(color & 0xff);
	c.channel[3] = (unsigned char)((color >> 24) & 0xff);
	return c;
}

static uint16_t
payload_size(float value) {
	if (value <= 0.0f) {
		return 0;
	}
	if (value >= 65535.0f) {
		return 65535;
	}
	return (uint16_t)(value + 0.5f);
}

static material_error
submit_rounded_rect(const struct material_item *item, void *out) {
	const struct rounded_payload *payload = (const struct rounded_payload *)item->data;
	struct rounded_inst *inst = (struct rounded_inst *)out;
	inst->position[0] = item->x;
	inst->position[1] = item->y;
	inst->position[2] = (float)item->transform_index;
	inst->shape[0] = (float)payload->width;
	inst->shape[1] = (float)payload->height;
	inst->shape[2] = (float)payload->radius;
	inst->shape[3] = 0.0f;
	inst->color = color_from_u32(payload->color);
	return NULL;
}

static void
pipeline_rounded_rect(sg_pipeline_desc *desc) {
	desc->layout.attrs[ATTR_rounded_rect_position].format = SG_VERTEXFORMAT_FLOAT3;
	desc->layout.attrs[ATTR_rounded_rect_shape].format = SG_VERTEXFORMAT_FLOAT4;
	desc->layout.attrs[ATTR_rounded_rect_color].format = SG_VERTEXFORMAT_UBYTE4N;
}

static const struct material_hook rounded_rect_hooks[] = {
	{ "shader", { .shader = rounded_rect_shader_desc } },
	{ "pipeline", { .pipeline = pipeline_rounded_rect } },
	{ "submit", { .submit = submit_rounded_rect } },
	{ NULL, { NULL } },
};

static int
lset_material_id(lua_State *L) {
	int id = luaL_checkinteger(L, 1);
	if (id <= 0) {
		return luaL_error(L, "Invalid rounded rect material id %d", id);
	}
	material_id = id;
	return 0;
}

static void
push_rect_item(lua_State *L, luaL_Buffer *buffer, float x, float y, float width, float height, float radius, uint32_t color) {
	struct rounded_payload payload = {
		.width = payload_size(width),
		.height = payload_size(height),
		.radius = payload_size(radius),
		.color = color,
	};
	struct material_push_item item = {
		.x = x,
		.y = y,
		.sprite = -1,
		.data = &payload,
	};
	material_push(L, material_id, &item);
	luaL_addvalue(buffer);
}

static int
lrounded_rect(lua_State *L) {
	luaL_Buffer buffer;
	float width;
	float height;
	float radius;
	float border_width;
	uint32_t fill_value;
	uint32_t border_value;
	if (material_id <= 0) {
		return luaL_error(L, "Rounded rect material is not registered");
	}
	luaL_checktype(L, 1, LUA_TTABLE);
	width = (float)check_number_field(L, "width");
	height = (float)check_number_field(L, "height");
	radius = (float)opt_number_field(L, "radius", 0.0);
	fill_value = (uint32_t)check_integer_field(L, "fill");
	border_value = (uint32_t)opt_integer_field(L, "border", fill_value);
	border_width = (float)opt_number_field(L, "border_width", 0.0);
	if (!isfinite(width) || !isfinite(height) || !isfinite(radius) || !isfinite(border_width)) {
		return luaL_error(L, "Rounded rect fields must be finite");
	}
	if (width <= 0.0f || height <= 0.0f) {
		return luaL_error(L, "Invalid rounded rect size");
	}
	if (radius < 0.0f || border_width < 0.0f) {
		return luaL_error(L, "Invalid rounded rect shape");
	}
	luaL_buffinit(L, &buffer);
	if (border_width > 0.0f && border_value != fill_value) {
		float fill_width = width - border_width * 2.0f;
		float fill_height = height - border_width * 2.0f;
		push_rect_item(L, &buffer, 0.0f, 0.0f, width, height, radius, border_value);
		if (fill_width > 0.0f && fill_height > 0.0f) {
			float fill_radius = radius > border_width ? radius - border_width : 0.0f;
			push_rect_item(L, &buffer, border_width, border_width, fill_width, fill_height, fill_radius, fill_value);
		}
	} else {
		push_rect_item(L, &buffer, 0.0f, 0.0f, width, height, radius, fill_value);
	}
	luaL_pushresult(&buffer);
	return 1;
}

int
luaopen_miru_test_material_rounded_rect(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "set_material_id", lset_material_id },
		{ "rect", lrounded_rect },
		{ "instance_size", NULL },
		{ "hooks", NULL },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	lua_pushinteger(L, sizeof(struct rounded_inst));
	lua_setfield(L, -2, "instance_size");
	material_push_hooks(L, rounded_rect_hooks);
	lua_setfield(L, -2, "hooks");
	return 1;
}
