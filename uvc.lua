local Lib_uvc = require("uvc_ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local Lib_uvc = require("uvc_ffi")
local plat = require("ljplatform")


-- from uvc_config.h
local function LIBUVC_MAKE_VERSION(major, minor, patch)
	return bor(lshift(major, 16), lshift(minor, 8), patch)
end

local function LIBUVC_VERSION_GTE(major, minor, patch)
	return LIBUVC_VERSION_INT >= LIBUVC_MAKE_VERSION(major, minor, patch)
end

local C = {}
C.LIBUVC_VERSION_MAJOR = 0;
C.LIBUVC_VERSION_MINOR = 0;
C.LIBUVC_VERSION_PATCH = 5;
C.LIBUVC_VERSION_STR = "0.0.5";
C.LIBUVC_VERSION_INT = LIBUVC_MAKE_VERSION(C.LIBUVC_VERSION_MAJOR, C.LIBUVC_VERSION_MINOR, C.LIBUVC_VERSION_PATCH);

--[[
-- can't really do this as we don't know whether the loaded
-- library has JPEG or not
local LIBUVC_HAS_JPEG = true

--]]

local Enums = {
	
	uvc_error = {
		UVC_SUCCESS = 0,
		UVC_ERROR_IO = -1,
		UVC_ERROR_INVALID_PARAM = -2,
		UVC_ERROR_ACCESS = -3,
		UVC_ERROR_NO_DEVICE = -4,
		UVC_ERROR_NOT_FOUND = -5,
		UVC_ERROR_BUSY = -6,
		UVC_ERROR_TIMEOUT = -7,
		UVC_ERROR_OVERFLOW = -8,
		UVC_ERROR_PIPE = -9,
		UVC_ERROR_INTERRUPTED = -10,
		UVC_ERROR_NO_MEM = -11,
		UVC_ERROR_NOT_SUPPORTED = -12,
		UVC_ERROR_INVALID_DEVICE = -50,
		UVC_ERROR_INVALID_MODE = -51,
		UVC_ERROR_CALLBACK_EXISTS = -52,
		UVC_ERROR_OTHER = -99
	} ;

	-- Color coding of stream, transport-independent
	uvc_frame_format = {
		UVC_FRAME_FORMAT_UNKNOWN = 0,
		UVC_FRAME_FORMAT_UNCOMPRESSED = 1,
		UVC_FRAME_FORMAT_COMPRESSED = 2,
		UVC_FRAME_FORMAT_YUYV = 3,
		UVC_FRAME_FORMAT_UYVY = 4,
		UVC_FRAME_FORMAT_RGB = 5,
		UVC_FRAME_FORMAT_BGR = 6,
		UVC_FRAME_FORMAT_MJPEG = 7,
		UVC_FRAME_FORMAT_GRAY8 = 8,
		UVC_FRAME_FORMAT_BY8 = 9,
		UVC_FRAME_FORMAT_COUNT = 10,
	};

	-- VideoStreaming interface descriptor subtype (A.6) */
	uvc_vs_desc_subtype = {
		UVC_VS_UNDEFINED = 0x00,
		UVC_VS_INPUT_HEADER = 0x01,
		UVC_VS_OUTPUT_HEADER = 0x02,
		UVC_VS_STILL_IMAGE_FRAME = 0x03,
		UVC_VS_FORMAT_UNCOMPRESSED = 0x04,
		UVC_VS_FRAME_UNCOMPRESSED = 0x05,
		UVC_VS_FORMAT_MJPEG = 0x06,
		UVC_VS_FRAME_MJPEG = 0x07,
		UVC_VS_FORMAT_MPEG2TS = 0x0a,
		UVC_VS_FORMAT_DV = 0x0c,
		UVC_VS_COLORFORMAT = 0x0d,
		UVC_VS_FORMAT_FRAME_BASED = 0x10,
		UVC_VS_FRAME_FRAME_BASED = 0x11,
		UVC_VS_FORMAT_STREAM_BASED = 0x12
	};

	-- UVC request code (A.8)
	uvc_req_code = {
		UVC_RC_UNDEFINED = 0x00,
		UVC_SET_CUR = 0x01,
		UVC_GET_CUR = 0x81,
		UVC_GET_MIN = 0x82,
		UVC_GET_MAX = 0x83,
		UVC_GET_RES = 0x84,
		UVC_GET_LEN = 0x85,
		UVC_GET_INFO = 0x86,
		UVC_GET_DEF = 0x87
	};

	uvc_device_power_mode = {
		UVC_VC_VIDEO_POWER_MODE_FULL = 0x000b,
		UVC_VC_VIDEO_POWER_MODE_DEVICE_DEPENDENT = 0x001b,
	};

	-- Camera terminal control selector (A.9.4)
	uvc_ct_ctrl_selector = {
		UVC_CT_CONTROL_UNDEFINED = 0x00,
		UVC_CT_SCANNING_MODE_CONTROL = 0x01,
		UVC_CT_AE_MODE_CONTROL = 0x02,
		UVC_CT_AE_PRIORITY_CONTROL = 0x03,
		UVC_CT_EXPOSURE_TIME_ABSOLUTE_CONTROL = 0x04,
		UVC_CT_EXPOSURE_TIME_RELATIVE_CONTROL = 0x05,
		UVC_CT_FOCUS_ABSOLUTE_CONTROL = 0x06,
		UVC_CT_FOCUS_RELATIVE_CONTROL = 0x07,
		UVC_CT_FOCUS_AUTO_CONTROL = 0x08,
		UVC_CT_IRIS_ABSOLUTE_CONTROL = 0x09,
		UVC_CT_IRIS_RELATIVE_CONTROL = 0x0a,
		UVC_CT_ZOOM_ABSOLUTE_CONTROL = 0x0b,
		UVC_CT_ZOOM_RELATIVE_CONTROL = 0x0c,
		UVC_CT_PANTILT_ABSOLUTE_CONTROL = 0x0d,
		UVC_CT_PANTILT_RELATIVE_CONTROL = 0x0e,
		UVC_CT_ROLL_ABSOLUTE_CONTROL = 0x0f,
		UVC_CT_ROLL_RELATIVE_CONTROL = 0x10,
		UVC_CT_PRIVACY_CONTROL = 0x11,
		UVC_CT_FOCUS_SIMPLE_CONTROL = 0x12,
		UVC_CT_DIGITAL_WINDOW_CONTROL = 0x13,
		UVC_CT_REGION_OF_INTEREST_CONTROL = 0x14
	};

	-- Processing unit control selector (A.9.5)
	uvc_pu_ctrl_selector = {
		UVC_PU_CONTROL_UNDEFINED = 0x00,
		UVC_PU_BACKLIGHT_COMPENSATION_CONTROL = 0x01,
		UVC_PU_BRIGHTNESS_CONTROL = 0x02,
		UVC_PU_CONTRAST_CONTROL = 0x03,
		UVC_PU_GAIN_CONTROL = 0x04,
		UVC_PU_POWER_LINE_FREQUENCY_CONTROL = 0x05,
		UVC_PU_HUE_CONTROL = 0x06,
		UVC_PU_SATURATION_CONTROL = 0x07,
		UVC_PU_SHARPNESS_CONTROL = 0x08,
		UVC_PU_GAMMA_CONTROL = 0x09,
		UVC_PU_WHITE_BALANCE_TEMPERATURE_CONTROL = 0x0a,
		UVC_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL = 0x0b,
		UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL = 0x0c,
		UVC_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL = 0x0d,
		UVC_PU_DIGITAL_MULTIPLIER_CONTROL = 0x0e,
		UVC_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL = 0x0f,
		UVC_PU_HUE_AUTO_CONTROL = 0x10,
		UVC_PU_ANALOG_VIDEO_STANDARD_CONTROL = 0x11,
		UVC_PU_ANALOG_LOCK_STATUS_CONTROL = 0x12,
		UVC_PU_CONTRAST_AUTO_CONTROL = 0x13
	};

	-- USB terminal type (B.1)
	uvc_term_type = {
  		UVC_TT_VENDOR_SPECIFIC = 0x0100,
  		UVC_TT_STREAMING = 0x0101
	};

	-- Input terminal type (B.2)
	uvc_it_type = {
  		UVC_ITT_VENDOR_SPECIFIC = 0x0200,
  		UVC_ITT_CAMERA = 0x0201,
  		UVC_ITT_MEDIA_TRANSPORT_INPUT = 0x0202
	};

	-- Output terminal type (B.3)
	uvc_ot_type = {
  		UVC_OTT_VENDOR_SPECIFIC = 0x0300,
		UVC_OTT_DISPLAY = 0x0301,
		UVC_OTT_MEDIA_TRANSPORT_OUTPUT = 0x0302
	};

	-- External terminal type (B.4)
	uvc_et_type = {
		UVC_EXTERNAL_VENDOR_SPECIFIC = 0x0400,
		UVC_COMPOSITE_CONNECTOR = 0x0401,
		UVC_SVIDEO_CONNECTOR = 0x0402,
		UVC_COMPONENT_CONNECTOR = 0x0403
	};


	uvc_status_class = {
		UVC_STATUS_CLASS_CONTROL = 0x10,
		UVC_STATUS_CLASS_CONTROL_CAMERA = 0x11,
		UVC_STATUS_CLASS_CONTROL_PROCESSING = 0x12,
	};

	uvc_status_attribute = {
		UVC_STATUS_ATTRIBUTE_VALUE_CHANGE = 0x00,
		UVC_STATUS_ATTRIBUTE_INFO_CHANGE = 0x01,
		UVC_STATUS_ATTRIBUTE_FAILURE_CHANGE = 0x02,
		UVC_STATUS_ATTRIBUTE_UNKNOWN = 0xff
	};
}


local function uvc_strerror(num)
	return plat.getValueName(num, Enums.uvc_error);
end

local Functions = {
	uvc_strerror = uvc_strerror;
}

local exports = {
	Lib_uvc = Lib_uvc;

	Constants = C;
	Enums = Enums;
	Functions = Functions;
}

setmetatable(exports, {
	__call = function(self, tbl)
		tbl = tbl or _G

		-- export enums
		for k,v in pairs(self.Enums) do
			tbl[k] = v;
			for key, value in pairs(v) do
				tbl[key] = value;
			end
		end

		-- export functions
		for k,v in pairs(self.Functions) do
			tbl[k] = v;
		end

		return self;
	end,

	__index = function(self, key)
		-- lookup the thing in the library
		local success, value = pcall(function() return Lib_uvc[key] end)
		if not success then
			return nil, "not found";
		end

		return value;
	end,
})

return exports
