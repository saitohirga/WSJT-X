#
# Find the hamlib library
#
# This will define the following variables::
#
#  hamlib_FOUND		- True if the system has the usb library
#  hamlib_VERSION	- The verion of the usb library which was found
#
# and the following imported targets::
#
#  hamlib::hamlib	- The hamlib library
#

include (LibFindMacros)

libfind_pkg_detect (hamlib hamlib
  FIND_PATH hamlib/rig.h PATH_SUFFIXES hamlib
  FIND_LIBRARY hamlib
  )

libfind_package (hamlib libusb)

libfind_process (hamlib)

if (NOT hamlib_PKGCONF_FOUND)
  if (WIN32)
    set (hamlib_LIBRARIES ${hamlib_LIBRARIES};ws2_32)
  else ()
    set (hamlib_LIBRARIES ${hamlib_LIBRARIES};m;dl)
  endif ()
endif ()

if (hamlib_FOUND AND NOT TARGET hamlib::hamlib)
  add_library (hamlib::hamlib UNKNOWN IMPORTED)
  set_target_properties (hamlib::hamlib PROPERTIES
    IMPORTED_LOCATION "${hamlib_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${hamlib_PKGCONF_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${hamlib_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${hamlib_LIBRARIES}"
    )
endif ()

mark_as_advanced (
  hamlib_INCLUDE_DIR
  hamlib_LIBRARY
  hamlib_LIBRARIES
  )
