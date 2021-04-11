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
# If portaudio_STATIC is TRUE then static linking will be assumed
#

# function(dump_cmake_variables)
#   get_cmake_property(_variableNames VARIABLES)
#   list (SORT _variableNames)
#   foreach (_variableName ${_variableNames})
#     if (ARGV0)
#       unset(MATCHED)
#       string(REGEX MATCH ${ARGV0} MATCHED ${_variableName})
#       if (NOT MATCHED)
#         continue()
#       endif()
#     endif()
#     message(STATUS "${_variableName}=${${_variableName}}")
#   endforeach()
# endfunction()

include (LibFindMacros)

libfind_pkg_detect (portaudio portaudio-2.0 FIND_PATH portaudio.h FIND_LIBRARY portaudio)
set (portaudio_PROCESS_LIBS portaudio_PKGCONF_LDFLAGS)
libfind_process (portaudio)

#dump_cmake_variables ("^portaudio_")

if (portaudio_FOUND AND NOT TARGET portaudio::portaudio)
  add_library (portaudio::portaudio UNKNOWN IMPORTED)
  set_target_properties (portaudio::portaudio PROPERTIES
    IMPORTED_LOCATION "${portaudio_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${portaudio_CFLAGS_OTHERS}"
    INTERFACE_INCLUDE_DIRECTORIES "${portaudio_INCLUDE_DIRS}"
    INTERFACE_LINK_LIBRARIES "${portaudio_LIBRARIES}"
    )
endif ()

mark_as_advanced (
  portaudio_INCLUDE_DIR
  portaudio_LIBRARY
  )
