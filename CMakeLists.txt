cmake_minimum_required (VERSION 2.8.9 FATAL_ERROR)

project (wsjtx C CXX Fortran)

set (WSJTX_COPYRIGHT "Copyright (C) 2001-2014 by Joe Taylor, K1JT")

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/CMake/Modules)

include (${PROJECT_SOURCE_DIR}/CMake/VersionCompute.cmake)


#
# Options & features
#
#	Some of these directly effect compilation by being defined in
#	wsjtx_config.h.in which makes them available to the C/C++
#	pre-processor.
#
option (UPDATE_TRANSLATIONS "Update source translation translations/*.ts
files (WARNING: make clean will delete the source .ts files! Danger!)")
option (WSJT_SHARED_RUNTIME "Debugging option that allows running from a shared Cloud directory.")
option (WSJT_QDEBUG_IN_RELEASE "Leave qDebug statements in Release configuration.")
option (WSJT_TRACE_CAT "Debugging option that turns on CAT diagnostics.")
option (WSJT_TRACE_CAT_POLLS "Debugging option that turns on CAT diagnostics during polling.")
option (WSJT_HAMLIB_TRACE "Debugging option that turns on full Hamlib internal diagnostics.")
option (WSJT_STANDARD_FILE_LOCATIONS "All non-installation files located in \"Standard\" platfom specific locations." ON)
option (WSJT_SOFT_KEYING "Apply a ramp to CW keying envelope to reduce transients." ON)


#
# install locations
#
set (WSJT_BIN_DESTINATION bin)
set (WSJT_LIB_DESTINATION lib)
set (WSJT_SHARE_DESTINATION share/wsjtx)
set (WSJT_DOC_DESTINATION share/wsjtx/doc)
set (WSJT_PLUGIN_DESTINATION lib/plugins)
set (WSJT_QT_CONF_DESTINATION bin)


#
# project information
#
set (PROJECT_HOMEPAGE "http://www.physics.princeton.edu/pulsar/K1JT/wsjtx.html")
set (PROJECT_MANUAL "http://www.physics.princeton.edu/pulsar/K1JT/wsjtx-doc/wsjtx-main-toc2.html")


#
# Project sources
#
set (wsjt_qt_CXXSRCS
  NetworkServerLookup.cpp
  revision_utils.cpp
  WFPalette.cpp
  Radio.cpp
  Bands.cpp
  FrequencyList.cpp
  StationList.cpp
  FrequencyLineEdit.cpp
  FrequencyItemDelegate.cpp
  ForeignKeyDelegate.cpp
  LiveFrequencyValidator.cpp
  GetUserId.cpp
  TraceFile.cpp
  AudioDevice.cpp
  Transceiver.cpp
  TransceiverBase.cpp
  EmulateSplitTransceiver.cpp
  TransceiverFactory.cpp
  PollingTransceiver.cpp
  HamlibTransceiver.cpp
  HRDTransceiver.cpp
  DXLabSuiteCommanderTransceiver.cpp
  )

set (ConfigTest_CXXSRCS
  Configuration.cpp
  TestConfiguration.cpp
  ConfigTest.cpp
  )

set (jt9_CXXSRCS
  lib/ipcomm.cpp
  )

set (wsjtx_CXXSRCS
  logbook/adif.cpp
  logbook/countrydat.cpp
  logbook/countriesworked.cpp
  logbook/logbook.cpp
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
  about.cpp
  astro.cpp
  mainwindow.cpp
  Configuration.cpp
  main.cpp
  )

if (WIN32)
  set (ConfigTest_CXXSRCS
    ${ConfigTest_CXXSRCS}
    OmniRigTransceiver.cpp
    )

  set (wsjt_CXXSRCS
    ${wsjt_CXXSRCS}
    killbyname.cpp
    )

  set (wsjt_qt_CXXSRCS
    ${wsjt_qt_CXXSRCS}
    OmniRigTransceiver.cpp
    )
endif (WIN32)

set (wsjt_FSRCS
  lib/afc65b.f90
  lib/afc9.f90
  lib/analytic.f90
  lib/astro.f90
  lib/astrosub.f90
  lib/astro0.f90
  lib/azdist.f90
  lib/baddata.f90
  lib/ccf2.f90
  lib/ccf65.f90
  lib/chkhist.f90
  lib/chkss2.f90
  lib/coord.f90
  lib/db.f90
  lib/dcoord.f90
  lib/decode65a.f90
  lib/decode65b.f90
  lib/decode9.f90
  lib/decoder.f90
  lib/deg2grid.f90
  lib/demod64a.f90
  lib/determ.f90
  lib/dot.f90
  lib/downsam9.f90
  lib/encode232.f90
  lib/entail.f90
  lib/extract.F90
  lib/geocentric.f90
  lib/f77_wisdom.f90
  lib/fano232.f90
  lib/fchisq.f90
  lib/fchisq65.f90
  lib/fil3.f90
  lib/fil4.f90
  lib/fil6521.f90
  lib/filbig.f90
  lib/fillcom.f90
  lib/flat1.f90
  lib/flat2.f90
  lib/flat3.f90
  lib/flat65.f90
  lib/four2a.f90
  lib/gen65.f90
  lib/genjt9.f90
  lib/geodist.f90
  lib/getlags.f90
  lib/getpfx1.f90
  lib/getpfx2.f90
  lib/graycode.f90
  lib/graycode65.f90
  lib/grid2deg.f90
  lib/grid2k.f90
  lib/grid2n.f90
  lib/indexx.f90
  lib/interleave63.f90
  lib/interleave9.f90
  lib/jt65a.f90
  lib/k2grid.f90
  lib/moon2.f90
  lib/moondop.f90
  lib/morse.f90
  lib/move.f90
  lib/n2grid.f90
  lib/nchar.f90
  lib/options.f90
  lib/packbits.f90
  lib/packcall.f90
  lib/packgrid.f90
  lib/packmsg.f90
  lib/packtext.f90
  lib/pctile.f90
  lib/peakdt9.f90
  lib/pfxdump.f90
  lib/polfit.f90
  lib/prog_args.f90
  lib/sec_midn.f90
  lib/setup65.f90
  lib/sleep_msec.f90
  lib/smo.f90
  lib/smo121.f90
  lib/softsym.f90
  lib/sort.f90
  lib/ssort.f90
  lib/stdmsg.f90
  lib/sun.f90
  lib/symspec.f90
  lib/symspec2.f90
  lib/symspec65.f90
  lib/sync9.f90
  lib/timer.f90
  lib/tm2.f90
  lib/toxyz.f90
  lib/twkfreq.f90
  lib/twkfreq65.f90
  lib/unpackbits.f90
  lib/unpackcall.f90
  lib/unpackgrid.f90
  lib/unpackmsg.f90
  lib/unpacktext.f90
  lib/zplot9.f90
  )

set (wsjt_CSRCS
  lib/decode_rs.c
  lib/encode_rs.c
  lib/gran.c
  lib/igray.c
  lib/init_rs.c
  lib/tmoonsub.c
  lib/usleep.c
  lib/wrapkarn.c
  )

set (ConfigTest_UISRCS
  TestConfiguration.ui
  Configuration.ui
  )

set (wsjt_qt_UISRCS
  wf_palette_design_dialog.ui
  )

set (wsjtx_UISRCS
  mainwindow.ui
  about.ui
  astro.ui
  widegraph.ui
  logqso.ui
  Configuration.ui
  )

set (all_C_and_CXXSRCS
  ${wsjt_CSRCS}
  ${wsjt_CXXSRCS}
  ${wsjt_qt_CXXSRCS}
  ${jt9_CXXSRCS}
  ${ConfigTest_CXXSRCS}
  ${wsjtx_CXXSRCS}
  )

if (APPLE)
  set (WSJTX_ICON_FILE ${CMAKE_PROJECT_NAME}.icns)
  set (ICONSRCS
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_16x16.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_16x16@2x.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_32x32.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_32x32@2x.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_128x128.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_128x128@2x.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_256x256.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_256x256@2x.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_512x512.png
    icons/Darwin/${CMAKE_PROJECT_NAME}.iconset/icon_512x512@2x.png
    )
  add_custom_command (
    OUTPUT ${WSJTX_ICON_FILE}
    COMMAND iconutil -c icns --output "${CMAKE_BINARY_DIR}/${WSJTX_ICON_FILE}" "${CMAKE_SOURCE_DIR}/icons/Darwin/${CMAKE_PROJECT_NAME}.iconset"
    DEPENDS ${ICONSRCS}
    COMMENT "Building Icons"
    )
endif (APPLE)

set_source_files_properties (${WSJTX_ICON_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

if (NOT WSJT_QDEBUG_IN_RELEASE)
  set_directory_properties (PROPERTIES COMPILE_DEFINITIONS_RELEASE "QT_NO_DEBUG_OUTPUT;QT_NO_WARNING_OUTPUT")
  set_directory_properties (PROPERTIES COMPILE_DEFINITIONS_MINSIZEREL "QT_NO_DEBUG_OUTPUT;QT_NO_WARNING_OUTPUT")
endif (NOT WSJT_QDEBUG_IN_RELEASE)

set_property (SOURCE ${all_C_and_CXXSRCS} APPEND PROPERTY COMPILE_FLAGS "-include wsjtx_config.h")
set_property (SOURCE ${all_C_and_CXXSRCS} APPEND PROPERTY OBJECT_DEPENDS wsjtx_config.h)

if (WIN32)
  # generate the OmniRig COM interface source
  find_program (DUMPCPP dumpcpp)
  if (DUMPCPP-NOTFOUND)
    message (FATAL_ERROR "dumpcpp tool not found")
  endif (DUMPCPP-NOTFOUND)
  execute_process (
    COMMAND ${DUMPCPP} -getfile {4FE359C5-A58F-459D-BE95-CA559FB4F270}
    OUTPUT_VARIABLE AXSERVER
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  string (STRIP "${AXSERVER}" AXSERVER)
  if (NOT AXSERVER)
    message (FATAL_ERROR "You need to install OmniRig on this computer")
  endif (NOT AXSERVER)
  string (REPLACE "\"" "" AXSERVER ${AXSERVER})
  file (TO_CMAKE_PATH ${AXSERVER} AXSERVERSRCS)
endif (WIN32)

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
# decide on platform specifc packing and fixing up
#
if (APPLE)
  set (WSJTX_BUNDLE_VERSION ${wsjtx_VERSION})

  # make sure CMAKE_INSTALL_PREFIX ends in /
  string (LENGTH "${CMAKE_INSTALL_PREFIX}" LEN)
  math (EXPR LEN "${LEN} -1" )
  string (SUBSTRING "${CMAKE_INSTALL_PREFIX}" ${LEN} 1 ENDCH)
  if (NOT "${ENDCH}" STREQUAL "/")
    set (CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/")
  endif ()
  # install inside bundle
  # set (CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}wsjtx.app")

  set (WSJT_PLUGIN_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/PlugIns)
  set (WSJT_QT_CONF_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/Resources)
  set (WSJT_SHARE_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/Resources)
  set (WSJT_BIN_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/MacOS)
endif (APPLE)

#set (QT_NEED_RPATH FALSE)
#if (NOT "${QT_LIBRARY_DIR}" STREQUAL "/lib" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/usr/lib" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/lib64" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/usr/lib64")
#  set (QT_NEED_RPATH TRUE)
#endif ()


#
# C & C++ setup
#
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -std=c++11 -fexceptions -frtti")
if (WIN32)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-keep-inline-dllexport")
endif (WIN32)
if (APPLE)
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
else (APPLE)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
endif (APPLE)


#
# Fortran setup
#
set (General_FFLAGS "-fbounds-check -Wall -Wno-conversion -fno-second-underscore")

# FFLAGS depend on the compiler
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)

if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  # gfortran
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g ${General_FFLAGS}")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*")
  # ifort (untested)
  set (CMAKE_Fortran_FLAGS_RELEASE "-f77rtl -O3 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-f77rtl -O0 -g ${General_FFLAGS}")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  # g77
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3 -m32 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g -m32 ${General_FFLAGS}")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "-O2 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-O0 -g ${General_FFLAGS}")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")


#
# setup and test Fortran C/C++ interaction
#

include (FortranCInterface)
FortranCInterface_VERIFY (CXX QUIET)
FortranCInterface_HEADER (FC.h MACRO_NAMESPACE "FC_" SYMBOL_NAMESPACE "FC_"
  SYMBOLS )


#
# sort out pre-requisites
#

#
# Setup RPATH so that built executable targets will run in both the
# build tree and the install location without having to set a
# (DYLD|LD)_LIBRARY_PATH override.
#

# use the full RPATH of the build tree
set (CMAKE_SKIP_BUILD_RPATH FALSE)

# when building, don't use the install RPATH, it will still be used
# later on in the install phase
set (CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

set (CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}")

# add the automaticaly determined parts of the RPATH which point to
# directories outside of the build tree to the install RPATH
set (CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# the RPATH to be used when installing, but only if it's not a system
# directory
list (FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}" isSystemDir)
if ("${isSystemDir}" STREQUAL "-1")
  set (CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}")
endif ("${isSystemDir}" STREQUAL "-1")


#
# fftw3 single precsion library
#
find_package (FFTW3 COMPONENTS single REQUIRED)
include_directories (${FFTW3_INCLUDE_DIRS})

#
# libhamlib setup
#
find_package (hamlib 3 REQUIRED)
include_directories (${hamlib_INCLUDE_DIRS})
if (hamlib_STATIC_LIBRARY)
  # static link hamlib if archive library available
  set (hamlib_LIBRARY "${hamlib_STATIC_LIBRARY}")
  set (hamlib_LIBRARIES "${hamlib_STATIC_LIBRARIES}")
endif ()

message (STATUS "hamlib_INCLUDE_DIRS: ${hamlib_INCLUDE_DIRS}")
message (STATUS "hamlib_LIBRARY: ${hamlib_LIBRARY}")
message (STATUS "hamlib_LIBRARIES: ${hamlib_LIBRARIES}")
message (STATUS "hamlib_STATIC_LIBRARY: ${hamlib_STATIC_LIBRARY}")
message (STATUS "hamlib_STATIC_LIBRARIES: ${hamlib_STATIC_LIBRARIES}")

# if (WIN32)
#   find_library (hamlib_RUNTIME NAMES hamlib hamlib-2 PATH_SUFFIXES bin)
#   get_filename_component (_hamlib_runtime_path "${hamlib_RUNTIME}" PATH)
#   file (GLOB hamlib_BACKENDS ${_hamlib_runtime_path}/hamlib*.dll)
#   find_library (usb_RUNTIME NAMES usb0 PATH_SUFFIXES bin)
# endif (WIN32)


#
# Qt5 setup
#

# Widgets finds its own dependencies.
find_package (Qt5Widgets 5 REQUIRED)
find_package (Qt5Multimedia 5 REQUIRED)

if (WIN32)
  add_definitions (-DQT_NEEDS_QTMAIN)
  find_package (Qt5AxContainer REQUIRED)
endif (WIN32)

#
# stuff only qmake can tell us
#
get_target_property (QMAKE_EXECUTABLE Qt5::qmake LOCATION)
function (QUERY_QMAKE VAR RESULT)
  exec_program (${QMAKE_EXECUTABLE} ARGS "-query ${VAR}" RETURN_VALUE return_code OUTPUT_VARIABLE output)
  if (NOT return_code)
    file (TO_CMAKE_PATH "${output}" output)
    set (${RESULT} ${output} PARENT_SCOPE)
  endif (NOT return_code)
  message (STATUS "Asking qmake for ${RESULT} and got ${output}")
endfunction (QUERY_QMAKE)

query_qmake (QT_INSTALL_PLUGINS QT_PLUGINS_DIR)
query_qmake (QT_INSTALL_IMPORTS QT_IMPORTS_DIR)
query_qmake (QT_HOST_DATA QT_DATA_DIR)
set (QT_MKSPECS_DIR ${QT_DATA_DIR}/mkspecs)

# Tell CMake to run moc when necessary
set (CMAKE_AUTOMOC ON)

# don't use Qt "keywords" signal, slot, emit in generated files to
# avoid compatability issue with other libraries
# ADD_DEFINITIONS (-DQT_NO_KEYWORDS)
# ADD_DEFINITIONS (-DUNICODE)	#as per qmake

# As moc files are generated in the binary dir, tell CMake to always
# look for includes there:
set (CMAKE_INCLUDE_CURRENT_DIR ON)

# project definitions
add_definitions (-DQT5 -DCMAKE_BUILD -DBIGSYM=1)
if (CMAKE_HOST_UNIX)
  add_definitions (-DUNIX)
elseif (CMAKE_HOST_WIN32)
  add_definitions (-DWIN32)
endif ()


#
# fetch and validate kvasd
#
add_custom_command (
  OUTPUT contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_COMMAND} -D SYSTEM_NAME=${CMAKE_SYSTEM_NAME} -D EXECUTABLE_SUFFIX=${CMAKE_EXECUTABLE_SUFFIX} -P ${CMAKE_SOURCE_DIR}/CMake/download_kvasd.cmake
  DEPENDS CMake/download_kvasd.cmake
  COMMENT "Downloading kvasd for ${CMAKE_SYSTEM_NAME}"
  VERBATIM
  )


# UI generation
qt5_wrap_ui (wsjt_qt_GENUISRCS ${wsjt_qt_UISRCS})
qt5_wrap_ui (ConfigTest_GENUISRCS ${ConfigTest_UISRCS})
qt5_wrap_ui (wsjtx_GENUISRCS ${wsjtx_UISRCS})

# Resource generation
qt5_add_resources (wsjtx_RESOURCES_RCC wsjtx.qrc)

# AX COM servers
if (WIN32)
  include (QtAxMacros)
  wrap_ax_server (GENAXSRCS ${AXSERVERSRCS})
endif (WIN32)


#
# targets
#

# build a library of package functionality
add_library (wsjt STATIC ${wsjt_CSRCS} ${wsjt_CXXSRCS} ${wsjt_FSRCS})

# build a library of package Qt functionality
add_library (wsjt_qt STATIC ${wsjt_qt_CXXSRCS} ${wsjt_qt_GENUISRCS} ${GENAXSRCS})
qt5_use_modules (wsjt_qt Widgets OpenGL Network)
if (WIN32)
  qt5_use_modules (wsjt_qt AxContainer AxBase)
endif (WIN32)

add_executable (jt9sim lib/jt9sim.f90 wsjtx.rc)
target_link_libraries (jt9sim wsjt)

add_executable (jt9code lib/jt9code.f90 wsjtx.rc)
target_link_libraries (jt9code wsjt)

add_executable (jt9 lib/jt9.f90 lib/jt9a.f90 lib/jt9b.f90 lib/jt9c.f90 ${jt9_CXXSRCS} wsjtx.rc)
target_link_libraries (jt9 wsjt ${FFTW3_LIBRARIES})
qt5_use_modules (jt9 Core)

# build configuration dialog and transceiver interface test application
#add_executable (ConfigTest ${ConfigTest_CXXSRCS} ${ConfigTest_GENUISRCS} wsjtx.rc)
#target_link_libraries (ConfigTest wsjt wsjt_qt ${hamlib_LIBRARIES})
#qt5_use_modules (ConfigTest Widgets OpenGL Network Multimedia)

# build the main application
add_executable (wsjtx WIN32 MACOSX_BUNDLE ${wsjtx_CXXSRCS} ${wsjtx_GENUISRCS} wsjtx.rc ${WSJTX_ICON_FILE} ${wsjtx_RESOURCES_RCC} contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX})
qt5_use_modules (wsjtx Widgets OpenGL Network Multimedia)

set_target_properties (wsjtx PROPERTIES
  MACOSX_BUNDLE_INFO_STRING "${WSJTX_DESCRIPTION_SUMMARY}"
  MACOSX_BUNDLE_ICON_FILE "${WSJTX_ICON_FILE}"
  MACOSX_BUNDLE_BUNDLE_VERSION ${wsjtx_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING "v${wsjtx_VERSION}"
  MACOSX_BUNDLE_LONG_VERSION_STRING "Version ${wsjtx_VERSION}"
  MACOSX_BUNDLE_BUNDLE_NAME "WSJT-X"
  MACOSX_BUNDLE_COPYRIGHT "${WSJTX_COPYRIGHT}"
  )

target_link_libraries (wsjtx wsjt wsjt_qt ${hamlib_LIBRARIES} ${FFTW3_LIBRARIES})

if (WIN32)
  set_target_properties (
    wsjtx
    # ConfigTest
    PROPERTIES LINK_FLAGS_RELEASE "${LINKER_FLAGS_RELEASE} -mwindows"
    )
endif (WIN32)


#
# installation
#
install (TARGETS wsjtx
  RUNTIME DESTINATION ${WSJT_BIN_DESTINATION}
  LIBRARY DESTINATION ${WSJT_LIB_DESTINATION}
  BUNDLE DESTINATION .
  # COMPONENT Runtime
  )

install (TARGETS jt9
  RUNTIME DESTINATION ${WSJT_BIN_DESTINATION}
  LIBRARY DESTINATION ${WSJT_LIB_DESTINATION}
  BUNDLE DESTINATION ${WSJT_BIN_DESTINATION}
  #  COMPONENT Runtime
  )

install (PROGRAMS
  ${CMAKE_BINARY_DIR}/contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX}
  DESTINATION ${WSJT_BIN_DESTINATION}
  #  COMPONENT Runtime
  )


#
# uninstall support
#
configure_file (
  "${CMAKE_CURRENT_SOURCE_DIR}/CMake/cmake_uninstall.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
  @ONLY)
add_custom_target (uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")


# creates svnversion.h using cmake script
add_custom_target (revisiontag
  COMMAND ${CMAKE_COMMAND} -D SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR} -D OUTPUT_DIR=${PROJECT_BINARY_DIR} -P ${CMAKE_CURRENT_SOURCE_DIR}/CMake/getsvn.cmake
  COMMENT "Generating Subversion revision information"
  VERBATIM
  )
# explicitly say that the executable depends on custom target, this is
# done indirectly so that the revisiontag target gets built exactly
# once per build
add_dependencies(jt9 revisiontag)
add_dependencies(wsjtx revisiontag)


#
# versioning and configuration
#
configure_file (
  "${PROJECT_SOURCE_DIR}/wsjtx_config.h.in"
  "${PROJECT_BINARY_DIR}/wsjtx_config.h"
  )
include_directories ("${PROJECT_BINARY_DIR}")


if (NOT WIN32 AND NOT APPLE)
  # install a desktop file so wsjtx appears in the application start
  # menu with an icon
  install (FILES wsjtx.desktop DESTINATION share/applications)
  install (FILES icons/Unix/wsjtx_icon.png DESTINATION share/pixmaps)
endif (NOT WIN32 AND NOT APPLE)


#
# bundle fixup only done in Release or MinSizeRel configurations
#
if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")

  # get_target_property (QtCore_location Qt5::Core LOCATION)
  # get_filename_component (QtCore_location ${QtCore_location} PATH)
  # list (APPEND fixup_library_dirs ${QtCore_location})

  if (APPLE)
    set (CMAKE_POSTFLIGHT_SCRIPT
      "${wsjtx_BINARY_DIR}/postflight.sh")
    set (CMAKE_POSTUPGRADE_SCRIPT
      "${wsjtx_BINARY_DIR}/postupgrade.sh")
    configure_file ("${wsjtx_SOURCE_DIR}/postflight.sh.in"
      "${wsjtx_BINARY_DIR}/postflight.sh")
    configure_file ("${wsjtx_SOURCE_DIR}/postupgrade.sh.in"
      "${wsjtx_BINARY_DIR}/postupgrade.sh")
  endif ()

  if (APPLE OR WIN32)
    # install rules for including 3rd party libs such as Qt

    # install a qt.conf file
    install (CODE "
  file (WRITE \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"[Paths]
\")
" #COMPONENT Runtime
      )

    # if a system Qt is used (e.g. installed in /usr/lib/), it will not be included in the installation
    set (fixup_exe "\${CMAKE_INSTALL_PREFIX}/${WSJT_BIN_DESTINATION}/${CMAKE_PROJECT_NAME}${CMAKE_EXECUTABLE_SUFFIX}")
    #get_filename_component (hamlib_lib_dir ${hamlib_LIBRARIES} PATH)

    if (APPLE)
      # install required Qt plugins
      install (
	DIRECTORY
	${QT_PLUGINS_DIR}/platforms
	${QT_PLUGINS_DIR}/audio
	DESTINATION ${WSJT_PLUGIN_DESTINATION}
	CONFIGURATIONS Release MinSizeRel
	#      COMPONENT Runtime
	FILES_MATCHING PATTERN "*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*_debug${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	)
      # install (
      # 	DIRECTORY
      # 	${QT_PLUGINS_DIR}/platforms
      # 	${QT_PLUGINS_DIR}/audio
      # 	DESTINATION ${WSJT_PLUGIN_DESTINATION}
      # 	CONFIGURATIONS Debug
      # 	#      COMPONENT Runtime
      # 	FILES_MATCHING PATTERN "*_debug${CMAKE_SHARED_LIBRARY_SUFFIX}"
      # 	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	)

      # add plugins path for Mac Bundle
      install (CODE "
file (APPEND \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"Plugins = Plugins
\")
" #COMPONENT Runtime
	)
    endif (APPLE)

    if (WIN32)
      # DLL directory
      #set (hamlib_lib_dir ${hamlib_lib_dir}/../bin)

      get_filename_component (fftw_lib_dir ${FFTW3F_LIBRARY} PATH)
      list (APPEND fixup_library_dirs ${fftw_lib_dir})

      # install required Qt plugins
      install (
	DIRECTORY
	${QT_PLUGINS_DIR}/platforms
	DESTINATION ${WSJT_PLUGIN_DESTINATION}
	CONFIGURATIONS Release MinSizeRel
	#      COMPONENT Runtime
	FILES_MATCHING PATTERN "*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*d${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	)
      # install (
      # 	DIRECTORY
      # 	${QT_PLUGINS_DIR}/platforms
      # 	DESTINATION ${WSJT_PLUGIN_DESTINATION}
      # 	CONFIGURATIONS Debug
      # 	#      COMPONENT Runtime
      # 	FILES_MATCHING PATTERN "*d${CMAKE_SHARED_LIBRARY_SUFFIX}"
      # 	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	)

      # add plugins path for WIN32
      file (RELATIVE_PATH _plugins_path "${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}" "${CMAKE_INSTALL_PREFIX}/${WSJT_PLUGIN_DESTINATION}")
      install (CODE "
file (APPEND \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"Plugins = ${_plugins_path}
\")
" #COMPONENT Runtime
	)

      # set (gp_tool "objdump")	# we want MinGW tool - not MSVC (See GetPrerequisites.cmake)
    endif (WIN32)

    #list (APPEND fixup_library_dirs ${hamlib_lib_dir})
    list (APPEND fixup_library_dirs ${hamlib_LIBRARY_DIRS})

    install (CODE "
     file (GLOB_RECURSE QTPLUGINS
       \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_PLUGIN_DESTINATION}/*${CMAKE_SHARED_LIBRARY_SUFFIX}\")
     include (BundleUtilities)
     set (BU_CHMOD_BUNDLE_ITEMS ON)
     set (gp_tool ${gp_tool})
     message (STATUS \"fixup_exe: ${fixup_exe}\")
     fixup_bundle (\"${fixup_exe}\" \"\${QTPLUGINS}\" \"${fixup_library_dirs}\")
   "
      #COMPONENT Runtime
      )
  endif (APPLE OR WIN32)

endif (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")


#
# packaging
#
set (CPACK_PACKAGE_NAME "${CMAKE_PROJECT_NAME}")
set (CPACK_PACKAGE_VERSION_MAJOR ${WSJTX_VERSION_MAJOR})
set (CPACK_PACKAGE_VERSION_MINOR ${WSJTX_VERSION_MINOR})
set (CPACK_PACKAGE_VERSION_PATCH ${WSJTX_VERSION_PATCH})

if (WIN32)
  set (CPACK_GENERATOR "NSIS")
elseif (APPLE)
  set (CPACK_GENERATOR "DragNDrop" "PackageMaker")
else ()
  #
  # Derive the correct filename for a Debian package because the DEB
  # generator doesn't do this correctly at present.
  #
  string (TOLOWER "${CPACK_PACKAGE_NAME}" CPACK_PACKAGE_NAME_LOWERCASE)
  find_program (DPKG_PROGRAM dpkg DOC "dpkg program of Debian-based systems")
  if (DPKG_PROGRAM)
    execute_process (
      COMMAND ${DPKG_PROGRAM} --print-architecture
      OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
      OUTPUT_STRIP_TRAILING_WHITESPACE
      )
    set (DEBIAN_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME_LOWERCASE}_${wsjtx_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")   

  else (DPKG_PROGRAM)
    set (DEBIAN_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME_LOWERCASE}_${wsjtx_VERSION}_${CMAKE_SYSTEM_NAME}")
  endif (DPKG_PROGRAM)

  set (CPACK_DEBIAN_PACKAGE_PACKAGE_SHLIBDEPS ON)

  set (CPACK_GENERATOR "DEB" "RPM" "TGZ")
endif ()

configure_file ("${PROJECT_SOURCE_DIR}/CMakeCPackOptions.cmake.in"
  "${PROJECT_BINARY_DIR}/CMakeCPackOptions.cmake" @ONLY)
set (CPACK_PROJECT_CONFIG_FILE "${PROJECT_BINARY_DIR}/CMakeCPackOptions.cmake")

include (CPack)
