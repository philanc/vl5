-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

vl5.proc  

this is implemented and tested only on x86_64


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
	-- argument is a stuct timespec {tv_sec, tv_nsec: long}
	puti(b, ms // 1000, 8) -- seconds
	puti(b+8, (ms % 1000) * 1000000, 8) -- nanoseconds
	return syscall(nr.nanosleep, b)
end

return proc

