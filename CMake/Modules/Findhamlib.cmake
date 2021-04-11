# - Try to find hamlib
#
# Once done, this will define:
#
#  hamlib_FOUND - system has Hamlib
#  hamlib_INCLUDE_DIRS - the Hamlib include directories
#  hamlib_LIBRARIES - link these to use Hamlib
#  hamlib_LIBRARY_DIRS - required shared/dynamic libraries are here
#
# If hamlib_STATIC is TRUE then static linking will be assumed
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

libfind_pkg_detect (hamlib hamlib FIND_PATH hamlib/rig.h PATH_SUFFIXES hamlib FIND_LIBRARY hamlib)
libfind_package (hamlib libusb)
if (hamlib_STATIC)
  if (hamlib_PKGCONF_FOUND)
    set (hamlib_PROCESS_LIBS hamlib_PKGCONF_STATIC_LIBRARY)
  else ()
  endif ()
else ()
  if (hamlib_PKGCONF_FOUND)
    set (hamlib_PROCESS_LIBS hamlib_PKGCONF_LIBRARY)
  else ()
  endif ()
endif ()
libfind_process (hamlib)

if (NOT hamlib_PKGCONF_FOUND)
  if (WIN32)
    set (hamlib_LIBRARIES ${hamlib_LIBRARIES};ws2_32)
  else ()
    set (hamlib_LIBRARIES ${hamlib_LIBRARIES};m;dl)
  endif ()
endif ()
