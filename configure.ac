dnl $Id$
dnl Process this file with autoconf to produce a configure script.

dnl AC_PREREQ(2.61)

dnl Sneaky way to get an Id tag into the configure script
AC_COPYRIGHT([$Id$])

AC_INIT([map65],[0.9])

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

AC_MSG_CHECKING([uname -s for Cygwin, Solaris or HPUX])
case `uname -s` in
	CYGWIN*)
		AC_MSG_RESULT(Cygwin)
		CYGWIN=yes
	;;
	SunOS*)
		AC_MSG_RESULT(SunOS or Solaris)
		AC_DEFINE(__EXTENSIONS__, 1, [This is needed to use strtok_r on Solaris.])
	;;
	*)
		AC_MSG_RESULT(no)
	;;
esac

if test "$ac_cv_c_compiler_gnu" = yes; then
	AC_MSG_CHECKING(if $CC is Apple GCC)
	
	if expr "`$CC -v 2>&1 | tail -1`" : ".*Apple" >/dev/null; then
		AppleGCC=yes
	else
		AppleGCC=no
	fi

	AC_MSG_RESULT($AppleGCC)

	CFLAGS="$CFLAGS -Wall -O0"
fi

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
AC_PATH_PROG(G95, g95)
AC_MSG_CHECKING([g95 lib path])
G95_LIB_PATH=`${G95} -print-file-name=`
AC_MSG_RESULT(${G95_LIB_PATH})
AC_PATH_PROG(GFORTRAN, gfortran)
AC_PATH_PROG(GFORTRAN, gfortran43)
AC_MSG_CHECKING([gfortran lib path])
GFORTRAN_LIB_PATH=`${GFORTRAN} -print-file-name=`
AC_MSG_RESULT(${GFORTRAN_LIB_PATH})
AC_MSG_CHECKING([OS])
OS=`uname`
AC_SUBST(OS, "${OS}")

dnl Checks for header files.

AC_HEADER_STDC

AC_CHECK_HEADERS([inttypes.h stdint.h sys/resource.h sys/param.h errno.h \
sys/syslog.h stddef.h libgen.h sys/wait.h wait.h stdio.h termios.h \
sys/resource.h linux/ppdev.h dev/ppbus/ppi.h sys/stat.h fcntl.h sys/ioctl.h ])

AC_HEADER_TIME

AC_CHECK_HEADER([samplerate.h], [HAS_SAMPLERATE_H=1], [HAS_SAMPLERATE_H=0])

HAS_PORTAUDIO_H=0
HAS_PORTAUDIO_LIB=0
HAS_PORTAUDIO=0

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

AC_CHECK_LIB(rt, clock_gettime, [RTLIBS="-lrt"], [RTLIBS=""])
AC_CHECK_LIB(asound, snd_pcm_open, [ASOUNDLIBS="-lasound"], [ASOUNDLIBS=""])

AC_CHECK_SIZEOF(int64_t)
AC_CHECK_SIZEOF(long long)

if test "$ac_cv_sizeof_int64_t" = 8; then
  AC_CHECK_TYPE(uint64_t)
  AC_CHECK_TYPE(int64_t)
elif test "$ac_cv_sizeof_long_long" = 8; then
  AC_CHECK_TYPE(uint64_t, unsigned long long)
  AC_CHECK_TYPE(int64_t, long long)
fi

AC_CHECK_TYPE([u_int32_t], [],
[
	AC_CHECK_TYPE([uint32_t],
	[
		AC_DEFINE(u_int32_t, [uint32_t], [If system does not define u_int32_t, define a reasonable substitute.])
	],
	[
		AC_MSG_WARN([system has no u_int32_t or uint32_t, default to unsigned long int])
		AC_DEFINE(u_int32_t, [unsigned long int], [If system does not define u_int32_t, define to unsigned long int here.])
	])
])

AC_CHECK_TYPE([u_int16_t], [],
[
	AC_CHECK_TYPE([uint16_t],
	[
		AC_DEFINE(u_int16_t, [uint16_t], [If system does not define u_int16_t, define a usable substitute])
	],
	[
		AC_MSG_WARN([system has no u_int16_t or uint16_t, default to unsigned short int])
		AC_DEFINE(u_int16_t, [unsigned short int], [If system does not define u_int16_t, define a usable substitute.])
	])
])

AC_C_BIGENDIAN

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
	AC_DEFINE_UNQUOTED(PREFIX, "$ac_default_prefix", [Prefix where wsjt is installed.])

else

dnl Don't get bitten by Cygwin's stupidity if the user specified
dnl a custom prefix with a trailing slash

	prefix=`echo $prefix | sed 's/\/$//'`
	AC_DEFINE_UNQUOTED(PREFIX, "$prefix", [Prefix where wsjt is installed.])
	
fi

AC_CONFIG_FILES(		\
	Makefile		
)

dnl pick gfortran or g95
dnl ====================

AC_ARG_ENABLE(g95,
AC_HELP_STRING([--enable-g95],[Use G95 compiler if available.]),
[g95=$enableval], [g95=no])

AC_ARG_ENABLE(gfortran,
AC_HELP_STRING([--enable-gfortran],[Use gfortran compiler if available.]),
[gfortran=$enableval], [gfortran=no])

dnl now set conf.h,, CPPFLAGS and CFLAGS flags as needed
dnl ====================================================

