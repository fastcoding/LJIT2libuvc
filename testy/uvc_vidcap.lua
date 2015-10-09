--[[
  THIS DOES NOT WORK YET!!!
  SO, DON'T GET YOUR HOPES UP

  THE VARIOUS DATA STRUCTURES NEED TO BE DEALT WITH PROPERLY
  AND THE CALLBACK NEEDS TO BE HANDLED PROPERLY AS WELL
--]]
package.path = package.path..";../?.lua"

local uvc = require("uvc")


--[[
 This callback function runs once per frame. Use it to perform any
 * quick processing you need, or have it put the frame into your application's
 * input queue. If this function takes too long, you'll start losing frames.
--]]
local function cb(frame, ptr)

  -- We'll convert the image from YUV/JPEG to BGR, so allocate space
  local bgr = uvc_allocate_frame(frame->width * frame->height * 3);
  if (bgr == nil) then
    print("unable to allocate bgr frame!");
    return;
  end

  -- Do the BGR conversion
  ret = uvc_any2bgr(frame, bgr);
  if (ret ~= 0) then
    uvc.uvc_perror(ret, "uvc_any2bgr");
    uvc.uvc_free_frame(bgr);
    return;
  end
  
  uvc.uvc_free_frame(bgr);
end

local function main(argc, argv) 
  uvc_context_t *ctx;
  uvc_device_t *dev;
  uvc_device_handle_t *devh;
  uvc_stream_ctrl_t ctrl;
  uvc_error_t res;
  
  --[[
   Initialize a UVC service context. Libuvc will set up its own libusb
    context. Replace NULL with a libusb_context pointer to run libuvc
    from an existing libusb context.
  --]]

  local res = uvc.uvc_init(&ctx, NULL);
  if (res < 0) then
    uvc.uvc_perror(res, "uvc_init");
    return res;
  end

  print("==== UVC initialized ====");


  -- Locates the first attached UVC device, stores in dev
  res = uvc.uvc_find_device(
      ctx, &dev,
      0, 0, NULL); -- filter devices: vendor_id, product_id, "serial_num"

  if (res < 0) then
    uvc.uvc_perror(res, "uvc_find_device"); -- no devices found
  else
    print("Device found");
    -- Try to open the device: requires exclusive access
    res = uvc.uvc_open(dev, &devh);
    if (res < 0) then
      uvc.uvc_perror(res, "uvc_open"); -- unable to open device
    else
      print("Device opened");
      -- Print out a message containing all the information that libuvc
      -- knows about the device
      uvc.uvc_print_diag(devh, io.stderr);

      -- Try to negotiate a 640x480 30 fps YUYV stream profile
      res = uvc.uvc_get_stream_ctrl_format_size(
          devh, &ctrl, -- result stored in ctrl
          UVC_FRAME_FORMAT_YUYV, -- YUV 422, aka YUV 4:2:2. try _COMPRESSED
          640, 480, 30 -- width, height, fps
      );
      
      -- Print out the result
      uvc.uvc_print_stream_ctrl(&ctrl, io.stderr);
      if (res < 0) then
        uvc.uvc_perror(res, "get_mode"); -- device doesn't provide a matching stream
      else
        -- Start the video stream. The library will call user function cb:
        --   cb(frame, (void*) 12345)
        
        res = uvc.uvc_start_streaming(devh, &ctrl, cb, 12345, 0);
        if (res < 0) then
          uvc.uvc_perror(res, "start_streaming"); -- unable to start stream
        else
          print("Streaming...");
          uvc.uvc_set_ae_mode(devh, 1); -- e.g., turn on auto exposure
          sleep(10); -- stream for 10 seconds
          -- End the stream. Blocks until last callback is serviced
          uvc.uvc_stop_streaming(devh);
          print("Done streaming.");
        end
      end

      -- Release our handle on the device
      uvc.uvc_close(devh);
      print("Device closed");
    end
    -- Release the device descriptor
    uvc.uvc_unref_device(dev);
  end
  -- Close the UVC context. This closes and cleans up any existing device handles,
  -- and it closes the libusb context if one was not provided.
  uvc.uvc_exit(ctx);
  print("UVC exited");
  return true;
end

main()

