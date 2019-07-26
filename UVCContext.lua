-- UVCContext.lua
local ffi = require("ffi")
local uvc = require("uvc")

local UVCDevice = require("UVCDevice")


local UVCContext = {}
setmetatable(UVCContext, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local UVCContext_mt = {
	__index = UVCContext;
}

function UVCContext.init(self, rawHandle)
	local obj = {
		Handle = rawHandle;
	}
	setmetatable(obj, UVCContext_mt);

	return obj;
end

function UVCContext.new(self, ...)
	local ctx = ffi.new("uvc_context_t *[1]")
	local res = uvc.uvc_init(ctx, NULL);
	if res < 0 then
    	uvc.uvc_perror(res, "uvc_init");
    	return nil, res;
  	end

 	-- ensure eventual garbage collection
 	ffi.gc(ctx[0], uvc.uvc_exit);

	return self:init(ctx[0]);
end

function UVCContext.getFirstDevice(self)
	for _, device in self:devices() do
		return device;
	end

	return nil;
end

function UVCContext.deviceByFd(self,fd)
	local rawHandle=uvc.uvc_handle_from_fd(self.Handle,fd)
	return UVCDevice(rawHandle)
end

-- iterator for devices
local function nil_gen()
	return nil;
end

function UVCContext.devices(self)
	local devlist = ffi.new("uvc_device_t**[1]")
	local res = uvc.uvc_get_device_list(self.Handle,devlist);
	if res < 0 then
		return nilgen, nil, nil
	end

	local function free_device_list(devlist)
		uvc.uvc_free_device_list(devlist, 0);
	end

	--ffi.gc(devlist[0], free_device_list);


	local function device_gen(device_list, idx)
		if device_list[idx] == nil then
			return nil;
		end

		return idx+1, UVCDevice(device_list[idx]);
	end

	return device_gen, devlist[0], 0
end

return UVCContext