if test "$g95" = yes; then
        FC_LIB_PATH=${G95_LIB_PATH}
	FC=${G95}
	gfortran=no
elif test "$gfortran" = yes; then
        FC_LIB_PATH=${GFORTRAN_LIB_PATH}
	FC=${GFORTRAN}
	g95=no
fi

if test -z $FC ; then
	if test ! -z $GFORTRAN ; then
       		FC_LIB_PATH=${GFORTRAN_LIB_PATH}
	        FC=${GFORTRAN}
		gfortran=yes
	elif test ! -z $G95 ; then
       		FC_LIB_PATH=${G95_LIB_PATH}
	        FC=${G95}
		g95=yes
	fi
fi

if test -z $FC ; then
		AC_MSG_ERROR([You need g95 or gfortran])
fi


AC_DEFINE_UNQUOTED(FC_LIB_PATH, "${FC_LIB_PATH}", [Path to fortran libs.])
AC_SUBST(FC_LIB_PATH, "${FC_LIB_PATH}")
AC_DEFINE_UNQUOTED(FC, "${FC}", [Fortran compiler.])
AC_SUBST(FC, "${FC}")

dnl set defaults
dnl ============


AC_MSG_CHECKING([for a v19 portaudio ])

portaudio_lib_dir="/usr/lib"
portaudio_include_dir="/usr/include"

AC_ARG_WITH([portaudio-include-dir],
AC_HELP_STRING([--with-portaudio-include-dir=<path>],
    [path to portaudio include files]),
    [portaudio_include_dir=$with_portaudio_include_dir])

AC_ARG_WITH([portaudio-lib-dir],
AC_HELP_STRING([--with-portaudio-lib-dir=<path>],
    [path to portaudio lib files]),
    [portaudio_lib_dir=$with_portaudio_lib_dir])

if test -e ${portaudio_include_dir}/portaudio.h; then
	HAS_PORTAUDIO_H=1
fi

if test -e ${portaudio_lib_dir}/libportaudio.so \
    -o -e ${portaudio_lib_dir}/libportaudio.a;then
	HAS_PORTAUDIO_LIB=1
fi

if test $HAS_PORTAUDIO_H -eq 1 -a $HAS_PORTAUDIO_LIB -eq 1; then
	LDFLAGS="-L${portaudio_lib_dir} ${LDFLAGS}"
	LIBS="${LIBS} -lportaudio"
	CPPFLAGS="-I${portaudio_include_dir} ${CPPFLAGS}"
	AC_CHECK_LIB(portaudio, Pa_GetVersion, \
		[HAS_PORTAUDIO_VERSION=1], [HAS_PORTAUDIO_VERSION=0])
	if test $HAS_PORTAUDIO_VERSION -eq 0; then
		AC_MSG_RESULT([This is likely portaudio v18; you need portaudio v19])
	else
		HAS_PORTAUDIO=1
	fi
else
	AC_MSG_RESULT([portaudio not found trying FreeBSD paths ])
	portaudio_lib_dir="/usr/local/lib/portaudio2"
	portaudio_include_dir="/usr/local/include/portaudio2"
dnl
dnl Try again to make sure portaudio dirs are valid
dnl
	AC_MSG_CHECKING([for a v19 portaudio in FreeBSD paths.])
	HAS_PORTAUDIO_H=0
	HAS_PORTAUDIO_LIB=0

	if test -e ${portaudio_include_dir}/portaudio.h; then
		HAS_PORTAUDIO_H=1
	fi

	if test -e ${portaudio_lib_dir}/libportaudio.so \
	    -o -e ${portaudio_lib_dir}/libportaudio.a;then
		HAS_PORTAUDIO_LIB=1
	fi

	if test $HAS_PORTAUDIO_H -eq 1 -a $HAS_PORTAUDIO_LIB -eq 1; then
		AC_MSG_RESULT([found portaudio in FreeBSD paths, double checking it is v19 ])
		LDFLAGS="-L${portaudio_lib_dir} ${LDFLAGS}"
		LIBS="${LIBS} -lportaudio"
		CPPFLAGS="-I${portaudio_include_dir} ${CPPFLAGS}"
		AC_CHECK_LIB(portaudio, Pa_GetVersion, \
			[HAS_PORTAUDIO_VERSION=1], [HAS_PORTAUDIO_VERSION=0])
		if test $HAS_PORTAUDIO_VERSION -eq 0; then
			AC_MSG_RESULT([How did you end up with a portaudio v18 here?])
		else
			AC_MSG_RESULT([found v19])
			HAS_PORTAUDIO=1
			HAS_PORTAUDIO_H=1
		fi
	fi
fi

dnl sanity tests.
dnl =============

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

if test "$F2PY" = ""; then
	AC_MSG_ERROR([You are missing f2py])
fi

dnl 
AC_SUBST(CPPFLAGS, "${CPPFLAGS}")
AC_SUBST(LDFLAGS, "${LDFLAGS}")
AC_SUBST(LIBS, "${LIBS}")
AC_SUBST(CFLAGS)

AC_OUTPUT
dnl AC_CONFIG_FILES(Makefile)

dnl do summary

echo
echo

if test $g95 = "yes"; then
	echo "Using g95 as fortran compiler.";
fi

if test $gfortran = "yes"; then
	echo "Using gfortran as fortran compiler.";
fi

echo
echo "Compiling $PACKAGE_NAME $PACKAGE_VERSION"
echo

echo "Installing into: $prefix"

echo
