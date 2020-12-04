

local vl5 = require "vl5"
local syscall = vl5.syscall

local nr = require "syscall_nr"

local t1 = os.time()
local t2 = syscall(nr.time)

-- t1 and t2 should _almost_ always be the same value
assert(t1 - t2 <= 1) 

print(vl5.VERSION, "ok.")


