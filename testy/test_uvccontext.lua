-- test_uvc.lua
package.path = package.path..";../?.lua"


local ctxt = require("UVCContext")()


print("==== Devices ====")
for _, device in ctxt:devices() do
	print(device:toString())
end
 
