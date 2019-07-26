local ffi = require("ffi")

--[[
#include <stdio.h> // FILE
#include <libusb-1.0/libusb.h>

--]]
require("ljplatform")

ffi.cdef[[
typedef struct libusb_context libusb_context;
typedef struct libusb_device libusb_device;
typedef struct libusb_device_handle libusb_device_handle;
]]


ffi.cdef[[
struct uvc_format_desc;
struct uvc_frame_desc;

/** Frame descriptor
 *
 * A "frame" is a configuration of a streaming format
 * for a particular image size at one of possibly several
 * available frame rates.
 */
typedef struct uvc_frame_desc {
  struct uvc_format_desc *parent;
  struct uvc_frame_desc *prev, *next;
  /** Type of frame, such as JPEG frame or uncompressed frme */
  int /* enum uvc_vs_desc_subtype */ bDescriptorSubtype;
  /** Index of the frame within the list of specs available for this format */
  uint8_t bFrameIndex;
  uint8_t bmCapabilities;
  /** Image width */
  uint16_t wWidth;
  /** Image height */
  uint16_t wHeight;
  /** Bitrate of corresponding stream at minimal frame rate */
  uint32_t dwMinBitRate;
  /** Bitrate of corresponding stream at maximal frame rate */
  uint32_t dwMaxBitRate;
  /** Maximum number of bytes for a video frame */
  uint32_t dwMaxVideoFrameBufferSize;
  /** Default frame interval (in 100ns units) */
  uint32_t dwDefaultFrameInterval;
  /** Minimum frame interval for continuous mode (100ns units) */
  uint32_t dwMinFrameInterval;
  /** Maximum frame interval for continuous mode (100ns units) */
  uint32_t dwMaxFrameInterval;
  /** Granularity of frame interval range for continuous mode (100ns) */
  uint32_t dwFrameIntervalStep;
  /** Frame intervals */
  uint8_t bFrameIntervalType;
  /** number of bytes per line */
  uint32_t dwBytesPerLine;
  /** Available frame rates, zero-terminated (in 100ns units) */
  uint32_t *intervals;
} uvc_frame_desc_t;

/** Format descriptor
 *
 * A "format" determines a stream's image type (e.g., raw YUYV or JPEG)
 * and includes many "frame" configurations.
 */
typedef struct uvc_format_desc {
  struct uvc_streaming_interface *parent;
  struct uvc_format_desc *prev, *next;
  /** Type of image stream, such as JPEG or uncompressed. */
  int /* enum uvc_vs_desc_subtype */ bDescriptorSubtype;
  /** Identifier of this format within the VS interface's format list */
  uint8_t bFormatIndex;
  uint8_t bNumFrameDescriptors;
  /** Format specifier */
  union {
    uint8_t guidFormat[16];
    uint8_t fourccFormat[4];
  };
  /** Format-specific data */
  union {
    /** BPP for uncompressed stream */
    uint8_t bBitsPerPixel;
    /** Flags for JPEG stream */
    uint8_t bmFlags;
  };
  /** Default {uvc_frame_desc} to choose given this format */
  uint8_t bDefaultFrameIndex;
  uint8_t bAspectRatioX;
  uint8_t bAspectRatioY;
  uint8_t bmInterlaceFlags;
  uint8_t bCopyProtect;
  uint8_t bVariableSize;
  /** Available frame specifications for this format */
  struct uvc_frame_desc *frame_descs;
} uvc_format_desc_t;



/** Context, equivalent to libusb's contexts.
 *
 * May either own a libusb context or use one that's already made.
 *
 * Always create these with uvc_get_context.
 */
struct uvc_context;
typedef struct uvc_context uvc_context_t;

/** UVC device.
 *
 * Get this from uvc_get_device_list() or uvc_find_device().
 */
struct uvc_device;
typedef struct uvc_device uvc_device_t;

/** Handle on an open UVC device.
 *
 * Get one of these from uvc_open(). Once you uvc_close()
 * it, it's no longer valid.
 */
struct uvc_device_handle;
typedef struct uvc_device_handle uvc_device_handle_t;

/** Handle on an open UVC stream.
 *
 * Get one of these from uvc_stream_open*().
 * Once you uvc_stream_close() it, it will no longer be valid.
 */
struct uvc_stream_handle;
typedef struct uvc_stream_handle uvc_stream_handle_t;

/** Representation of the interface that brings data into the UVC device */
typedef struct uvc_input_terminal {
  struct uvc_input_terminal *prev, *next;
  /** Index of the terminal within the device */
  uint8_t bTerminalID;
  /** Type of terminal (e.g., camera) */
  int wTerminalType;   // enum uvc_it_type
  uint16_t wObjectiveFocalLengthMin;
  uint16_t wObjectiveFocalLengthMax;
  uint16_t wOcularFocalLength;
  /** Camera controls (meaning of bits given in {uvc_ct_ctrl_selector}) */
  uint64_t bmControls;
} uvc_input_terminal_t;

typedef struct uvc_output_terminal {
  struct uvc_output_terminal *prev, *next;
  /** @todo */
} uvc_output_terminal_t;

/** Represents post-capture processing functions */
typedef struct uvc_processing_unit {
  struct uvc_processing_unit *prev, *next;
  /** Index of the processing unit within the device */
  uint8_t bUnitID;
  /** Index of the terminal from which the device accepts images */
  uint8_t bSourceID;
  /** Processing controls (meaning of bits given in {uvc_pu_ctrl_selector}) */
  uint64_t bmControls;
} uvc_processing_unit_t;

/** Custom processing or camera-control functions */
typedef struct uvc_extension_unit {
  struct uvc_extension_unit *prev, *next;
  /** Index of the extension unit within the device */
  uint8_t bUnitID;
  /** GUID identifying the extension unit */
  uint8_t guidExtensionCode[16];
  /** Bitmap of available controls (manufacturer-dependent) */
  uint64_t bmControls;
} uvc_extension_unit_t;


/** A callback function to accept status updates
 * @ingroup device
 */
typedef void(uvc_status_callback_t)(int status_class,   // enum uvc_status_class
                                    int event,
                                    int selector,
                                    int status_attribute, // enum uvc_status_attribute
                                    void *data, size_t data_len,
                                    void *user_ptr);

/** Structure representing a UVC device descriptor.
 *
 * (This isn't a standard structure.)
 */
typedef struct uvc_device_descriptor {
  /** Vendor ID */
  uint16_t idVendor;
  /** Product ID */
  uint16_t idProduct;
  /** UVC compliance level, e.g. 0x0100 (1.0), 0x0110 */
  uint16_t bcdUVC;
  /** Serial number (null if unavailable) */
  const char *serialNumber;
  /** Device-reported manufacturer name (or null) */
  const char *manufacturer;
  /** Device-reporter product name (or null) */
  const char *product;
} uvc_device_descriptor_t;
]]

