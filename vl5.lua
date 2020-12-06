-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

VL5  - Very Low-Level Linux Lua Library (syscall interface)

This is for Lua 5.3+ only, built with default 64-bit integers



]]


local vl5 = require "vl5core"

-- create a default buffer
if not vl5.buf then
	vl5.bufsize = 8192
	vl5.buf = vl5.newbuffer(vl5.bufsize)
end



return vl5

