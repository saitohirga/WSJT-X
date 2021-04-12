# - Try to find portaudio
#
# Once done, this will define:
#
#  portaudio_FOUND - system has portaudio
#  portaudio_VERSION - The version of the portaudio library which was found
#
# and the following imported targets::
#
#   portaudio::portaudio	- The portaudio library
#

include (LibFindMacros)

libfind_pkg_detect (portaudio portaudio-2.0
  FIND_PATH portaudio.h
  FIND_LIBRARY portaudio
  )

libfind_process (portaudio)

if (portaudio_FOUND AND NOT TARGET portaudio::portaudio)
  add_library (portaudio::portaudio UNKNOWN IMPORTED)
  set_target_properties (portaudio::portaudio PROPERTIES
    IMPORTED_LOCATION "${portaudio_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${portaudio_PKGCONF_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${portaudio_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${portaudio_PKGCONF_LDFLAGS}"
    )
endif ()

mark_as_advanced (
  portaudio_INCLUDE_DIR
  portaudio_LIBRARY
  )