ffi.cdef[[
/** An image frame received from the UVC device
 * @ingroup streaming
 */
typedef struct uvc_frame {
  void *data;
  size_t data_bytes;
  uint32_t width;
  uint32_t height;

  int frame_format;   //   enum uvc_frame_format
  /** Number of bytes per horizontal line (undefined for compressed format) */
  size_t step;
  uint32_t sequence;
  struct timeval capture_time;
  /** Handle on the device that produced the image.
   * @warning You must not call any uvc_* functions during a callback. */
  uvc_device_handle_t *source;
  /** Is the data buffer owned by the library?
   * If 1, the data buffer can be arbitrarily reallocated by frame conversion
   * functions.
   * If 0, the data buffer will not be reallocated or freed by the library.
   * Set this field to zero if you are supplying the buffer.
   */
  uint8_t library_owns_data;
} uvc_frame_t;
]]

ffi.cdef[[
/** A callback function to handle incoming assembled UVC frames
 * @ingroup streaming
 */
typedef void(uvc_frame_callback_t)(struct uvc_frame *frame, void *user_ptr);
]]

ffi.cdef[[
/** Streaming mode, includes all information needed to select stream
 * @ingroup streaming
 */
typedef struct uvc_stream_ctrl {
  uint16_t bmHint;
  uint8_t bFormatIndex;
  uint8_t bFrameIndex;
  uint32_t dwFrameInterval;
  uint16_t wKeyFrameRate;
  uint16_t wPFrameRate;
  uint16_t wCompQuality;
  uint16_t wCompWindowSize;
  uint16_t wDelay;
  uint32_t dwMaxVideoFrameSize;
  uint32_t dwMaxPayloadTransferSize;
  uint32_t dwClockFrequency;
  uint8_t bmFramingInfo;
  uint8_t bPreferredVersion;
  uint8_t bMinVersion;
  uint8_t bMaxVersion;
  uint8_t bInterfaceNumber;
} uvc_stream_ctrl_t;
]]

