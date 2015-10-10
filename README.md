# LJIT2libuvc
LuaJIT binding to libuvc

libuvc is a convenience library that makes streaming video from things such as webcams relatively easy in a cross platform way (where libusb exists).  This binding makes the library accessible from LuaJIT.

Initially, it supports a relatively simple interface to the library, adding very few Lua conveniences.  This may change over time.

If libuvc is not already on your Linux machine, then go to this site:
* https://int80k.com/libuvc/doc/index.html


Here is a simple capture program which utilizes the callback mechanism.  This should
be run as root as it requires exclusive access to the camera.

```lua
local ffi = require("ffi")
local uvc = require("uvc")
local UVCContext = require("UVCContext")


ffi.cdef[[
  unsigned int sleep(unsigned int);
]]
local sleep = ffi.C.sleep;

--[[
 This callback function runs once per frame. Use it to perform any
 * quick processing you need, or have it put the frame into your application's
 * input queue. If this function takes too long, you'll start losing frames.
--]]
local function cb(frame, ptr)
  io.write('.')
  -- We'll convert the image from YUV/JPEG to BGR, so allocate space
  local bgr = uvc.uvc_allocate_frame(frame.width * frame.height * 3);
  if (bgr == nil) then
    print("unable to allocate bgr frame!");
    return;
  end

  -- Do the BGR conversion
  ret = uvc.uvc_any2bgr(frame, bgr);
  if (ret ~= 0) then
    uvc.uvc_perror(ret, "uvc_any2bgr");
    uvc.uvc_free_frame(bgr);
    return;
  end
  
  uvc.uvc_free_frame(bgr);
end

local function main(argc, argv) 
  local dev = UVCContext():getFirstDevice();
  local devh = dev:getCallbackStream(cb);
  local ctrl, err = devh:formatAndSize(uvc.UVC_FRAME_FORMAT_YUYV, 640, 480, 30);
 
  devh:start();      
  
  sleep(10); -- stream for 10 seconds
    
  devh:stop();
end

main()
```
