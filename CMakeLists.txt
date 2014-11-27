cmake_minimum_required (VERSION 2.8.10 FATAL_ERROR)

project (wsjtx C CXX Fortran)

#
# CMake policies
#
if (POLICY CMP0020)
  cmake_policy (SET CMP0020 NEW) # link to Qt winmain on Windows
endif (POLICY CMP0020)

if (POLICY CMP0043)
  cmake_policy (SET CMP0043 NEW) # ignore COMPILE_DEFINITIONS_<CONFIG>
endif (POLICY CMP0043)


#
# project information
#
set (PROJECT_NAME "WSJT-X")
set (PROJECT_VENDOR "Joe Taylor, K1JT")
set (PROJECT_CONTACT "Joe Taylor <k1jt@arrl.net>")
set (PROJECT_COPYRIGHT "Copyright (C) 2001-2014 by Joe Taylor, K1JT")
set (PROJECT_HOMEPAGE "http://www.physics.princeton.edu/pulsar/K1JT/wsjtx.html")
set (PROJECT_MANUAL wsjtx-main.html)
set (PROJECT_MANUAL_DIRECTORY_URL http://www.physics.princeton.edu/pulsar/K1JT/wsjtx-doc)
set (PROJECT_SUMMARY_DESCRIPTION "${PROJECT_NAME} - JT9 and JT65 Modes for LF, MF and HF Amateur Radio.")
set (PROJECT_DESCRIPTION "${PROJECT_SUMMARY_DESCRIPTION}
 ${PROJECT_NAME} implements JT9, a new mode designed especially for the LF, MF,
 and HF bands, as well as the popular mode JT65. Both modes were
 designed for making reliable, confirmed QSOs under extreme
 weak-signal conditions. They use nearly identical message structure
 and source encoding. JT65 was designed for EME (“moonbounce”) on the
 VHF/UHF bands and has also proved very effective for worldwide QRP
 communication at HF; in contrast, JT9 is optimized for HF and lower
 frequencies. JT9 is about 2 dB more sensitive than JT65A while using
 less than 10% of the bandwidth. World-wide QSOs are possible with
 power levels of a few watts and compromise antennas. A 2 kHz slice
 of spectrum is essentially full when occupied by ten JT65 signals.
 As many as 100 JT9 signals can fit into the same space, without
 overlap.
 .
 ${PROJECT_NAME} offers a “bi-lingual“ operating mode in which you can transmit
 and receive JT65 and JT9 signals, switching between modes
 automatically as needed. Displayed bandwidth can be as large as 5
 kHz. If your receiver has as upper-sideband filter at least 4 kHz
 wide, you can have all the typical JT65 and JT9 activity on screen at
 once, available for making QSOs with a click of the mouse. Even with
 standard SSB-width IF filters, switching between JT65 and JT9 modes
 is quick and convenient. Be sure to read the online ${PROJECT_NAME} User's
 Guide.")

set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/CMake/Modules)

include (${PROJECT_SOURCE_DIR}/CMake/VersionCompute.cmake)
message (STATUS "Building ${CMAKE_PROJECT_NAME}-${wsjtx_VERSION}")

# make sure that the default configuration is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)
endif (NOT CMAKE_BUILD_TYPE)
if (CMAKE_BUILD_TYPE MATCHES "[Dd][Ee][Bb][Uu][Gg]")
  set (is_debug_build 1)
endif ()


#
# Options & features
#
#	Some of these directly effect compilation by being defined in
#	wsjtx_config.h.in which makes them available to the C/C++
#	pre-processor.
#
include (CMakeDependentOption)

option (UPDATE_TRANSLATIONS "Update source translation translations/*.ts
files (WARNING: make clean will delete the source .ts files! Danger!)")
option (WSJT_SHARED_RUNTIME "Debugging option that allows running from a shared Cloud directory.")
option (WSJT_QDEBUG_TO_FILE "Redirect Qt debuging messages to a trace file.")
option (WSJT_TRACE_CAT "Debugging option that turns on CAT diagnostics.")
option (WSJT_TRACE_CAT_POLLS "Debugging option that turns on CAT diagnostics during polling.")
option (WSJT_HAMLIB_TRACE "Debugging option that turns on full Hamlib internal diagnostics.")
option (WSJT_STANDARD_FILE_LOCATIONS "All non-installation files located in \"Standard\" platfom specific locations." ON)
option (WSJT_SOFT_KEYING "Apply a ramp to CW keying envelope to reduce transients." ON)
option (WSJT_SKIP_MANPAGES "Skip *nix manpage generation.")

CMAKE_DEPENDENT_OPTION (WSJT_QDEBUG_IN_RELEASE "Leave Qt debugging statements in Release configuration." OFF
  "NOT is_debug_build" OFF)
CMAKE_DEPENDENT_OPTION (WSJT_ENABLE_EXPERIMENTAL_FEATURES "Enable features not fully ready for public releases." ON
  "is_debug_build" OFF)
CMAKE_DEPENDENT_OPTION (WSJT_CREATE_WINMAIN
  "The wsjtx target is normally built as GUI executable with a WinMain entry point on Windows,
if you want a console application instead then set this option to OFF.

If you just want to see the debug output from the application then the easiest way is to
attach a debugger which will then receive the console output inside its console." ON
  "is_debug_build;WIN32" ON)

#
# decide if we are bundling kvasd (non-FOSS)
#
CMAKE_DEPENDENT_OPTION (WSJT_INCLUDE_KVASD "Include kvasd in the package." OFF
  "NOT is_debug_build;NOT WIN32" ON)


#
# install locations
#
set (WSJT_BIN_DESTINATION bin)
set (WSJT_LIB_DESTINATION lib)
set (WSJT_SHARE_DESTINATION share)
set (WSJT_DOC_DESTINATION doc/${CMAKE_PROJECT_NAME})
set (WSJT_MANPAGE_DESTINATION share)
set (WSJT_PLUGIN_DESTINATION lib/plugins)
set (WSJT_QT_CONF_DESTINATION bin)

if (WIN32)
  set (WSJT_SHARE_DESTINATION bin)
  set (WSJT_DOC_DESTINATION doc)
  set (WSJT_PLUGIN_DESTINATION plugins)
endif (WIN32)

if (APPLE)
  set (WSJT_BIN_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/MacOS)
  set (WSJT_SHARE_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/Resources)
  set (WSJT_MANPAGE_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/Resources)
  set (WSJT_DOC_DESTINATION doc)
  set (WSJT_PLUGIN_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/PlugIns)
  set (WSJT_QT_CONF_DESTINATION ${CMAKE_PROJECT_NAME}.app/Contents/Resources)
endif (APPLE)


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
  lib/chkmsg.f90
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
  lib/fmtmsg.f90
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
  lib/wisdom.c
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

set (all_CXXSRCS
  ${wsjt_CXXSRCS}
  ${wsjt_qt_CXXSRCS}
  ${jt9_CXXSRCS}
  ${ConfigTest_CXXSRCS}
  ${wsjtx_CXXSRCS}
  )

set (all_C_and_CXXSRCS
  ${wsjt_CSRCS}
  ${all_CXXSRCS}
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
  set_property (DIRECTORY APPEND PROPERTY
    COMPILE_DEFINITIONS $<$<NOT:$<CONFIG:Debug>>:QT_NO_DEBUG_OUTPUT;QT_NO_WARNING_OUTPUT>
    )
endif (NOT WSJT_QDEBUG_IN_RELEASE)

set_property (SOURCE ${all_C_and_CXXSRCS} APPEND_STRING PROPERTY COMPILE_FLAGS " -include wsjtx_config.h")
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
endif (APPLE)


#
# C & C++ setup
#
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -std=c++11 -fexceptions -frtti")

if (NOT APPLE)
  set (CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fdata-sections -ffunction-sections")
  set (CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -fdata-sections -ffunction-sections")
  set (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fdata-sections -ffunction-sections")
  set (CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} -fdata-sections -ffunction-sections")
endif (NOT APPLE)

if (WIN32)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-keep-inline-dllexport")
endif (WIN32)
if (APPLE)
  #
  # The following variables define the portability and compatability attributes of the Mac OS X build
  # they are choosen with care and should not be changed without good cause. Note that they preclude
  # doing a default build on OS X 10.7 since there is no 10.9 SDK available for Mac OS X 10.7. This doesn't
  # preclude builds on newer versions of OS X being installed on Mac OS X 10.7, in fact it is exacty these
  # options that ensure offcial build run on 10.7 and newer versions of Mac OS X. At some point it may
  # be that some new version cannot be supported as well as 10.7, at that point the deployment target below
  # must be moved on to 10.8 and we can no longer support Mac OS X 10.7.
  #
  # Among other things these options are chosen to match the portability and compatability options of the
  # Qt framework dylibs which can be checked as follows:
  #
  # otool -l <binary> | grep -A3 LC_VERSION_MIN_MACOSX
  #
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
  set (CMAKE_OSX_DEPLOYMENT_TARGET 10.7
    CACHE STRING "Earliest version of OS X supported

Earliest version we can support with C++11 & libc++ is 10.7.
Do not override this if you intend to build an official deployable installer.")
  set (CMAKE_OSX_SYSROOT /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk
    CACHE STRING "Mac OS X SDK to build with

Change this to the newest SDK available that you can install on your system (10.9 preferred).
Do not override this if you intend to build an official deployable installer.")
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

  # CMake compiler test is supposed to do this but doesn't yet
  if (CMAKE_OSX_DEPLOYMENT_TARGET)
    set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
  endif (CMAKE_OSX_DEPLOYMENT_TARGET)
  if (CMAKE_OSX_SYSROOT)
    set (CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -isysroot ${CMAKE_OSX_SYSROOT}")
  endif (CMAKE_OSX_SYSROOT)

  set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -funroll-all-loops -fno-f2c ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "${CMAKE_Fortran_FLAGS_DEBUG} -fno-f2c ${General_FFLAGS}")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*")
  # ifort (untested)
  set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -f77rtl ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "${CMAKE_Fortran_FLAGS_DEBUG} -f77rtl ${General_FFLAGS}")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  # g77
  set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -funroll-all-loops -fno-f2c -m32 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "${CMAKE_Fortran_FLAGS_DEBUG} -fno-f2c -m32 ${General_FFLAGS}")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -O2 ${General_FFLAGS}")
  set (CMAKE_Fortran_FLAGS_DEBUG   "${CMAKE_Fortran_FLAGS_DEBUG} ${General_FFLAGS}")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")


#
# Linker setup
#
if (NOT APPLE)
  set (CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -Wl,--gc-sections")
  set (CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "${CMAKE_EXE_LINKER_FLAGS_MINSIZEREL} -Wl,--gc-sections")
endif (NOT APPLE)


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
# fetch latest HTML manual
#
set (WSJT_MANUAL_DIRECTORY "${PROJECT_MANUAL_DIRECTORY_URL}"
  CACHE STRING "Can be overridden to a local URI")
add_custom_target (user_manual ALL
  ${CMAKE_COMMAND} -D URL=${WSJT_MANUAL_DIRECTORY} -D NAME=${PROJECT_MANUAL} -P ${CMAKE_SOURCE_DIR}/CMake/download_html_manual.cmake
  COMMENT "Downloading ${PROJECT_NAME} HTML manual"
  VERBATIM
  )

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

# set (CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}")

# add the automaticaly determined parts of the RPATH which point to
# directories outside of the build tree to the install RPATH
set (CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# the RPATH to be used when installing, but only if it's not a system
# directory
# list (FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}" isSystemDir)
# if ("${isSystemDir}" STREQUAL "-1")
#   set (CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/${WSJT_LIB_DESTINATION}")
# endif ("${isSystemDir}" STREQUAL "-1")

set (QT_NEED_RPATH FALSE)
if (NOT "${QT_LIBRARY_DIR}" STREQUAL "/lib" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/usr/lib" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/lib64" AND NOT "${QT_LIBRARY_DIR}" STREQUAL "/usr/lib64")
  set (QT_NEED_RPATH TRUE)
endif ()


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
find_program (RIGCTLD_EXE rigctld)

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


if (WSJT_INCLUDE_KVASD)
  #
  # fetch and validate kvasd
  #
  set (KVASD contrib/kvasd${CMAKE_EXECUTABLE_SUFFIX})
  add_custom_target (kvasd ALL
    ${CMAKE_COMMAND} -D SYSTEM_NAME=${CMAKE_SYSTEM_NAME} -D EXECUTABLE_SUFFIX=${CMAKE_EXECUTABLE_SUFFIX} -P ${CMAKE_SOURCE_DIR}/CMake/download_kvasd.cmake
    COMMENT "Downloading kvasd for ${CMAKE_SYSTEM_NAME}"
    VERBATIM
    )
endif (WSJT_INCLUDE_KVASD)


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

add_executable (jt65code lib/jt65code.f90 wsjtx.rc)
target_link_libraries (jt65code wsjt)

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
add_executable (wsjtx MACOSX_BUNDLE
  ${wsjtx_CXXSRCS}
  ${wsjtx_GENUISRCS}
  wsjtx.rc
  ${WSJTX_ICON_FILE}
  ${wsjtx_RESOURCES_RCC}
  )
qt5_use_modules (wsjtx Widgets OpenGL Network Multimedia)

if (UNIX)
  if (NOT WSJT_SKIP_MANPAGES)
    add_subdirectory (manpages)
    add_dependencies (wsjtx manpages)
  endif (NOT WSJT_SKIP_MANPAGES)
  if (NOT APPLE)
    add_subdirectory (debian)
    add_dependencies (wsjtx debian)
  endif (NOT APPLE)
endif (UNIX)

if (WSJT_CREATE_WINMAIN)
  set_target_properties (wsjtx PROPERTIES WIN32_EXECUTABLE ON)
endif (WSJT_CREATE_WINMAIN)

set_target_properties (wsjtx PROPERTIES
  MACOSX_BUNDLE_INFO_STRING "${WSJTX_DESCRIPTION_SUMMARY}"
  MACOSX_BUNDLE_ICON_FILE "${WSJTX_ICON_FILE}"
  MACOSX_BUNDLE_BUNDLE_VERSION ${wsjtx_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING "v${wsjtx_VERSION}"
  MACOSX_BUNDLE_LONG_VERSION_STRING "Version ${wsjtx_VERSION}"
  MACOSX_BUNDLE_BUNDLE_NAME "${PROJECT_NAME}"
  MACOSX_BUNDLE_COPYRIGHT "${PROJECT_COPYRIGHT}"
  MACOSX_BUNDLE_GUI_IDENTIFIER "org.k1jt.wsjtx"
  )

target_link_libraries (wsjtx wsjt wsjt_qt ${hamlib_LIBRARIES} ${FFTW3_LIBRARIES})

#
# installation
#
install (TARGETS wsjtx
  RUNTIME DESTINATION ${WSJT_BIN_DESTINATION}
  LIBRARY DESTINATION ${WSJT_LIB_DESTINATION}
  BUNDLE DESTINATION .
  #COMPONENT Runtime
  )

install (TARGETS jt9 jt65code jt9code
  RUNTIME DESTINATION ${WSJT_BIN_DESTINATION}
  LIBRARY DESTINATION ${WSJT_LIB_DESTINATION}
  BUNDLE DESTINATION ${WSJT_BIN_DESTINATION}
  #COMPONENT Runtime
  )

if (WSJT_INCLUDE_KVASD)
  install (PROGRAMS
    ${CMAKE_BINARY_DIR}/${KVASD}
    DESTINATION ${WSJT_BIN_DESTINATION}
    #COMPONENT Runtime
  )
else (WSJT_INCLUDE_KVASD)
  if (APPLE)
    install (DIRECTORY contrib/Darwin/KVASD-installer.app
      DESTINATION .
      USE_SOURCE_PERMISSIONS
      #COMPONENT Runtime
      )
  endif (APPLE)
endif (WSJT_INCLUDE_KVASD)

install (PROGRAMS
  ${RIGCTLD_EXE}
  DESTINATION ${WSJT_BIN_DESTINATION}
  #COMPONENT Runtime
  RENAME rigctld-wsjtx${CMAKE_EXECUTABLE_SUFFIX}
  )

install (FILES
  ${CMAKE_BINARY_DIR}/contrib/${PROJECT_MANUAL}
  DESTINATION ${WSJT_SHARE_DESTINATION}/${WSJT_DOC_DESTINATION}
  #COMPONENT Runtime
  )

#
# Mac installer files
#
if (APPLE)
    install (FILES
        Darwin/ReadMe.txt
        Darwin/sysctl.conf
        DESTINATION .
        #COMPONENT Runtime
    )
endif (APPLE)


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
# explicitly say that the wsjt_qt depends on custom target, this is
# done indirectly so that the revisiontag target gets built exactly
# once per build
add_dependencies(wsjt_qt revisiontag)


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
  install (
    FILES wsjtx.desktop
    DESTINATION share/applications
    #COMPONENT Runtime
    )
  install (
    FILES icons/Unix/wsjtx_icon.png
    DESTINATION share/pixmaps
    #COMPONENT Runtime
    )
endif (NOT WIN32 AND NOT APPLE)


#
# bundle fixup only done in Release or MinSizeRel configurations
#
if (NOT is_debug_build)

  # get_target_property (QtCore_location Qt5::Core LOCATION)
  # get_filename_component (QtCore_location ${QtCore_location} PATH)
  # list (APPEND fixup_library_dirs ${QtCore_location})

  if (APPLE)
    set (CMAKE_POSTFLIGHT_SCRIPT
      "${wsjtx_BINARY_DIR}/postflight.sh")
    set (CMAKE_POSTUPGRADE_SCRIPT
      "${wsjtx_BINARY_DIR}/postupgrade.sh")
    configure_file ("${wsjtx_SOURCE_DIR}/Darwin/postflight.sh.in"
      "${CMAKE_POSTFLIGHT_SCRIPT}")
    configure_file ("${wsjtx_SOURCE_DIR}/Darwin/postupgrade.sh.in"
      "${CMAKE_POSTUPGRADE_SCRIPT}")
  endif ()

  if (APPLE OR WIN32)
    # install rules for including 3rd party libs such as Qt

    # install a qt.conf file
    install (CODE "
  file (WRITE \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"[Paths]
\")
"
      #COMPONENT Runtime
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
	${QT_PLUGINS_DIR}/accessible
	DESTINATION ${WSJT_PLUGIN_DESTINATION}
	CONFIGURATIONS Release MinSizeRel
	#COMPONENT Runtime
	FILES_MATCHING PATTERN "*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*quick*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*_debug${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	)
      # install (
      # 	DIRECTORY
      # 	${QT_PLUGINS_DIR}/platforms
      # 	${QT_PLUGINS_DIR}/audio
      #         ${QT_PLUGINS_DIR}/accessible
      # 	DESTINATION ${WSJT_PLUGIN_DESTINATION}
      # 	CONFIGURATIONS Debug
      # 	#COMPONENT Runtime
      # 	FILES_MATCHING PATTERN "*_debug${CMAKE_SHARED_LIBRARY_SUFFIX}"
      # 	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*quick*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	)

      # add plugins path for Mac Bundle
      install (CODE "
file (APPEND \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"Plugins = Plugins
\")
"
	#COMPONENT Runtime
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
	${QT_PLUGINS_DIR}/accessible
	DESTINATION ${WSJT_PLUGIN_DESTINATION}
	CONFIGURATIONS Release MinSizeRel
	#COMPONENT Runtime
	FILES_MATCHING PATTERN "*${CMAKE_SHARED_LIBRARY_SUFFIX}"
	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*quick*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	PATTERN "*d${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
	)
      # install (
      # 	DIRECTORY
      # 	${QT_PLUGINS_DIR}/platforms
      # 	${QT_PLUGINS_DIR}/accessible
      # 	DESTINATION ${WSJT_PLUGIN_DESTINATION}
      # 	CONFIGURATIONS Debug
      # 	#COMPONENT Runtime
      # 	FILES_MATCHING PATTERN "*d${CMAKE_SHARED_LIBRARY_SUFFIX}"
      # 	PATTERN "*minimal*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*offscreen*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	PATTERN "*quick*${CMAKE_SHARED_LIBRARY_SUFFIX}" EXCLUDE
      # 	)

      # add plugins path for WIN32
      file (RELATIVE_PATH _plugins_path "${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}" "${CMAKE_INSTALL_PREFIX}/${WSJT_PLUGIN_DESTINATION}")
      install (CODE "
file (APPEND \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${WSJT_QT_CONF_DESTINATION}/qt.conf\"
\"Plugins = ${_plugins_path}
\")
"
	#COMPONENT Runtime
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
     # canonicalize path in install context
     get_filename_component (the_exe ${fixup_exe} REALPATH)
     message (STATUS \"fixup_exe: \${the_exe}\")
     fixup_bundle (\"\${the_exe}\" \"\${QTPLUGINS}\" \"${fixup_library_dirs}\")
   "
      #COMPONENT Runtime
      )
  endif (APPLE OR WIN32)

endif (NOT is_debug_build)


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
  set (CPACK_GENERATOR "DragNDrop")
else ()
  find_program (DPKG_BUILDER dpkg-buildpackage DOC "Debian package builder")
  if (DPKG_BUILDER)
    #
    # Derive the correct filename for a Debian package because the DEB
    # generator doesn't do this correctly at present.
    #
    find_program (DPKG_PROGRAM dpkg DOC "dpkg program of Debian-based systems")
    if (DPKG_PROGRAM)
      execute_process (
	COMMAND ${DPKG_PROGRAM} --print-architecture
	OUTPUT_VARIABLE CPACK_DEBIAN_PACKAGE_ARCHITECTURE
	OUTPUT_STRIP_TRAILING_WHITESPACE
	)
    else (DPKG_PROGRAM)
      set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE noarch)
    endif (DPKG_PROGRAM)

    list (APPEND CPACK_GENERATOR "DEB")
  endif (DPKG_BUILDER)

  find_program (RPMBUILDER rpmbuild DOC "RPM package builder")
  if (RPMBUILDER)
    list (APPEND CPACK_GENERATOR "RPM")
  endif (RPMBUILDER)
endif ()

set (CPACK_DEBIAN_PACKAGE_DESCRIPTION "${PROJECT_DESCRIPTION}")
set (CPACK_DEBIAN_PACKAGE_HOMEPAGE "${PROJECT_HOMEPAGE}")
set (CPACK_DEBIAN_PACKAGE_DEPENDS "libgfortran3 (>=4.8.2), libqt5multimedia5-plugins (>=5), libqt5widgets5 (>=5), libc6 (>=2.19)")
set (CPACK_DEBIAN_PACKAGE_PACKAGE_SHLIBDEPS ON)

set (CPACK_RPM_PACKAGE_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
set (CPACK_RPM_PACKAGE_REQUIRES "qt5-qtmultimedia >= 5, glibc >= 2, libgfortran >= 4.8.2")
set (CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION /usr/share/pixmaps /usr/share/applications /usr/share/man /usr/share/man1)

configure_file ("${PROJECT_SOURCE_DIR}/CMakeCPackOptions.cmake.in"
  "${PROJECT_BINARY_DIR}/CMakeCPackOptions.cmake" @ONLY)
set (CPACK_PROJECT_CONFIG_FILE "${PROJECT_BINARY_DIR}/CMakeCPackOptions.cmake")

include (CPack)