ffi.cdef[[
int /* uvc_error_t */ uvc_init(uvc_context_t **ctx, struct libusb_context *usb_ctx);
void uvc_exit(uvc_context_t *ctx);

int /* uvc_error_t */ uvc_get_device_list(
    uvc_context_t *ctx,
    uvc_device_t ***list);
void uvc_free_device_list(uvc_device_t **list, uint8_t unref_devices);

int /* uvc_error_t */ uvc_get_device_descriptor(
    uvc_device_t *dev,
    uvc_device_descriptor_t **desc);
void uvc_free_device_descriptor(
    uvc_device_descriptor_t *desc);

uint8_t uvc_get_bus_number(uvc_device_t *dev);
uint8_t uvc_get_device_address(uvc_device_t *dev);

int /* uvc_error_t */ uvc_find_device(
    uvc_context_t *ctx,
    uvc_device_t **dev,
    int vid, int pid, const char *sn);

int /* uvc_error_t */ uvc_open(
    uvc_device_t *dev,
    uvc_device_handle_t **devh);
void uvc_close(uvc_device_handle_t *devh);

uvc_device_handle_t* uvc_handle_from_fd(uvc_context_t*ctx,intptr_t sys_dev);

uvc_device_t *uvc_get_device(uvc_device_handle_t *devh);
libusb_device_handle *uvc_get_libusb_handle(uvc_device_handle_t *devh);

void uvc_ref_device(uvc_device_t *dev);
void uvc_unref_device(uvc_device_t *dev);

void uvc_set_status_callback(uvc_device_handle_t *devh,
                             uvc_status_callback_t cb,
                             void *user_ptr);

const uvc_input_terminal_t *uvc_get_input_terminals(uvc_device_handle_t *devh);
const uvc_output_terminal_t *uvc_get_output_terminals(uvc_device_handle_t *devh);
const uvc_processing_unit_t *uvc_get_processing_units(uvc_device_handle_t *devh);
const uvc_extension_unit_t *uvc_get_extension_units(uvc_device_handle_t *devh);

int /* uvc_error_t */ uvc_get_stream_ctrl_format_size(
    uvc_device_handle_t *devh,
    uvc_stream_ctrl_t *ctrl,
    int format,   // enum uvc_frame_format
    int width, int height,
    int fps
    );

const uvc_format_desc_t *uvc_get_format_descs(uvc_device_handle_t* );

int /* uvc_error_t */ uvc_probe_stream_ctrl(
    uvc_device_handle_t *devh,
    uvc_stream_ctrl_t *ctrl);

int /* uvc_error_t */ uvc_start_streaming(
    uvc_device_handle_t *devh,
    uvc_stream_ctrl_t *ctrl,
    uvc_frame_callback_t *cb,
    void *user_ptr,
    uint8_t flags);

int /* uvc_error_t */ uvc_start_iso_streaming(
    uvc_device_handle_t *devh,
    uvc_stream_ctrl_t *ctrl,
    uvc_frame_callback_t *cb,
    void *user_ptr);

void uvc_stop_streaming(uvc_device_handle_t *devh);

int /* uvc_error_t */ uvc_stream_open_ctrl(uvc_device_handle_t *devh, uvc_stream_handle_t **strmh, uvc_stream_ctrl_t *ctrl);
int /* uvc_error_t */ uvc_stream_ctrl(uvc_stream_handle_t *strmh, uvc_stream_ctrl_t *ctrl);
int /* uvc_error_t */ uvc_stream_start(uvc_stream_handle_t *strmh,
    uvc_frame_callback_t *cb,
    void *user_ptr,
    uint8_t flags);
int /* uvc_error_t */ uvc_stream_start_iso(uvc_stream_handle_t *strmh,
    uvc_frame_callback_t *cb,
    void *user_ptr);
int /* uvc_error_t */ uvc_stream_get_frame(
    uvc_stream_handle_t *strmh,
    uvc_frame_t **frame,
    int32_t timeout_us
);
int /* uvc_error_t */ uvc_stream_stop(uvc_stream_handle_t *strmh);
void uvc_stream_close(uvc_stream_handle_t *strmh);

int uvc_get_ctrl_len(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl);
int uvc_get_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len, int req_code);
int uvc_set_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len);

