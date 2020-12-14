-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

vl5.lio  -- Linux I/O functions 

files, directories and filesystems-related functions

	open, close, read, write
	ftruncate
	pipe2, dup2
	ioctl
	dirmap  --a wrapper around getdents64()
todo
	stat, lstat
	mount, umount
	

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
	} --lio constants
------------------------------------------------------------------------

function lio.fcntl()
	--see: man 2 fcntl
	return syscall(nr.fcntl, fd, cmd, arg)
end

-- two frequent use cases of fcntl are to set the CLOEXEC and NONBLOCK flags
-- they provided with their own functions below: 

function lio.set_cloexec(fd)
	local FD_CLOEXEC = 1
	return lio.fcntl(fd, lio.F_SETFD, FD_CLOEXEC)
end

function lio.set_nonblock(fd)
	return lio.fcntl(fd, lio.F_SETFL, lio.O_NONBLOCK)
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
	--
	-- note: arch=64bits (len is uint64, is passed as one arg)
	--
	return syscall(nr.ftruncate, fd, len)
end

function lio.lseek(fd, offset, whence)
	-- reposition the read/write file offset of open file fd
	-- whence = 0 (SET) file offset is set to `offset`
	-- whence = 1 (CUR) file offset is set to current position + `offset`
	-- whence = 2 (END) file offset is set to end of file + `offset`
	--                  (allow to create "holes" in file)
	-- offset defaults to 0
	-- whence defaults to 0 (SET)
	-- return the new offset location, or nil, errno
	--
	-- note: arch=64bits (offset is uint64, is passed as one arg)
	--
	-- (syscall args default to 0)
	return syscall(nr.lseek, fd, offset, whence)
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
	local intsz = 4 -- sizeof(int)
	local p0, p1 = geti(b, intsz), geti(b+intsz, intsz)
	return p0, p1
end

function lio.ioctl(fd, cmd, arg)
	-- `fd`, `cmd`, `arg` are lua integers. 
	-- arg can be an integer argument or the address of a buffer.
	return syscall(nr.ioctl, fd, cmd, arg)
end

------------------------------------------------------------------------
-- directory functions

local typetbl = { -- directory entry type as a one-char string
	[1] = "f", 	-- fifo
	[2] = "c",	-- char device
	[4] = "d",	-- directory
	[6] = "b",	-- block device
	[8] = "r",	-- regular file
	[10] = "l",	-- symlink
	[12] = "s",	-- socket
	-- [14] = "w",  -- whiteout (only bsd? and/or codafs? => ignore it)
}

local function getdent(a)
	-- parse a directory entry (returned by getdents64) at address a 
	-- return 
	--	the address of the next entry
	--	entry name, type (as one char), and inode
	local eino = geti(a, 8) -- inode 
	--local offset = geti(a+8, 8) -- what is offset? ignore it.
	local reclen = geti(a+16, 2) -- entry record length
	local etype = geti(a+18, 1)
	etype = typetbl[etype] or "u" --(unknown)
	local ename = gets(a+19)
	return a + reclen, ename, etype, eino
end

function lio.dirmap(dirpath, f, t, buf, buflen)
	-- map function f over all the directory entries
	-- f signature:  f(t, ename, etype, eino)
	-- t is intended to be a table to collect results (defaults to {})
	-- buf, buflen: the buffer used for the system calls
	-- (defaults to vl5.buf)
	--
	t = t or {}
	buf = buf or b
	buflen = bulen or blen
	local fd, r, eno
	fd, eno = lio.open(dirpath, lio.O_RDONLY | lio.O_DIRECTORY)
	if not fd then 
		print(nil, eno, "opendir", '['..dirpath..']')
		return nil, eno, "opendir" 
	end
	while true do
		r, eno = syscall(nr.getdents64, fd, buf, buflen)
		if not r then 
			return nil, eno, "getdents64" 
		end
--~ 		print("read", r)
		eoe = buf + r
		if r == 0 then break end
		a = buf
		local eino, ename, etype -- dir entry values
		while (a < eoe) do
			a, ename, etype, eino = getdent(a)
			f(t, ename, etype, eino)
		end
	end
	lio.close(fd)
	return t
