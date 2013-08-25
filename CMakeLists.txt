cmake_minimum_required (VERSION 2.8.9)

project (wsjtx C CXX Fortran)

set (WSJTX_VERSION_MAJOR 1)
set (WSJTX_VERSION_MINOR 2)

if (POLICY CMP0020)
  cmake_policy (SET CMP0020 NEW) # link to Qt winmain on Windows
endif (POLICY CMP0020)

# make sure that the default is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)
endif (NOT CMAKE_BUILD_TYPE)


#
# C++ setup
#

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")


set (CXXSRCS
  logbook/adif.cpp
  logbook/countrydat.cpp
  logbook/countriesworked.cpp
  logbook/logbook.cpp
  rigclass.cpp
  psk_reporter.cpp
  Modulator.cpp
  Detector.cpp
  logqso.cpp
  displaytext.cpp
  decodedtext.cpp
  getfile.cpp
  soundout.cpp
  soundin.cpp
  meterwidget.cpp
  signalmeter.cpp
  plotter.cpp
  widegraph.cpp
  devsetup.cpp
  about.cpp
  mainwindow.cpp
  main.cpp
  )

if (WIN32)
  set (CXXSRCS ${CXXSRCS} killbyname.cpp)
endif (WIN32)

set_property (SOURCE ${CXXSRCS} APPEND PROPERTY COMPILE_FLAGS "-include wsjtx_config.h")

set (UISRCS
  mainwindow.ui
  about.ui
  devsetup.ui
  widegraph.ui
  logqso.ui
)

#
# sort out pre-requisites
#

#
# libfftw3 setup
#
find_path (fftw3f_INCLUDES fftw3.f)
find_library (fftw3f NAMES fftw3f fftw3f-3)
include_directories (${fftw3f_INCLUDES})

#
# libhamlib setup
#
find_path (hamlib_INCLUDES hamlib/rig.h)
find_library (hamlib NAMES hamlib hamlib-2)
find_library (usb NAMES usb0)
find_path (hamlib-runtime-path libhamlib-2.dll)
file (GLOB hamlib-backends ${hamlib-runtime-path}/hamlib*.dll)
include_directories (${hamlib_INCLUDES})


#
# Qt5 setup
#

# Widgets finds its own dependencies.
find_package (Qt5Widgets REQUIRED)
find_package (Qt5Multimedia REQUIRED)

# Tell CMake to run moc when necessary
set (CMAKE_AUTOMOC ON)

# don't use Qt "keywords" signal, slot, emit in generated files to
# avoid compatability issue with other libraries
#ADD_DEFINITIONS (-DQT_NO_KEYWORDS)

# As moc files are generated in the binary dir, tell CMake to always
# look for includes there:
set (CMAKE_INCLUDE_CURRENT_DIR ON)

# project definitions
add_definitions (-DQT5)
if (CMAKE_HOST_UNIX)
  add_definitions (-DUNIX)
elseif (CMAKE_HOST_WIN32)
  add_definitions (-DWIN32)
endif ()

# add_definitions (-DWSJT_SOFT_KEYING)
set_property (DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS_RELEASE QT_NO_DEBUG_OUTPUT QT_NO_WARNING_OUTPUT)


#
# build the subdirectories
#
add_subdirectory (lib)


#
# fetch kvasd
#
if (APPLE)
  set (kvasd_NAME http://svn.berlios.de/wsvn/wsjt/trunk/KVASD_gfortran_Mac${CMAKE_EXECUTABLE_SUFFIX})
else ()
  set (kvasd_NAME http://www.physics.princeton.edu/pulsar/K1JT/kvasd${CMAKE_EXECUTABLE_SUFFIX})
endif ()
file (
  DOWNLOAD ${kvasd_NAME} contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX}
  STATUS kvasd_STATUS
  LOG kvasd_LOG
  SHOW_PROGRESS
  )
message (${kvasd_LOG})
list (GET kvasd_STATUS 0 kvasd_RC)
if (!kvasd_RC)
  message (FATAL_ERROR "${kvasd_STATUS}")
endif (!kvasd_RC)
add_custom_target (kvasd DEPENDS contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX})


# UI generation
qt5_wrap_ui (GENUISRCS ${UISRCS})

add_executable (wsjtx ${CXXSRCS} ${GENUISRCS} wsjtx.rc)
target_link_libraries (wsjtx jt9impl ${hamlib} ${fftw3f})
if (WIN32)
  target_link_libraries (wsjtx ${CMAKE_CURRENT_SOURCE_DIR}/libHRDInterface001.a)
endif (WIN32)
add_dependencies (wsjtx hamlib kvasd)
qt5_use_modules (wsjtx Widgets Multimedia OpenGL)


install (
  TARGETS wsjtx
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  )

install (DIRECTORY Palettes DESTINATION bin PATTERN *.pal)
install (DIRECTORY samples DESTINATION bin/save)

install (
  PROGRAMS ${CMAKE_BINARY_DIR}/contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX}
  DESTINATION bin
)

install (
  FILES WSJT-X_Users_Guide_v${WSJTX_VERSION_MAJOR}.${WSJTX_VERSION_MINOR}.docx
  DESTINATION bin
  )

if (WIN32)
  install (
    FILES ${hamlib} ${hamlib-backends} ${fftw3f} ${usb} contrib/HRDInterface001.dll
    DESTINATION bin COMPONENT Runtime
    )
endif (WIN32)


# a custom target that is always built
ADD_CUSTOM_TARGET (revisiontag ALL)

# creates svnversion.h using cmake script
ADD_CUSTOM_COMMAND (TARGET revisiontag COMMAND ${CMAKE_COMMAND}
  -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR} 
  -P ${CMAKE_CURRENT_SOURCE_DIR}/getsvn.cmake)

# explicitly say that the executable depends on custom target
add_dependencies(wsjtx revisiontag)

#
# versioning
#
configure_file (
  "${PROJECT_SOURCE_DIR}/wsjtx_config.h.in"
  "${PROJECT_BINARY_DIR}/wsjtx_config.h"
  )

include_directories ("${PROJECT_BINARY_DIR}")