int /* uvc_error_t */ uvc_get_power_mode(uvc_device_handle_t *devh, int *mode, int req_code);
int /* uvc_error_t */ uvc_set_power_mode(uvc_device_handle_t *devh, int mode);
]]

ffi.cdef[[
/* AUTO-GENERATED control accessors! Update them with the output of `ctrl-gen.py decl`. */
int /* uvc_error_t */ uvc_get_scanning_mode(uvc_device_handle_t *devh, uint8_t* mode, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_scanning_mode(uvc_device_handle_t *devh, uint8_t mode);

int /* uvc_error_t */ uvc_get_ae_mode(uvc_device_handle_t *devh, uint8_t* mode, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_ae_mode(uvc_device_handle_t *devh, uint8_t mode);

int /* uvc_error_t */ uvc_get_ae_priority(uvc_device_handle_t *devh, uint8_t* priority, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_ae_priority(uvc_device_handle_t *devh, uint8_t priority);

int /* uvc_error_t */ uvc_get_exposure_abs(uvc_device_handle_t *devh, uint32_t* time, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_exposure_abs(uvc_device_handle_t *devh, uint32_t time);

int /* uvc_error_t */ uvc_get_exposure_rel(uvc_device_handle_t *devh, int8_t* step, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_exposure_rel(uvc_device_handle_t *devh, int8_t step);

int /* uvc_error_t */ uvc_get_focus_abs(uvc_device_handle_t *devh, uint16_t* focus, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_focus_abs(uvc_device_handle_t *devh, uint16_t focus);

int /* uvc_error_t */ uvc_get_focus_rel(uvc_device_handle_t *devh, int8_t* focus_rel, uint8_t* speed, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_focus_rel(uvc_device_handle_t *devh, int8_t focus_rel, uint8_t speed);

int /* uvc_error_t */ uvc_get_focus_simple_range(uvc_device_handle_t *devh, uint8_t* focus, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_focus_simple_range(uvc_device_handle_t *devh, uint8_t focus);

int /* uvc_error_t */ uvc_get_focus_auto(uvc_device_handle_t *devh, uint8_t* state, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_focus_auto(uvc_device_handle_t *devh, uint8_t state);

int /* uvc_error_t */ uvc_get_iris_abs(uvc_device_handle_t *devh, uint16_t* iris, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_iris_abs(uvc_device_handle_t *devh, uint16_t iris);

int /* uvc_error_t */ uvc_get_iris_rel(uvc_device_handle_t *devh, uint8_t* iris_rel, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_iris_rel(uvc_device_handle_t *devh, uint8_t iris_rel);

int /* uvc_error_t */ uvc_get_zoom_abs(uvc_device_handle_t *devh, uint16_t* focal_length, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_zoom_abs(uvc_device_handle_t *devh, uint16_t focal_length);

int /* uvc_error_t */ uvc_get_zoom_rel(uvc_device_handle_t *devh, int8_t* zoom_rel, uint8_t* digital_zoom, uint8_t* speed, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_zoom_rel(uvc_device_handle_t *devh, int8_t zoom_rel, uint8_t digital_zoom, uint8_t speed);

int /* uvc_error_t */ uvc_get_pantilt_abs(uvc_device_handle_t *devh, int32_t* pan, int32_t* tilt, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_pantilt_abs(uvc_device_handle_t *devh, int32_t pan, int32_t tilt);

int /* uvc_error_t */ uvc_get_pantilt_rel(uvc_device_handle_t *devh, int8_t* pan_rel, uint8_t* pan_speed, int8_t* tilt_rel, uint8_t* tilt_speed, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_pantilt_rel(uvc_device_handle_t *devh, int8_t pan_rel, uint8_t pan_speed, int8_t tilt_rel, uint8_t tilt_speed);

int /* uvc_error_t */ uvc_get_roll_abs(uvc_device_handle_t *devh, int16_t* roll, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_roll_abs(uvc_device_handle_t *devh, int16_t roll);

int /* uvc_error_t */ uvc_get_roll_rel(uvc_device_handle_t *devh, int8_t* roll_rel, uint8_t* speed, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_roll_rel(uvc_device_handle_t *devh, int8_t roll_rel, uint8_t speed);

int /* uvc_error_t */ uvc_get_privacy(uvc_device_handle_t *devh, uint8_t* privacy, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_privacy(uvc_device_handle_t *devh, uint8_t privacy);

int /* uvc_error_t */ uvc_get_digital_window(uvc_device_handle_t *devh, uint16_t* window_top, uint16_t* window_left, uint16_t* window_bottom, uint16_t* window_right, uint16_t* num_steps, uint16_t* num_steps_units, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_digital_window(uvc_device_handle_t *devh, uint16_t window_top, uint16_t window_left, uint16_t window_bottom, uint16_t window_right, uint16_t num_steps, uint16_t num_steps_units);

int /* uvc_error_t */ uvc_get_digital_roi(uvc_device_handle_t *devh, uint16_t* roi_top, uint16_t* roi_left, uint16_t* roi_bottom, uint16_t* roi_right, uint16_t* auto_controls, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_digital_roi(uvc_device_handle_t *devh, uint16_t roi_top, uint16_t roi_left, uint16_t roi_bottom, uint16_t roi_right, uint16_t auto_controls);

int /* uvc_error_t */ uvc_get_backlight_compensation(uvc_device_handle_t *devh, uint16_t* backlight_compensation, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_backlight_compensation(uvc_device_handle_t *devh, uint16_t backlight_compensation);

int /* uvc_error_t */ uvc_get_brightness(uvc_device_handle_t *devh, int16_t* brightness, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_brightness(uvc_device_handle_t *devh, int16_t brightness);

int /* uvc_error_t */ uvc_get_contrast(uvc_device_handle_t *devh, uint16_t* contrast, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_contrast(uvc_device_handle_t *devh, uint16_t contrast);

int /* uvc_error_t */ uvc_get_contrast_auto(uvc_device_handle_t *devh, uint8_t* contrast_auto, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_contrast_auto(uvc_device_handle_t *devh, uint8_t contrast_auto);

int /* uvc_error_t */ uvc_get_gain(uvc_device_handle_t *devh, uint16_t* gain, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_gain(uvc_device_handle_t *devh, uint16_t gain);

int /* uvc_error_t */ uvc_get_power_line_frequency(uvc_device_handle_t *devh, uint8_t* power_line_frequency, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_power_line_frequency(uvc_device_handle_t *devh, uint8_t power_line_frequency);

int /* uvc_error_t */ uvc_get_hue(uvc_device_handle_t *devh, int16_t* hue, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_hue(uvc_device_handle_t *devh, int16_t hue);

int /* uvc_error_t */ uvc_get_hue_auto(uvc_device_handle_t *devh, uint8_t* hue_auto, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_hue_auto(uvc_device_handle_t *devh, uint8_t hue_auto);

int /* uvc_error_t */ uvc_get_saturation(uvc_device_handle_t *devh, uint16_t* saturation, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_saturation(uvc_device_handle_t *devh, uint16_t saturation);

int /* uvc_error_t */ uvc_get_sharpness(uvc_device_handle_t *devh, uint16_t* sharpness, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_sharpness(uvc_device_handle_t *devh, uint16_t sharpness);

int /* uvc_error_t */ uvc_get_gamma(uvc_device_handle_t *devh, uint16_t* gamma, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_gamma(uvc_device_handle_t *devh, uint16_t gamma);

int /* uvc_error_t */ uvc_get_white_balance_temperature(uvc_device_handle_t *devh, uint16_t* temperature, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_white_balance_temperature(uvc_device_handle_t *devh, uint16_t temperature);

int /* uvc_error_t */ uvc_get_white_balance_temperature_auto(uvc_device_handle_t *devh, uint8_t* temperature_auto, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_white_balance_temperature_auto(uvc_device_handle_t *devh, uint8_t temperature_auto);

int /* uvc_error_t */ uvc_get_white_balance_component(uvc_device_handle_t *devh, uint16_t* blue, uint16_t* red, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_white_balance_component(uvc_device_handle_t *devh, uint16_t blue, uint16_t red);

int /* uvc_error_t */ uvc_get_white_balance_component_auto(uvc_device_handle_t *devh, uint8_t* white_balance_component_auto, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_white_balance_component_auto(uvc_device_handle_t *devh, uint8_t white_balance_component_auto);

int /* uvc_error_t */ uvc_get_digital_multiplier(uvc_device_handle_t *devh, uint16_t* multiplier_step, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_digital_multiplier(uvc_device_handle_t *devh, uint16_t multiplier_step);

int /* uvc_error_t */ uvc_get_digital_multiplier_limit(uvc_device_handle_t *devh, uint16_t* multiplier_step, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_digital_multiplier_limit(uvc_device_handle_t *devh, uint16_t multiplier_step);

int /* uvc_error_t */ uvc_get_analog_video_standard(uvc_device_handle_t *devh, uint8_t* video_standard, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_analog_video_standard(uvc_device_handle_t *devh, uint8_t video_standard);

int /* uvc_error_t */ uvc_get_analog_video_lock_status(uvc_device_handle_t *devh, uint8_t* status, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_analog_video_lock_status(uvc_device_handle_t *devh, uint8_t status);

int /* uvc_error_t */ uvc_get_input_select(uvc_device_handle_t *devh, uint8_t* selector, int /* enum uvc_req_code */ req_code);
int /* uvc_error_t */ uvc_set_input_select(uvc_device_handle_t *devh, uint8_t selector);
/* end AUTO-GENERATED control accessors */
]]

ffi.cdef[[
void uvc_perror(int /* uvc_error_t */ err, const char *msg);
const char* uvc_strerror(int /* uvc_error_t */ err);
void uvc_print_diag(uvc_device_handle_t *devh, FILE *stream);
void uvc_print_stream_ctrl(uvc_stream_ctrl_t *ctrl, FILE *stream);

uvc_frame_t *uvc_allocate_frame(size_t data_bytes);
void uvc_free_frame(uvc_frame_t *frame);

int /* uvc_error_t */ uvc_duplicate_frame(uvc_frame_t *in, uvc_frame_t *out);

int /* uvc_error_t */ uvc_yuyv2rgb(uvc_frame_t *in, uvc_frame_t *out);
int /* uvc_error_t */ uvc_uyvy2rgb(uvc_frame_t *in, uvc_frame_t *out);
int /* uvc_error_t */ uvc_any2rgb(uvc_frame_t *in, uvc_frame_t *out);

int /* uvc_error_t */ uvc_yuyv2bgr(uvc_frame_t *in, uvc_frame_t *out);
int /* uvc_error_t */ uvc_uyvy2bgr(uvc_frame_t *in, uvc_frame_t *out);
int /* uvc_error_t */ uvc_any2bgr(uvc_frame_t *in, uvc_frame_t *out);

int /* uvc_error_t */ uvc_yuyv2y(uvc_frame_t *in, uvc_frame_t *out);
int /* uvc_error_t */ uvc_yuyv2uv(uvc_frame_t *in, uvc_frame_t *out);
]]

if LIBUVC_HAS_JPEG then
ffi.cdef[[
int /* uvc_error_t */ uvc_mjpeg2rgb(uvc_frame_t *in, uvc_frame_t *out);
]]
end

--[[
  This could be made to platform independent
--]]
local success, Lib_uvc = pcall(function() return ffi.load("uvc") end )

return Lib_uvc
