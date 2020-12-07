
local proc = require "vl5.proc"

print(proc.getpid())
print(proc.getppid())
print(proc.getcwd())
print(proc.chdir("test"))
print(os.time())
print(proc.msleep(2000))
print(os.time())
print(proc.getcwd())
