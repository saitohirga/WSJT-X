dnl $Id$
dnl Process this file with autoconf to produce a configure script.


dnl AC_PREREQ(2.59)

dnl Sneaky way to get an Id tag into the configure script
AC_COPYRIGHT([$Id$])

AC_INIT([wsjt],[0.9])

AC_CONFIG_HEADER(conf.h)

AC_PREFIX_DEFAULT(/usr/local/)

OLD_CFLAGS="$CFLAGS"
dnl Checks for programs.
AC_PROG_CC
AC_LANG(C)
AC_PROG_F77

dnl Make sure autoconf doesn't interfere with cflags -jmallett
CFLAGS="$OLD_CFLAGS"

dnl Lets guess at some likely places for extra libs/includes XXX -db
CPPFLAGS="-I/usr/local/include -I/usr/include/alsa ${CPPFLAGS}"
LDFLAGS="-L/usr/local/lib -lpthread ${LDFLAGS}"

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
AC_DEFINE_UNQUOTED(G95_LIB_PATH, "${G95_LIB_PATH}", [Path to G95 libs.])
AC_SUBST(G95_LIB_PATH, "${G95_LIB_PATH}")

AC_MSG_CHECKING([OS])
OS=`uname`
AC_SUBST(OS, "${OS}")

dnl Checks for header files.
AC_HEADER_STDC

AC_CHECK_HEADERS([inttypes.h stdint.h sys/resource.h sys/param.h errno.h sys/syslog.h stddef.h libgen.h sys/wait.h wait.h ])
AC_CHECK_HEADER([sys/soundcard.h], [HAS_SOUNDCARD_H=1], [HAS_SOUNDCARD_H=0])
AC_CHECK_HEADER([alsa/asoundlib.h], [HAS_ASOUNDLIB_H=1], [HAS_ASOUNDLIB_H=0])
AC_CHECK_HEADER([portaudio.h], [HAS_PORTAUDIO_H=1], [HAS_PORTAUDIO_H=0])
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

dnl alsa soundsupport
dnl =================

AC_ARG_ENABLE(alsa,
AC_HELP_STRING([--enable-alsa],[Force ALSA SOUNDCARD usage.]),
[alsa=$enableval] , [alsa=no])

dnl oss soundsupport
dnl ================

AC_ARG_ENABLE(oss,
AC_HELP_STRING([--enable-oss],[Force OSS SOUND usage.]),
[oss=$enableval] , [oss=no])

dnl portaudio soundsupport
dnl ======================

AC_ARG_ENABLE(portaudio,
AC_HELP_STRING([--enable-portaudio],[Force PORTAUDIO SOUND usage.]),
[portaudio=$enableval], [portaudio=no])

if test "$alsa" = yes; then
	AC_DEFINE(USE_ALSA, 1, [Define if you want ALSA used.])
	AC_SUBST(AUDIO, "start_threads.c")
	LDFLAGS="${LDFLAGS} -lasound"
fi

if test "$oss" = yes; then
	AC_DEFINE(USE_OSS, 1, [Define if you want OSS used.])
	AC_SUBST(AUDIO, "jtaudio.c")
fi

dnl XXX
if test "$portaudio" = yes; then
	AC_DEFINE(USE_PORTAUDIO, 1, [Define if you want PORTAUDIO used.])
	AC_SUBST(AUDIO, "jtaudio.c start_threads.c")
	LDFLAGS="${LDFLAGS} -lportaudio -lsamplerate" 
	CFLAGS="${CFLAGS} -DUSE_PORTAUDIO"
	CPPFLAGS="${CPPFLAGS} -DUSE_PORTAUDIO"
fi

dnl set conf flags

if test $HAS_ASOUNDLIB_H -eq 1; then
	AC_DEFINE(HAS_ASOUNDLIB_H, 1, )
fi

if test $HAS_SOUNDCARD_H -eq 1; then
	AC_DEFINE(HAS_SOUNDCARD_H, 1, )
fi

if test $HAS_PORTAUDIO_H -eq 1; then
	AC_DEFINE(HAS_PORTAUDIO_H, 1, )
fi

if test $HAS_SAMPLERATE_H -eq 1; then
        AC_DEFINE(HAS_SAMPLERATE_H, 1, )
fi

dnl set defaults

if test "$alsa" != yes -a "$oss" != yes -a "$portaudio" != yes; then
	if test $HAS_PORTAUDIO_H -eq 1; then
		set portaudio = yes;	
		AC_MSG_RESULT([Using portaudio])
	elif test $HAS_ASOUNDLIB_H -eq 1; then
		set alsa = yes;
		AC_MSG_RESULT([Using alsa])
	fi
fi

dnl sanity tests.

if test "$alsa" = yes; then
	if test $HAS_ASOUNDLIB_H -eq 0; then
		AC_MSG_ERROR([You need asoundlib.h to use --enable-alsa])
	fi
fi

if test "$oss" = yes; then
	if test $HAS_SOUNDCARD_H -eq 0; then
		AC_MSG_ERROR([You need soundcard.h to use --enable-oss])
	fi
fi

if test "$portaudio" = yes; then
	if test $HAS_PORTAUDIO_H -eq 0; then
		AC_MSG_ERROR([You need portaudio.h to use --enable-portaudio])
	fi
	if test $HAS_SAMPLERATE_H -eq 0; then
		AC_MSG_ERROR([You need samplerate.h to use --enable-portaudio])
	fi
fi


dnl 
AC_SUBST(CPPFLAGS, "${CPPFLAGS}")
AC_SUBST(LDFLAGS, "${LDFLAGS}")
AC_SUBST(CFLAGS)



AC_OUTPUT
dnl do summary

echo
echo "Compiling $PACKAGE_NAME $PACKAGE_VERSION"
echo

echo "Installing into: $prefix"

echo
