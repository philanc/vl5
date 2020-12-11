
-- run tests
vl5core = require("vl5core")

print(string.rep("-", 60))
print("vl5 version: " .. vl5core.VERSION)

require("test.test_core")
require("test.test_misc")
require("test.test_proc")
require("test.test_lio")


