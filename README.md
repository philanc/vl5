# VL5

VL5, a **Very Low-Level Linux Library for Lua** is a minimal binding to the Linux syscall interface.

The library targets **Lua 5.3+** with the default 64-bit integers. 

### Caveat

- This is work in progress. No guarantee that it works or do anything remotely useful.

- This is *really low-level*. It is *not* intended to be used as-is in applications. It is intended to be the *minimal* C core required to implement Lua access to Linux system calls.  In other words, this is the *perfect foot-gun*.


- No doc at the moment.


### What's the point?

- this is fun,

- this is a great learning experience,

- this is the first step to build a minimal Linux userspace (almost) entirely in Lua.


### Available functions

```
syscall(syscall_no [, p2, p3, p4, p5, p6]) => r


Example:

	require "vl5"
		
	-- get the current user uid:  system call 102 (__NR_getuid)
	uid = vl5.syscall(102)  -- here, uid = 1000
	
```



### License

MIT.



