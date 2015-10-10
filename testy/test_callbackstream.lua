--[[
  This code works so far as it will actually grab a camera, and start the video 
  capture, which means the 'cb()' function will be called for each frame.

  That's useful, if you're processing the frames fast enough to keep up.  If not
  then you could alter this to use the 'polling' method instead, pulling the 
  frames at your leisure.

  For a lua context, polling might work out better as you can control the flow
  using coroutines and wakeups when there's something available.
--]]
package.path = package.path..";../?.lua"

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
  local ctxt = UVCContext();
  assert(ctxt, "could not create UVCContext")

  local dev = ctxt:getFirstDevice();
  assert(dev, "could not get first device")

  -- Try to open the device: requires exclusive access
  local devh, err = dev:getCallbackStream(cb);
  assert(devh, err)

  devh:print();

  -- Try to negotiate a 640x480 30 fps YUYV stream profile
  local ctrl, err = devh:formatAndSize(uvc.UVC_FRAME_FORMAT_YUYV, 640, 480, 30);
  assert(ctrl, err)

  -- Print out the result
  --uvc.uvc_print_stream_ctrl(ctrl, io.stdout);
  --ctrl:print();
      
  -- Start the video stream. The library will call user function cb:
  --   cb(frame, (void*) 12345)
  assert(devh:start(), "could not start the streaming");
  
  sleep(10); -- stream for 10 seconds

  print("Streaming...");
    
  devh:stop();
   
  return true;
end

main()
