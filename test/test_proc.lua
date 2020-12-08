
local proc = require "vl5.proc"

--~ print(proc.getpid())
--~ print(proc.getppid())
--~ print(proc.getcwd())
--~ print(proc.chdir("test"))
--~ print(os.time())
--~ print(proc.msleep(2000))
--~ print(os.time())
--~ print(proc.getcwd())

l5=require"l5"

function test_chdir()
	-- test chdir, getcwd
	local path, here, eno
	local tmp = "/tmp"
	here = assert(proc.getcwd())
	assert(proc.chdir(tmp))
	assert(proc.getcwd() == tmp)
	-- return to initial dir
	assert(proc.chdir(here))
	assert(proc.getcwd() == here)
	print("test_chdir: ok.")
end

function test_fork()	
	-- test fork, getpid, getppid, waitpid, kill
	--
	local pid, childpid, parentpid, eno
	parentpid = proc.getpid()
	
	pid = assert(proc.fork())
	if pid == 0 then -- child
		assert(parentpid == proc.getppid())
		os.exit(3)
	else -- parent
		childpid = pid
		-- wait for child to exit
		pid, status = proc.waitpid()
		assert(pid == childpid)
		-- extract exit status, signal and coredump 
		-- indicator from status:
		exit = (status & 0xff00) >> 8
		sig = status & 0x7f
		core = status & 0x80
--~ 		print("  status => exit, sig, coredump =>", exit, sig, core)
		-- child has exited with os.exit(3), so:
		assert(exit==3 and sig==0 and core==0)
	end
	--
	-- now fork the process and try to interrupt the child:
	
	-- 		
	pid, eno = assert(proc.fork())
	if pid == 0 then -- child
		assert(parentpid == proc.getppid())
		-- do not exit before being terminated by parent
		proc.msleep(5000) -- 5 sec is more than enough!
	else -- parent
		childpid = pid
		proc.kill(pid, 15) -- interrupt child with SIGTERM (15)
		pid, status = proc.waitpid()
		assert(pid == childpid)
		-- extract exit status, signal and coredump 
		-- indicator from status:
		exit = (status & 0xff00) >> 8
		sig = status & 0x7f
		core = status & 0x80
--~ 		print("  status => exit, sig, coredump =>", exit, sig, core)
		-- child has been sent signal 15 so:
		assert(exit==0 and sig==15 and core==0)
	end
	print("test_fork: ok.")
end

test_chdir()
test_fork()

