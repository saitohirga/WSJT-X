dnl $Id$
dnl Process this file with autoconf to produce a configure script.

dnl AC_PREREQ(2.61)

dnl Sneaky way to get an Id tag into the configure script
AC_COPYRIGHT([$Id$])

AC_INIT([map65],[0.9])

fail=0

AC_PREFIX_DEFAULT(/usr/local/)

OLD_CFLAGS="$CFLAGS"
dnl Checks for programs.
AC_PROG_CC
AC_LANG(C)
AC_PROG_F77

dnl Make sure autoconf doesn't interfere with cflags -jmallett
CFLAGS="$OLD_CFLAGS"

dnl Lets guess at some likely places for extra libs/includes XXX -db
CPPFLAGS="-I/usr/local/include ${CPPFLAGS}"
LDFLAGS="-L/usr/local/lib ${LDFLAGS}"
LIBS=" -lpthread ${LIBS}"
FFLAGS_GFORTRAN="${FFLAGS} -fno-range-check -ffixed-line-length-none\
			-Wall -fbounds-check -fno-second-underscore -fPIC"
FFLAGS_G95="${FFLAGS} -Wall -Wno-precision-loss -fbounds-check -fno-second-underscore -fPIC"
#-Wall -Wno-precision-loss -fbounds-check -fno-second-underscore -fPIC

AX_CHECK_GFORTRAN
AX_CHECK_PORTAUDIO

dnl If we support -g, use it!
if test "$ac_cv_prog_cc_g" = yes; then
		CFLAGS="$CFLAGS -g"
fi

dnl jdc -- If CFLAGS is defined, best use it everywhere...
dnl NOTE: jv says it must be added to the *END*, because things like
dnl "gcc -O9 -O2" will result in -O2 getting preference.  How stupid.
if test ! -z "$CFLAGS"; then
	CFLAGS="$CFLAGS $CFLAGS"
fi


AC_ISC_POSIX
AC_C_INLINE
AC_PROG_GCC_TRADITIONAL
AC_PROG_MAKE_SET
AC_PROG_INSTALL
AC_PATH_PROG(RM, rm)
AC_PATH_PROG(CP, cp)
AC_PATH_PROG(MV, mv)
AC_PATH_PROG(LN, ln)
AC_PATH_PROG(SED, sed)
AC_PATH_PROG(AR, ar)
AC_PATH_PROG(LD, ld)
AC_PATH_PROG(TEST, [test], [test])
AC_PATH_PROG(PYTHON, python)
AC_PATH_PROG(F2PY, f2py)
AC_MSG_CHECKING([OS])
OS=`uname`
AC_SUBST(OS, "${OS}")

dnl Checks for header files.

AC_HEADER_STDC

AC_CHECK_HEADERS([inttypes.h stdint.h sys/resource.h sys/param.h errno.h \
sys/syslog.h stddef.h libgen.h sys/wait.h wait.h stdio.h termios.h \
sys/resource.h linux/ppdev.h dev/ppbus/ppi.h sys/stat.h fcntl.h sys/ioctl.h ])

AC_HEADER_TIME

AC_CHECK_HEADER([fftw3.h], [HAS_FFTW3_H=1], [HAS_FFTW3_H=0])
AC_CHECK_HEADER([samplerate.h], [HAS_SAMPLERATE_H=1], [HAS_SAMPLERATE_H=0])

