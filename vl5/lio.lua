-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

vl5.lio  -- Linux I/O functions 

files, directories and filesystems-related functions

	open, close, read, write
	getdents64

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


local lio = {	 -- the vl5.lio module. 

	-- some useful constants 
	--
	-- open / fd flags -- from musl asm-generic/fcntl.h
	O_RDONLY = 0x00000000,
	O_WRONLY = 0x00000001,
	O_RDWR = 0x00000002,
	O_CREAT = 0x00000040,
	O_EXCL = 0x00000080,
	O_TRUNC = 0x00000200,
	O_APPEND = 0x00000400,
	O_NONBLOCK = 0x00000800,
	O_DIRECTORY = 0x00010000,
	O_CLOEXEC = 0x00080000,
	--	
	-- fcntl
	F_GETFD = 0x00000001,
	F_SETFD = 0x00000002,
	F_GETFL = 0x00000003,
	F_SETFL = 0x00000004,
	--
	}--lio
------------------------------------------------------------------------


function lio.fcntl()

end


function lio.open(pathname, flags, mode)
	puts(b, pathname)
	local fd, eno = syscall(nr.open, b, flags, mode)
	if not fd then return nil, eno end
	-- it appears that CLOEXEC is not set by the open syscall
	-- cf musl src open.c.  set it with fcntl
	if flags & lio.O_CLOEXEC ~= 0 then
		local FD_CLOEXEC = 1 -- from fcntl.h
		return syscall(nr.fcntl, fd, lio.F_SETFD, FD_CLOEXEC)
	end
	return fd
end

function lio.close(fd)
	return syscall(nr.close)
end

function lio.read(fd, count)
	assert(count <= blen, "count too large for buffer")
	local r, eno = syscall(nr.read, fd, b, count)
	if not r then return nil, eno end
	local s = gets(b, r)
	return s
end

function lio.readbuf(fd, buf, buflen)
	-- read at most `buflen` bytes using buffer at address `buf`
	-- buf, buflen default to vl5.buf
	buf = buf or vl5.buf
	buflen = buflen or vl5.bufsize
	local r, eno = syscall(nr.read, fd, buf, buflen)
	if not r then return nil, eno end
	local s = gets(b, r)
	return s
end

function lio.write(fd, s)
	assert(#s <= blen, "string too large for buffer")
	puts(b, s)
	return syscall(nr.write, fd, b, #s)
end

function lio.writebuf(fd, s, idx, buf, buflen)
	-- write a slice of string s at index idx of at most buflen bytes
	-- using buffer buf.
	-- buf, buflen default to vl5.buf
	-- 
	idx = idx or 1
	buf = buf or vl5.buf
	buflen = buflen or vl5.bufsize
	local s1 = s:sub(idx, idx + buflen -1)
	puts(buf, s1)
	return syscall(nr.write, fd, buf, #s1)
end


------------------------------------------------------------------------
return lio