end

-- utility functions for dirmap
local function append_name_type(t, ename, etype, eino)
	if ename ~= "." and ename ~= ".." then
		table.insert(t, {ename, etype})
	end
	return t
end

local function append_name(t, ename, etype, eino)
	if ename ~= "." and ename ~= ".." then
		table.insert(t, ename)
	end
	return t
end

-- convenience functions to return the content of a directory

function lio.ls(dirpath)
	-- return a list of the names of entries in the directory
	-- ('.' and '..' are not included)
	return lio.dirmap(dirpath, append_name)
end

function lio.ls2(dirpath)
	-- return a list of pairs: {{"name1", "type1"}, {"name2", "type2"}...}
	-- types are one-letter strings, as described above.
	return lio.dirmap(dirpath, append_name_type)
end

------------------------------------------------------------------------
-- stat() functions  -- (for 64-bit arch)

local stat_off = { --field offset in struct stat
	dev = 0,
	ino = 8,
	nlink = 16,
	mode = 24,
	uid = 28,
	gid = 32,
	rdev = 40,
	size = 48,
	blksize = 56,
	blocks = 64,
	atime = 72,
	atime_ns = 80,
	mtime = 88,
	mtime_ns = 96,
	ctime = 104,
	ctime_ns = 112,
}

local stat_len = { --field length in struct stat
	dev = 8,
	ino = 8,
	nlink = 8,
	mode = 4,
	uid = 4,
	gid = 4,
	rdev = 8,
	size = 8,
	blksize = 8,
	blocks = 8,
	atime = 8,
	atime_ns = 8,
	mtime = 8,
	mtime_ns = 8,
	ctime = 8,
	ctime_ns = 8,
}

local stat_names = {
	"dev", "ino", "nlink", "mode", "uid", "gid", "rdev", "size", "blksize",
	"blocks", "atime", "atime_ns", "mtime", "mtime_ns", "ctime", "ctime_ns",
}

function lio.statbuf(pathname, buf)
	-- call the system call stat. The struct stat returned by 
	-- the system call is placed in buffer `buf`
	buf = buf or vl5.buf
	puts(buf + 256, pathname)
	return syscall(nr.stat, buf+256, buf)
end

function lio.lstatbuf(pathname, buf)
	-- call the system call lstat. The struct stat returned by 
	-- the system call is placed in buffer `buf`
	buf = buf or vl5.buf
	puts(buf + 256, pathname)
	return syscall(nr.lstat, buf+256, buf)
end

function lio.stat_get(name, buf)
	-- return a field of struct stat after a call to lio.statbuf() 
	-- or lio.lstatbuf()
	buf = buf or vl5.buf
	return geti(buf + stat_off[name], stat_len[name])
end

function lio.stat(pathname, t, buf)
	-- convenience function. stat is called, the result is returned 
	-- as a Lua table
	t = t or {}
	buf = buf or vl5.buf
	local r, eno = lio.statbuf(pathname, buf)
	if not r then return nil, eno end
	for i, name in ipairs(stat_names) do
		t[name] = geti(buf + stat_off[name], stat_len[name])
	end
	return t
end

function lio.lstat(pathname, t, buf)
	-- convenience function. stat is called, the result is returned 
	-- as a Lua table
	t = t or {}
	buf = buf or vl5.buf
	local r, eno = lio.lstatbuf(pathname, buf)
	if not r then return nil, eno end
	for i, name in ipairs(stat_names) do
		t[name] = geti(buf + stat_off[name], stat_len[name])
	end
	return t
end

-- access to the content of the stat/lstat `mode` attribute

function lio.mtype(mode)
	-- return the file type of a file given its 'mode' attribute
	-- as a one letter string
	return typetbl[(mode >> 12) & 0x1f] or "u"
end

function lio.mperm(mode) 
	-- get the access permissions of a file given its 'mode' attribute
	return mode & 0x0fff
end

function lio.mpermo(mode)
	-- same as mperm(), but return the octal representation of 
	-- permissions as a four-digit string, eg. "0755", "4755", "0600"...	
	return string.format("%04o", mode & 0x0fff) 
end


------------------------------------------------------------------------
return lio

