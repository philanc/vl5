
local misc = require "vl5.misc"

function test_uname()	
	local ul = assert(misc.uname())
--~ 	for i,u in ipairs(ul) do print(i, u) end
	assert(ul[1] == "Linux")
	assert(ul[5] == "x86_64") -- ATM, vl5 is implemented only for x86_64
end

test_uname()

print("test_misc: ok.")
