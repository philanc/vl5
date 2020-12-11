
-- simple tests for module vl5.io

local vl5 = require "vl5"
local lio = require "vl5.lio"
local util = require "vl5.util"
local proc = require "vl5.proc"

------------------------------------------------------------------------



------------------------------------------------------------------------

local function test_file()
	-- use open, read, write, close, dup2
	--
	local fname = "zzlio"
	local str = "HELLO"
	local mode = tonumber("600", 8) -- "rw- --- ---"
	local fd, fd2, fd3, r, eno, s
	fd = assert(lio.open(fname, lio.O_CREAT | lio.O_RDWR, mode))
	fd2, eno = lio.open(fname, lio.O_CREAT | lio.O_RDWR | lio.O_EXCL, mode)
	assert(not fd2 and eno == 17) -- 17=EEXIST
	local r, eno
	r = lio.write(fd, str)
	assert(r == #str)
	assert(util.fget(fname) == str)
	assert(lio.close(fd))
	--
	-- now reopen, dup2 and read from the new fd
	fd2 = assert(lio.open(fname, lio.O_RDONLY))
	fd3 = assert(lio.dup2(fd2, fd2+10)) -- assume fd2+10 does not exist
	assert(fd3 == fd2+10)
	assert(lio.close(fd2))
	s = assert(lio.read(fd3))
	assert(s == str)
	assert(lio.close(fd3))
	os.remove(fname)
end--test_file

local function test_pipe()
	local r, eno, pid, status
	local p0, p1 = lio.pipe2() -- should be 3 and 4
	assert(p0==3 and p1==4, "not 3,4 - any redirection?")
	assert(lio.write(p1, "HELLO"))
	local s = assert(lio.read(p0))
	assert(s == "HELLO")
	local pid = assert(proc.fork())
	if pid == 0 then -- child
		lio.write(p1, "HELLO from child")
		-- close child end of the pipe
		assert( lio.close(p0) and lio.close(p1), 
			"error closing pipe in child")
		os.exit()
	else -- parent
		s, eno = assert(lio.read(p0))
		assert(s == "HELLO from child")
		assert(lio.close(p0)) -- close parent end of the pipe
		assert(lio.close(p1)) -- id.
		assert(proc.waitpid())
	end
end--test_pipe

test_file()
test_pipe()


print("test_lio: ok.")

