local ffi = require("ffi")

-- useful types
ffi.cdef[[
typedef uint32_t __useconds_t;
typedef __useconds_t useconds_t;
typedef long suseconds_t;
typedef long time_t;

typedef int64_t off_t;
typedef uint16_t      mode_t;
typedef long ssize_t;

struct timeval { time_t tv_sec; suseconds_t tv_usec; };
struct timespec { time_t tv_sec; long tv_nsec; };


typedef struct _IO_FILE FILE;

]]

local function getValueName(num, tbl)
	tbl = tbl or _G

	for k,v in pairs(tbl)do
		if v == num then
			return k;
		end
	end

	return string.format("UNKNOWN [%d]", num)
end

local exports = {
	getValueName = getValueName;
}

return exports
