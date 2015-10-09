-- UVCDevice.lua
local ffi = require("ffi")

local uvc = require("uvc")
local ljplatform = require("ljplatform")

local ffistring = ljplatform.ffistring

local UVCDevice = {}
setmetatable(UVCDevice, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local UVCDevice_mt = {
	__index = UVCDevice;
	__toString = function(self)
		return self:toString();
	end;
}

function UVCDevice.init(self, rawHandle)
	local desc = ffi.new("uvc_device_descriptor_t *[1]")

	local res = uvc.uvc_get_device_descriptor(rawHandle, desc);
    if res < 0 then 
    	return nil;
    end

    desc = desc[0]
    ffi.gc(desc, uvc.uvc_free_device_descriptor);

	local obj = {
		Handle = rawHandle;

    	VendorID = tonumber(desc.idVendor);
    	ProductID = tonumber(desc.idProduct);
    	bcdUVC = tonumber(desc.bcdUVC);
    	SerialNumber = ffistring(desc.serialNumber);
    	Manufacturer = ffistring(desc.manufacturer);
    	Product = ffistring(desc.product);

	}

print("assigned object")
	setmetatable(obj, UVCDevice_mt);

	return obj;
end

function UVCDevice.new(self, rawHandle)
	-- setup gc before calling init

	return self:init(rawHandle);
end


function UVCDevice.toString(self)
	return string.format([[
      Product: %s
 Manufacturer: %s 
    Vendor ID: %#x 
   Product ID: %#x 
       bcdUVC: %d
Serial Number: %s
]],
	self.Product,
	self.Manufacturer,
	self.VendorID,
	self.ProductID,
	self.bcdUVC,
	self.SerialNumber)
end


function UVCDevice.open(self)
	local devh = ffi.new("uvc_device_handle_t *[1]")
	local res = uvc.uvc_open(self.Handle, devh);
	
	if res < 0 then return false end
	
	devh = devh[0]
	ffi.gc(devh, uvc.uvc_close);

	self.OpenHandle = devh;
end

function UVCDevice.close(self)
	uvc.uvc_close(self.OpenHandle);
	self.OpenHandle = nil;
end


return UVCDevice