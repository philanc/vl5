# VL5

VL5, a **Very Low-Level Linux Library for Lua** is a minimal binding to the Linux syscall interface.

The library targets **Lua 5.3+** with the default 64-bit integers. 

### Caveat

- This is work in progress. No guarantee that it works or do anything remotely useful.

- This is *really low-level*. It is *not* intended to be used as-is in applications. It is intended to be the *minimal* C core required to implement Lua access to Linux system calls.  In other words, this is the *perfect footgun*.


- No doc at the moment.


### What's the point?

- this is fun,

- this is a great learning experience,

- this is the first step to build a minimal Linux userspace (almost) entirely in Lua.


### Available functions

```
syscall(syscall_no [, p2, p3, p4, p5, p6]) => r | nil, errno

	All arguments are integers (64-bit Lua integers)
	
	The return value is also an integer. As a convenience, when
	the system call fails and return -1, the Lua function syscall()
	returns (nil, eno) where eno is the errno value set by the system call	
	
	Example:

	vl5 = require "vl5"
	nr = require "vl5.nr"  -- syscall numbers (the __NR_xxx constants)
		
	-- get the current user uid:  system call 102 (__NR_getuid)
	uid = vl5.syscall(nr.getuid)  -- here, uid = 1000

```

**Access to memory**

Additional functions are provided to handle strings, struct and arrays 
in memory. All these functions are obviously **very unsafe**.

A memory buffer can be allocated and deallocated with functions `newbuffer` and `freebuffer`. Memory addresses (pointers) are represented as Lua integers. Functions are provided to read / write integers and strings from / to a memory address.

```
newbuffer(size) => addr
	allocate a buffer of `size` bytes
	return the address of the new buffer as an integer

freebuffer(addr)
	free a buffer allocated at this address

getstr(addr [, size]) => str
	return `size` bytes at address `addr` as a Lua string
	if size is not provided, the null-terminated string at
	address `addr` is returned.

putstr(addr, str [, zflag])
	write string `str` at address `addr`.
	if `zflag` is true, a zero byte ('\0') is appended in memory
	after the string

getuint(addr, isize) => i
	read an unsigned integer in memory at address `addr`. `isize` is the
	size of the integer in memory (in bytes). It must be 1, 2, 4 or 8.

putuint(addr, i, isize)
	writes an integer in memory at address `addr`. `isize` is the 
	size of the integer in bytes. It must be 1, 2, 4 or 8.
	the integer is truncated if needed. For example,
	   putuint(addr, i, 2) 
	is equivalent to
	   putstr(addr, string.format("I2", i & 0xffff))

errno([n]) => eno

	Return the value of the global `errno` variable.
	If `n` is provided, the global variable `errno` is set to `n`.

environ() => addr

	Return the address of the current environment (ie. the value of 
	the C global variable `environ`) as an integer


```

An example:

```
	vl5 = require "vl5"
	nr = require "vl5.nr"
	
	-- change the current directory to /var/log
	
	-- allocate a 128 bytes buffer
	-- buf is the memory address of the buffer (as a Lua integer)
	
	buf = vl5.newbuffer(128)  
	
	-- write the path to the buffer (as a null-terminated string)
	
	vl5.putstr(buf, "/var/log", true) 
	
	-- invoke the system call
	
	r, eno = vl5.syscall(nr.chdir, buf)
	
	-- if the system call fails (eg. if the path is invalid)
	-- `r` is nil and `eno` is the errno value set by the system call.
	
	-- if the buffer is not used anymore for other syscalls, 
	-- it may be deallocated.

	vl5.freebuffer(buf)
	
```
	








### License

MIT.



