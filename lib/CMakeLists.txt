cmake_minimum_required (VERSION 2.8.8)

project (libjt9 C CXX Fortran)

if (POLICY CMP0020)
  cmake_policy (SET CMP0020 NEW) # link to Qt winmain on Windows
endif (POLICY CMP0020)

# make sure that the default is a RELEASE
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE RELEASE CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)
endif (NOT CMAKE_BUILD_TYPE)

set (CMAKE_POSITION_INDEPENDENT_CODE ON)


#
# Fortran setup
#

# FFLAGS depend on the compiler
get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)

if (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  # gfortran
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "ifort.*")
  # ifort (untested)
  set (CMAKE_Fortran_FLAGS_RELEASE "-f77rtl -O3")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-f77rtl -O0 -g")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  # g77
  set (CMAKE_Fortran_FLAGS_RELEASE "-funroll-all-loops -fno-f2c -O3 -m32")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-fno-f2c -O0 -g -m32")
else (Fortran_COMPILER_NAME MATCHES "gfortran.*")
  message ("CMAKE_Fortran_COMPILER full path: " ${CMAKE_Fortran_COMPILER})
  message ("Fortran compiler: " ${Fortran_COMPILER_NAME})
  message ("No optimized Fortran compiler flags are known, we just try -O2...")
  set (CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set (CMAKE_Fortran_FLAGS_DEBUG   "-O0 -g")
endif (Fortran_COMPILER_NAME MATCHES "gfortran.*")


#
# C++ setup
#

if (UNIX)
	SET (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
endif (UNIX)


#
# setup and test Fortran C/C++ interaction
#

include (FortranCInterface)
FortranCInterface_VERIFY (CXX QUIET)
FortranCInterface_HEADER (FC.h MACRO_NAMESPACE "FC_" SYMBOL_NAMESPACE "FC_"
  SYMBOLS )


set (FSRCS
  afc65b.f90
  afc9.f90
  analytic.f90
  azdist.f90
  ccf2.f90
  ccf65.f90
  chkhist.f90
  chkss2.f90
  db.f90
  decode65a.f90
  decode65b.f90
  decode9.f90
  decoder.f90
  deg2grid.f90
  demod64a.f90
  downsam9.f90
  encode232.f90
  entail.f90
  extract.F90
  f77_wisdom.f90
  fano232.f90
  fchisq.f90
  fchisq65.f90
  fil3.f90
  fil6521.f90
  filbig.f90
  fillcom.f90
  flat2.f90
  flat65.f90
  four2a.f90
  gen65.f90
  genjt9.f90
  geodist.f90
  getlags.f90
  getpfx1.f90
  getpfx2.f90
  graycode.f90
  graycode65.f90
  grid2deg.f90
  grid2k.f90
  grid2n.f90
  indexx.f90
  interleave63.f90
  interleave9.f90
  jt65a.f90
  k2grid.f90
  morse.f90
  move.f90
  n2grid.f90
  nchar.f90
  packbits.f90
  packcall.f90
  packgrid.f90
  packmsg.f90
  packtext.f90
  pctile.f90
  peakdt9.f90
  pfxdump.f90
  sec_midn.f90
  setup65.f90
  sleep_msec.f90
  smo121.f90
  softsym.f90
  sort.f90
  ssort.f90
  stdmsg.f90
  symspec.f90
  symspec2.f90
  symspec65.f90
  sync9.f90
  timer.f90
  twkfreq.f90
  twkfreq65.f90
  unpackbits.f90
  unpackcall.f90
  unpackgrid.f90
  unpackmsg.f90
  unpacktext.f90
  zplot9.f90
  )

set (CSRCS
  cutil.c
  decode_rs.c
  encode_rs.c
  gran.c
  igray.c
  init_rs.c
  wrapkarn.c
)

set (CXXSRCS
  ipcomm.cpp
  )


add_definitions (-DBIGSYM=1)

#
# build our targets
#
add_library (jt9impl STATIC ${FSRCS} ${CSRCS} ${CXXSRCS})
qt5_use_modules (jt9impl Core)

add_executable (jt9sim jt9sim.f90 ../wsjtx.rc)
target_link_libraries (jt9sim jt9impl)

add_executable (jt9code jt9code.f90 ../wsjtx.rc)
target_link_libraries (jt9code jt9impl)

add_executable (jt9 jt9.f90 jt9a.f90 jt9b.f90 jt9c.f90 ../wsjtx.rc)
target_link_libraries (jt9 jt9impl ${fftw3f})
add_dependencies (jt9 fftw3f)
qt5_use_modules (jt9 Core)

install (
  TARGETS jt9
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  )