dnl See whether we can include both string.h and strings.h.
AC_CACHE_CHECK([whether string.h and strings.h may both be included],
gcc_cv_header_string,
[
	AC_COMPILE_IFELSE(
	[#include <string.h>
	#include <strings.h>], 
	[gcc_cv_header_string=yes],
	[gcc_cv_header_string=no])
])

if test "$gcc_cv_header_string" = "yes"; then
	AC_DEFINE(STRING_WITH_STRINGS, 1, [Define to 1 if string.h may be included along with strings.h])
fi

dnl check for a fortran shim entry point
AC_CHECK_LIB(fftw3f, sfftw_destroy_plan_, \
	[HAS_FFTW3FLIBS=1], [HAS_FFTW3FLIBS=0])

dnl Check for stdarg.h - if we can't find it, halt configure
AC_CHECK_HEADER(stdarg.h, , [AC_MSG_ERROR([** stdarg.h could not be found - wsjt will not compile without it **])])

dnl Debug-related options
dnl =====================

AC_ARG_ENABLE(clobber,
AC_HELP_STRING([--enable-clobber], [Don't preserve old binaries on make install]),
[clobber=$enableval], [clobber=no])

if test "$clobber" = yes; then
	AC_SUBST(CLOBBER, yes)
fi

AC_ARG_ENABLE(assert,
AC_HELP_STRING([--enable-assert],[Enable assert().]),
[assert=$enableval], [assert=no])

if test "$assert" = no; then
	AC_DEFINE(NDEBUG, 1, [Define this to disable debugging support.])
fi

if test "$prefix" = "NONE"; then 
	prefix=${ac_default_prefix}
else

dnl Don't get bitten by Cygwin's stupidity if the user specified
dnl a custom prefix with a trailing slash

	prefix=`echo ${ac_default_prefix} | sed 's/\/$//'`
fi

dnl sanity tests.
dnl =============

if test -z $FC ; then
	fail=1
	echo "You need g95 or gfortran to compile this program!"
fi

if test $HAS_FFTW3_H -eq 0; then
	fail=1
	echo "You need to install the fftw3 libraries"
fi

if test $HAS_SAMPLERATE_H -eq 0; then
	fail=1
	echo "You need to install the samplerate library"
else
        AC_DEFINE(HAS_SAMPLERATE_H, 1, )
	LIBS="${LIBS} -lsamplerate"
fi

if test $HAS_PORTAUDIO -eq 1; then
	AC_DEFINE(HAS_PORTAUDIO, 1, )
	AC_DEFINE(HAS_PORTAUDIO_H, 1, )
	AC_DEFINE(HAS_PORTAUDIO_LIB, 1, )
else
	fail=1
	echo "This program needs portaudio v19 to compile."
	echo "Please use --with-portaudio-include-dir= and"
	echo " --with-portaudio-lib-dir= to set the paths."
fi

if test $HAS_FFTW3_H -eq 1; then
	AC_DEFINE(HAS_FFTW3_H, 1, )
else
	fail=1
	echo "You are missing the fftw3.h include file"
fi

if test $HAS_FFTW3FLIBS -eq 1; then
	LIBS="${LIBS} -lfftw3f"
	AC_DEFINE(HAS_FFTW3FLIBS, 1, )
else
	fail =1
	echo "You are missing the fortran shim in libfftw3."
fi

if test "$F2PY" = ""; then
	echo "You are missing f2py, trying local copy."
	F2PY="python f2py.py";	
fi

dnl 
dnl
dnl If fail a pre-requisite then fail
dnl

if test $fail -eq 1; then
	AC_MSG_ERROR([Please check error messages and install missing packages.])
fi

AC_SUBST(PREFIX, "${prefix}")
AC_SUBST(CPPFLAGS, "${CPPFLAGS}")
AC_SUBST(LDFLAGS, "${LDFLAGS}")
AC_SUBST(LIBS, "${LIBS}")
AC_SUBST(CFLAGS)
AC_SUBST(FFLAGS)
AC_SUBST(F2PY, "${F2PY}")
AC_CONFIG_FILES(Makefile)
AC_OUTPUT

dnl do summary

echo
echo

if test $g95 = "yes"; then
	echo "Using g95 as fortran compiler.";
elif test $gfortran = "yes"; then
	echo "Using gfortran as fortran compiler.";
fi

echo
echo "Compiling $PACKAGE_NAME $PACKAGE_VERSION"
echo

echo "Installing into: $prefix"

echo
