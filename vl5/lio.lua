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
	return syscall(nr.close, fd)
end

function lio.read(fd, count, buf, buflen)
	-- read at most `count` bytes from fd, using buffer `buf`
	-- return read bytes as a string, or nil, errno
	-- buf, buflen  default to vl5.buf, vl4.bufsize
	-- count defaults to buflen
	buf = buf or vl5.buf
	buflen = buflen or vl5.bufsize
	count = count or buflen
	assert(count <= buflen)
	local r, eno = syscall(nr.read, fd, buf, count)
	if not r then return nil, eno end
	local s = gets(buf, r)
	return s
end

function lio.write(fd, s, buf, buflen)
	-- write string s to fd, using buffer `buf`
	-- returns the number of written bytes, or nil, errno
	-- buf, buflen  default to vl5.buf, vl4.bufsize
	buf = buf or vl5.buf
	buflen = buflen or vl5.bufsize
	assert(#s <= buflen, "string too large for buffer")
	puts(b, s)
	return syscall(nr.write, fd, buf, #s)
end 

function lio.ftruncate(fd, len)
	-- truncate file to length `len`. If the file was shorter, 
	-- it is extended with null bytes.
	-- return 0 or nil, errno
	return syscall(nr.ftruncate, fd, len)
end

function lio.dup2(oldfd, newfd)
	-- return newfd, or nil, errno
	local r, eno
	r, eno = syscall(nr.dup2, oldfd, newfd)
	-- [ may should enclose in a busy loop:
	-- while eno ~= EBUSY do syscall(...) end
	-- becuse of a race condition with open()
	-- See musl src/unistd/dup2.c
	return r, eno
end

function lio.pipe2(flags)
	local r, eno = syscall(nr.pipe2, b, flags)
	if not r then return nil, eno end
	local intsz = 4
	local p0, p1 = geti(b, intsz), geti(b+intsz, intsz)
	return p0, p1
end

------------------------------------------------------------------------
return lio

