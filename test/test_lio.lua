
-- simple tests for module vl5.io

local vl5 = require "vl5"
local lio = require "vl5.lio"
local util = require "vl5.util"

------------------------------------------------------------------------



------------------------------------------------------------------------

local function test_file()
	local fname = "zzlio"
	local str = "HELLO"
	local mode = tonumber("600", 8)
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
	assert(lio.close(fd2))
	assert(fd3 == fd2+10)
	s = assert(lio.read(fd3))
	assert(s == str)
	assert(lio.close(fd3))
	os.remove(fname)
end--test_file


test_file()

print("test_lio: ok.")

