# - Try to find hamlib
# Once done, this will define:
#
#  hamlib_FOUND - system has Hamlib-2
#  hamlib_INCLUDE_DIRS - the Hamlib-2 include directories
#  hamlib_LIBRARIES - link these to use Hamlib-2

include (LibFindMacros)

# Use pkg-config to get hints about paths
libfind_pkg_check_modules (hamlib_PKGCONF hamlib)

# Include dirs
find_path (hamlib_INCLUDE_DIR
  NAMES hamlib/rig.h
  PATHS ${hamlib_PKGCONF_INCLUDE_DIRS}
)

# The library
find_library (hamlib_LIBRARY
  NAMES hamlib hamlib-2
  PATHS ${hamlib_PKGCONF_LIBRARY_DIRS}
)

# Set the include dir variables and the libraries and let libfind_process do the rest
set (hamlib_PROCESS_INCLUDES hamlib_INCLUDE_DIR)
set (hamlib_PROCESS_LIBS hamlib_LIBRARY)
libfind_process (hamlib)
