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
return proc

