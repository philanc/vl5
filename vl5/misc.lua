-- Copyright (c) 2020  Phil Leblanc  -- see LICENSE file
-- ---------------------------------------------------------------------

--[[   

vl5.misc

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


local misc = {} -- the vl5.misc module

--[[ uname(2)  

the uname syscall returns system  information  in the following structure

   struct utsname {
       char sysname[];    /* Operating system name (e.g., "Linux") */
       char nodename[];   /* Name within "some implementation-defined
			     network" */
       char release[];    /* Operating system release (e.g., "2.6.28") */
       char version[];    /* Operating system version */
       char machine[];    /* Hardware identifier */
   #ifdef _GNU_SOURCE
       char domainname[]; /* NIS or YP domain name */
   #endif
   };
   
   in a recent linux, with system call __NR_UNAME (nr.uname), 
   all fields should be 65 bytes, incl. null terminator
   
]]

function misc.uname()
	-- return a Lua list with fields `sysname` to `machine`
	--
	local r, eno = syscall(nr.uname, b)
	-- b contains a struct utsname (see above)
	if not r then return nil, eno end
	ul = {}
	for i = 0, 4 do
		table.insert(ul, gets(b + 65*i))
	end
	return ul
end--uname



------------------------------------------------------------------------
return misc

