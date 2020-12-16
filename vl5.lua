-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
------------------------------------------------------------------------

--[[   

VL5  - Very Low-Level Linux Lua Library (syscall interface)

This is for Lua 5.3+ only, built with default 64-bit integers



]]


local vl5 = require "vl5core"

-- create a default buffer that will be used for system calls 
-- by all vl5 submodules, except where noted.
if not vl5.buf then
	vl5.buflen = 32768 -- should be enough for most use cases.
	
	-- allocate the default buffer. No need to test the result
	-- (if allocation fails, newbuffer() raises a Lua error)
	vl5.buf = vl5.newbuffer(vl5.buflen)
end



return vl5

