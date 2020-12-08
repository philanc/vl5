
-- test vl5core

local vl5 = require "vl5"
local syscall = vl5.syscall

local nr = require "vl5.nr"



local t1 = os.time()
local t2 = syscall(nr.time)
-- t1 and t2 should _almost_ always be the same value
assert(t1 - t2 <= 1) 

------------------------------------------------------------------------
-- test buffer/memory functions

local b, b1, i, j, i1, j1, r, s

b = vl5.newbuffer(1024)
i, j = 123456, 789
vl5.putuint(b, i, 8)
vl5.putuint(b+8, j, 8)
s = vl5.getstr(b, 16)
i1,j1 = string.unpack("I8I8", s)
assert(i==i1 and j==j1)

i, j = 99, 1001
vl5.putuint(b, i, 1)
vl5.putuint(b+1, j, 2)
s = vl5.getstr(b, 16)
i1,j1 = string.unpack("I1I2", s)
assert(i==i1 and j==j1)

b1 = vl5.newbuffer(1024)
vl5.putstr(b1, string.pack("I8I8", i, j))
i1 = vl5.getuint(b1, 8)
j1 = vl5.getuint(b1+8, 8)
assert(i==i1 and j==j1)

vl5.putstr(b, "AAAAAAAAAA")
vl5.zero(b, 100)
assert(vl5.getstr(b, 100) == string.rep('\0', 100))

r = vl5.syscall(nr.getcwd, b, 1000)
s = vl5.getstr(b)
print("getcwd: " .. s)

vl5.freebuffer(b)
vl5.freebuffer(b1)

------------------------------------------------------------------------
print("test_core: ok.")
