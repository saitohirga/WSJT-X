# Findlibusb
# ==========
#
# Find the usb library
#
# This will define the following variables::
#
#  libusb_FOUND		- True if the system has the usb library
#  libusb_VERSION	- The verion of the usb library which was found
#
# and the following imported targets::
#
#  libusb::libusb	- The libusb library
#

if (WIN32)
  # Use path suffixes on MS Windows as we probably shouldn't
  # trust the PATH envvar. PATH will still be searched to find the
  # library as last resort.
  if (CMAKE_SIZEOF_VOID_P MATCHES "8")
    set (_library_options PATH_SUFFIXES MinGW64/dll MinGW64/static)
  else ()
    set (_library_options PATH_SUFFIXES MinGW32/dll MinGW32/static)
  endif ()
endif ()
libfind_pkg_detect (libusb libusb-1.0
  FIND_PATH libusb.h PATH_SUFFIXES libusb-1.0
  FIND_LIBRARY libusb-1.0 ${_library_options}
  )

libfind_process (libusb)

if (libusb_FOUND AND NOT TARGET libusb::libusb)
  add_library (libusb::libusb UNKNOWN IMPORTED)
  set_target_properties (libusb::libusb PROPERTIES
    IMPORTED_LOCATION "${libusb_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${libusb_PKGCONF_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${libusb_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${libusb_LIBRARIES}"
    )
endif ()

mark_as_advanced (
  libusb_INCLUDE_DIR
  libusb_LIBRARY
  libusb_LIBRARIES
  )
