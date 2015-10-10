--UVCCallbackStream.lua

local ffi = require("ffi")
local uvc = require("uvc")

local UVCCallbackStream = {}
setmetatable(UVCCallbackStream, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local UVCCallbackStream_mt = {
	__index = UVCCallbackStream;
}

function UVCCallbackStream.init(self, rawHandle, framecb)
	local obj = {
		Handle = rawHandle;
		FrameCallback = framecb;
	}
	setmetatable(obj, UVCCallbackStream_mt);

	return obj;
end

function UVCCallbackStream.new(self, devHandle, framecb)
	local devh = ffi.new("uvc_device_handle_t *[1]")
    local res = uvc.uvc_open(devHandle, devh);

    if res < 0 then
    	return nil, "could not open device handle"
    end

    devh = devh[0];
    ffi.gc(devh, uvc.uvc_close);

	return self:init(devh, framecb);
end

function UVCCallbackStream.formatAndSize(self, fmt, width, height, fps)
	local ctrl = ffi.new("uvc_stream_ctrl_t")
	local res = uvc.uvc_get_stream_ctrl_format_size(self.Handle, ctrl, fmt, width, height, fps); 		
	if res < 0 then
		return false, "could not get stream format"
	end
	
	self.Config = ctrl;

	return ctrl;
end

function UVCCallbackStream.start(self)
	local res = uvc.uvc_start_streaming(self.Handle, self.Config, self.FrameCallback, nil, 0);

	return res >= 0;
end

function UVCCallbackStream.stop(self)
	-- End the stream. Blocks until last callback is serviced
	uvc.uvc_stop_streaming(self.Handle);
	
	return true;
end

function UVCCallbackStream.print(self)
	uvc.uvc_print_diag(self.Handle, io.stdout);
end

return UVCCallbackStream;
