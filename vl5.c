// Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/*   

VL5  - Very Low-Level Linux Lua Library (syscall interface)

This is for Lua 5.3+ only, built with default 64-bit integers

*/

#include "lua.h"
#include "lauxlib.h"

#include <string.h>
#include <unistd.h>
#include <errno.h>	// errno

//~ #include <sys/syscall.h>   /* For SYS_xxx definitions */


#define LERR(msg) return luaL_error(L, msg)
#define RET_TRUE return (lua_pushboolean(L, 1), 1)
#define RET_INT(i) return (lua_pushinteger(L, (i)), 1)


#define VL5_VERSION "vl5-0.0"

static int ll_syscall(lua_State *L) {
	long number = luaL_checkinteger(L, 1);
	long p1 = luaL_optinteger(L, 2, 0);
	long p2 = luaL_optinteger(L, 3, 0);
	long p3 = luaL_optinteger(L, 4, 0);
	long p4 = luaL_optinteger(L, 5, 0);
	long p5 = luaL_optinteger(L, 6, 0);
	long p6 = luaL_optinteger(L, 7, 0);
	long r = syscall(number, p1, p2, p3, p4, p5, p6);
	lua_pushinteger(L, r);
	return 1;
}

//----------------------------------------------------------------------
// memory / buffer API
// ...one more step towards the perfect footgun... :-)

static int ll_newbuffer(lua_State *L) {
	// lua API: newbuffer(size) => ptr as an int
	size_t size = luaL_checkinteger(L, 1);
	char *mb = lua_newuserdata(L, size);
	if (mb == NULL) LERR("buffer: allocation failed");
	memset(mb, 0, size); // ?? is it needed or already done by lua?
	lua_pushinteger(L, (lua_Integer) mb);
	return 1;
}

static int ll_getstr(lua_State *L) {
	// lua API: getstr(ptr:int [, size) => string
	// if size=-1 (default), string is null-terminated
	char *p = (char *) luaL_checkinteger(L, 1);
	long size = luaL_optinteger(L, 2, -1);
	if (size < 0) {
		lua_pushstring (L, p);
	} else {
		lua_pushlstring (L, p, size);
	}
	return 1;
}

static int ll_putstr(lua_State *L) {
	// lua API: putstr(ptr:int, str)
	// NO \0 is added at the end of the written string
	size_t len;
	char *ptr = (char *) luaL_checkinteger(L, 1);
	const char *str = luaL_checklstring(L, 2, &len);
	memcpy(ptr, str, len);
	RET_TRUE;
}

static int ll_putstrz(lua_State *L) {
	// lua API: putstrz(ptr:int, str)
	// a \0 is appended at the end of the copied string
	size_t len;
	char *ptr = (char *) luaL_checkinteger(L, 1);
	const char *str = luaL_checklstring(L, 2, &len);
	memcpy(ptr, str, len);
	ptr[len] = '\0';
	RET_TRUE;
}

static int ll_getlong(lua_State *L) {
	// lua API: getlong(ptr:int) => int
	char *p = (char *) luaL_checkinteger(L, 1);
	long i = *((long *) p);
	lua_pushinteger(L, i);
	return 1;
}

static int ll_putlong(lua_State *L) {
	// lua API: putlong(ptr:int, i)
	char *p = (char *) luaL_checkinteger(L, 1);
	long i = luaL_checkinteger(L, 2);
	*((long *) p) = i;
	RET_TRUE;
}

static int ll_putint(lua_State *L) {
	// lua API: putlong(ptr:int, i, isize)
	// isize is i size in bytes. can be 1, 2, 4 or 8
	char *p = (char *) luaL_checkinteger(L, 1);
	long i = luaL_checkinteger(L, 2);
	int sz = luaL_optinteger(L, 3, 8);
	switch (sz) {
		case 1: *((uint8_t *) p) = i & 0xff; break;
		case 2: *((uint16_t *) p) = i & 0xffff; break;
		case 4: *((uint32_t *) p) = i & 0xffffffff; break;
		case 8: *((uint64_t *) p) = i; break;
		default: LERR("vl5.putint: invalid parameter"); break;
	}
	RET_TRUE;
}


static int ll_errno(lua_State *L) {
	// lua api: errno() => errno value; 
	//          errno(n): set errno to n (main use: errno(0))
	int r = luaL_optinteger(L, 1, -1);
	if (r != -1) errno = r; 
	RET_INT(errno);
}



//----------------------------------------------------------------------
// lua library declaration
//

// l5 function table
static const struct luaL_Reg vl5lib[] = {
	//
	{"syscall", ll_syscall},
	{"newbuffer", ll_newbuffer},
	{"getstr", ll_getstr},
	{"putstr", ll_putstr},
	{"putstrz", ll_putstrz},
	{"getlong", ll_getlong},
	{"putlong", ll_putlong},
	{"putint", ll_putint},
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
