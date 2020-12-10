-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

vl5.proc  

caveats:
** this is implemented for and tested only on x86_64. **
** this doesn't support multi-threaded programs. **


]]

local vl5 = require "vl5"
local nr = require "vl5.nr"

local gets, puts = vl5.getstr, vl5.putstr
local geti, puti = vl5.getuint, vl5.putuint
local syscall, errno = vl5.syscall, vl5.errno

-- default memory buffer for syscalls
local b, blen = vl5.buf, vl5.bufsize


local proc = {} -- the vl5.proc module

function proc.getpid()
	return vl5.syscall(nr.getpid)
end

function proc.getppid()
	return vl5.syscall(nr.getppid)
end

function proc.getcwd()
	local r, eno = syscall(nr.getcwd, b, blen)
	if r then return gets(b) else return nil, eno end
end

function proc.chdir(path)
	puts(b, path, 0)
	return syscall(nr.chdir, b)
end

function proc.msleep(ms)
	-- suspend the execution for ms milliseconds
	--
	-- built with nanosleep(2)
	-- argument is a stuct timespec {tv_sec:long, tv_nsec:long}
	-- Note: the nanosleep optional argument (remaining time in case 
	-- of interruption) is not used/returned. 
	puti(b, ms // 1000, 8) -- seconds
	puti(b+8, (ms % 1000) * 1000000, 8) -- nanoseconds
	return syscall(nr.nanosleep, b)
end

function proc.kill(pid, sig)
	-- see kill(2)
	return syscall(nr.kill, pid, sig)
end

function proc.fork()
	-- !! doesn't support multithreading !!
	return syscall(nr.fork)
end

function proc.waitpid(pid, opt)
	-- wait for state changes in a child process (see waitpid(2))
	-- return pid, status
	-- pid, opt and status are integers
	-- (for status consts and macros, see sys/wait.h)
	--	exitstatus: (status & 0xff00) >> 8
	--	termsig: status & 0x7f
	--	coredump: status & 0x80
	-- pid and opt are optional:
	-- pid default value is -1 (wait for any child - same as wait())
	-- pid=0: wait for any child in same process group
	-- pid=123: wait for child with pid 123
	-- opt=1 (WNOHANG) => return immediately if no child has exited.
	-- default is opt=0
	--
	-- !! doesn't support multithreading !!
	--
	pid = pid or -1
	opt = opt or 0
	local pid, status, eno
	pid, eno = syscall(nr.wait4, pid, b, opt)
	if pid then
		status = geti(b, 4)
		return pid, status
	else
		return nil, eno
	end
end

------------------------------------------------------------------------
-- execve


-- utilities to convert between a Lua list of string and a list of
-- C strings as used for example by `argv` and `environ` ("csl")

--[[ a C string list is stored in a buffer as follows:

starting at address b:
	addr of string1 (a char *)
	addr of string2
	...
	addr of stringN
	0  (a null ptr)
	string1 \0 (a null byte must be  appended at end of string)
	string2 \0
	... 
	stringN \0
	
]]

function proc.make_csl(a, alen, t)
	-- create a C string list (csl) in memory at address a.
	-- the csl must fit between a and a+alen. if not, the 
	-- function returns nil, errmsg
	-- strings are taken for the list part of Lua table t.
	-- return a on success or nil, errmsg
	--
	local psz = 8 -- size of a pointer
	local len = (#t + 1) * psz  -- space used for the string pointers
	-- store the strings and check the total length of the future csl
	local pa = a -- address of the pointer to the first string
	for i, s in ipairs(t) do
		assert(type(s) == "string")
		sa = a + len -- -- address of the first string chars
		len = len + #s + 1  -- add 1 for the '\0' terminator
		if len > alen then return nil, "not enough space" end
		puts(sa, s, true) -- write s, add a '\0'
		puti(pa, sa, psz)
		pa = pa + psz
	end
	return a
end

function proc.parse_csl(a)
	-- parse a C string list (csl) at address a
	-- return a Lua table containing the list of strings
	--
	local psz = 8 -- size of a pointer
	local t = {}  -- the Lua table to be filled by strings
	while true do
		local sa = geti(a, psz)
		if sa == 0 then break end
		local s = gets(sa)
		table.insert(t, s)
		a = a + psz
	end
	return t
end
	
	

function proc.execve(exepath, argv_csl, env_csl)
	-- Return nil, eno (the errno value set by the system call)
	-- This function does not return on success.
	
	
end

------------------------------------------------------------------------
return proc

