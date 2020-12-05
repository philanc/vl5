// Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/*   

VL5  - Very Low-Level Linux Lua Library (syscall interface)

This is for Lua 5.3+ only, built with default 64-bit integers

CAVEAT
At the moment, this is tested and should work only for x86_64

Among other things, it assumes that:
sizeof(char *) == sizeof(long) == sizeof(lua_Integer) == 8

*/

#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>
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
// memory / buffer minimal API
// ...one big step towards the perfect footgun... :-)

// FIXME: how to use a userdata automatically GC'd by Lua for buffer?

static int ll_newbuffer(lua_State *L) {
	// lua API: newbuffer(size) => addr
	// return the address of a block of allocated memory
	size_t size = luaL_checkinteger(L, 1);
	char *mb = (char *) malloc(size);
	if (mb == NULL) LERR("buffer: allocation failed");
	memset(mb, 0, size); // ?? is it needed or already done by lua?
	lua_pushinteger(L, (lua_Integer) mb);
	return 1;
}

static int ll_freebuffer(lua_State *L) {
	// lua API: freebuffer(addr)
	// free a buffer allocated with newbuffer()
	char *p = (char *) luaL_checkinteger(L, 1);
	free(p);
	RET_TRUE;
}

static int ll_getstr(lua_State *L) {
	// lua API: getstr(addr [, size]) => string
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
	// lua API: putstr(addr, str [, nt])
	// nt is optional. if true, a null terminator ('\0')
	// is appended at the end of the written string. Default is false.
	size_t len;
	char *ptr = (char *) luaL_checkinteger(L, 1);
	const char *str = luaL_checklstring(L, 2, &len);
	memcpy(ptr, str, len);
	if (lua_toboolean(L, 3)) ptr[len] = '\0';
	RET_TRUE;
}

static int ll_getuint(lua_State *L) {
	// lua API: getuint(addr, isize) => i
	// get unsigned integer i at address addr
	// isize is i size in bytes. can be 1, 2, 4 or 8
	// default is 4 
	char *p = (char *) luaL_checkinteger(L, 1);
	int sz = luaL_optinteger(L, 2, 4);
	long i;
	switch (sz) {
		case 1: i = *((uint8_t *) p); break;
		case 2: i = *((uint16_t *) p); break;
		case 4: i = *((uint32_t *) p); break;
		case 8: i = *((uint64_t *) p); break;
		default: LERR("vl5.getint: invalid parameter"); break;
	}
	RET_INT(i);
}

static int ll_putuint(lua_State *L) {
	// lua API: putuint(addr, i, isize)
	// put integer i at address addr.
	// isize is i size in bytes. can be 1, 2, 4 or 8
	// default is 4 
	char *p = (char *) luaL_checkinteger(L, 1);
	long i = luaL_checkinteger(L, 2);
	int sz = luaL_optinteger(L, 3, 4);
	switch (sz) {
		case 1: *((uint8_t *) p) = i & 0xff; break;
		case 2: *((uint16_t *) p) = i & 0xffff; break;
		case 4: *((uint32_t *) p) = i & 0xffffffff; break;
		case 8: *((uint64_t *) p) = i; break;
		default: LERR("vl5.putint: invalid parameter"); break;
	}
	RET_TRUE;
}

// access to the errno global variable

static int ll_errno(lua_State *L) {
	// lua api: errno() => errno value
	//          errno(n): set errno to n
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
	{"freebuffer", ll_freebuffer},
	{"getstr", ll_getstr},
	{"putstr", ll_putstr},
	{"getuint", ll_getuint},
	{"putuint", ll_putuint},
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
