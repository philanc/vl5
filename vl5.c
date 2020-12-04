// Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/*   

VL5  - Very Low-Level Linux Lua Library (syscall interface)

This is for Lua 5.3+ only, built with default 64-bit integers

*/

#include "lua.h"
#include "lauxlib.h"

#include <unistd.h>
#include <sys/syscall.h>   /* For SYS_xxx definitions */

#define VL5_VERSION "vl5-0.0"

static int ll_syscall(lua_State *L) {
	long number = luaL_checkinteger(L, 1);
	long p2 = luaL_optinteger(L, 2, 0);
	long p3 = luaL_optinteger(L, 3, 0);
	long p4 = luaL_optinteger(L, 4, 0);
	long p5 = luaL_optinteger(L, 5, 0);
	long p6 = luaL_optinteger(L, 6, 0);
	long r = syscall(number, p2, p3, p4, p5, p6);
	lua_pushinteger(L, r);
	return 1;
}

//----------------------------------------------------------------------
// lua library declaration
//

// l5 function table
static const struct luaL_Reg vl5lib[] = {
	//
	{"syscall", ll_syscall},
	//
	{NULL, NULL},
};

int luaopen_vl5 (lua_State *L) {
	
	// register main library functions
	//~ luaL_register (L, "l5", l5lib);
	luaL_newlib (L, vl5lib);
	lua_pushliteral (L, "VERSION");
	lua_pushliteral (L, VL5_VERSION); 
	lua_settable (L, -3);
	return 1;
}
