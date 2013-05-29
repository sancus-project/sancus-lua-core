/* This file is part of sancus-lua-core <http://github.com/sancus-project/sancus-lua-core>
 *
 * Copyright (c) 2012, Alejandro Mery <amery@geeks.cl>
 */

#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

static const struct luaL_Reg core[] = {
	{ NULL, NULL}
};

int luaopen_sancus_core(lua_State *L)
{
	fputs("luaopen_sancus_core\n", stderr);
	luaL_register(L, "sancus.core", core);
	return 1;
}
