dnl {{{ ax_check_gfortran
AC_DEFUN([AX_CHECK_GFORTRAN],[

AC_ARG_ENABLE(g95,
AC_HELP_STRING([--enable-g95],[Use G95 compiler if available.]),
[g95=$enableval], [g95=no])

AC_ARG_ENABLE(gfortran,
AC_HELP_STRING([--enable-gfortran],[Use gfortran compiler if available.]),
[gfortran=$enableval], [gfortran=no])

dnl
dnl Pick up FC from the environment if present
dnl I'll add a test to confirm this is a gfortran later -db
dnl

FCV=""

if test -n $[{FC}] ; then
	gfortran_name_part=`echo $[{FC}] | cut -c 1-8`
	if test $[{gfortran_name_part}] = "gfortran" ; then
		gfortran_name=$[{FC}]
       		FC_LIB_PATH=`$[{FC}] -print-file-name=`
		g95=no
		gfortran=yes
		FFLAGS="$[{FFLAGS_GFORTRAN}]"
		FCV="gnu95"
	else
		unset $[{FC}]
	fi
fi

dnl
dnl Note regarding the apparent silliness with FCV.
dnl The FCV value for g95 might be system dependent, this is
dnl still to be fully explored. If not, then the FCV_G95
dnl stuff can go away. -db
dnl

AC_MSG_CHECKING([uname -s])
case `uname -s` in
	CYGWIN*)
		AC_MSG_RESULT(Cygwin)
		CYGWIN=yes
	;;
	SunOS*)
		AC_MSG_RESULT(SunOS or Solaris)
		AC_DEFINE(__EXTENSIONS__, 1, [This is needed to use strtok_r on Solaris.])
	;;
dnl
dnl Pick up current gfortran from ports infrastructure for fbsd
dnl
        FreeBSD*)
		if test -z $[{gfortran_name}] ; then
			gfortran_name=`grep FC: /usr/ports/Mk/bsd.gcc.mk | head -1 |awk '{print $[2]}'`
		fi
		FCV_G95="g95"
	;;
	*)
		FCV_G95="g95"
		AC_MSG_RESULT(no)
	;;
esac

dnl
dnl look for gfortran if nothing else was given
dnl

if test -z $[gfortran_name] ; then
	gfortran_name="gfortran"
fi

AC_PATH_PROG(G95, g95)
AC_PATH_PROG(GFORTRAN, $[{gfortran_name}])

if test ! -z $[{GFORTRAN}] ; then
	echo "*** gfortran compiler found at $[{GFORTRAN}]"
	if test "$[{gfortran}]" = yes; then
       		FC_LIB_PATH=`$[{GFORTRAN}] -print-file-name=`
		FC=`basename $[{GFORTRAN}]`
		g95=no
		FFLAGS="$[{FFLAGS_GFORTRAN}]"
		FCV="gnu95"
	fi
else
	echo "*** No gfortran compiler found"
fi

if test ! -z $[{G95}] ; then
	echo "*** g95 compiler found at $[{G95}]"
	if test "$[{g95}]" = yes; then
       		FC_LIB_PATH=`$[{G95}] -print-file-name=`
		FC=`basename $[{G95}]`
		gfortran=no
		FFLAGS="$[{FFLAGS_G95}]"
		FCV=$[{FCV_G95}]
	fi
else
	echo "*** No g95 compiler found"
fi

dnl
dnl if FC is not set by now, pick a compiler for user
dnl
if test -z $[{FC}] ; then
	if test ! -z $[{GFORTRAN}] ; then
		if test "$[{g95}]" = yes; then
			echo "You enabled g95, but no g95 compiler found, defaulting to gfortran instead"
		fi
       		FC_LIB_PATH=`$[{GFORTRAN}] -print-file-name=`
	        FC=`basename $[{GFORTRAN}]`
		g95=no
		gfortran=yes
		FFLAGS="$[{FFLAGS_GFORTRAN}]"
		FCV="gnu95"
	elif test ! -z $G95 ; then
		if test "$[{gfortran}]" = yes; then
			echo "You enabled gfortran, but no gfortran compiler found, defaulting to g95 instead"
		fi
       		FC_LIB_PATH=`$[{G95}] -print-file-name=`
	        FC=`basename $[{G95}]`
		g95=yes
		gfortran=no
		FFLAGS="$[{FFLAGS_G95}]"
		FCV=$[{FCV_G95}]
	fi
fi

AC_DEFINE_UNQUOTED(FC_LIB_PATH, "${FC_LIB_PATH}", [Path to fortran libs.])
AC_SUBST(FC_LIB_PATH, "${FC_LIB_PATH}")
AC_DEFINE_UNQUOTED(FC, "${FC}", [Fortran compiler.])
AC_SUBST(FC, "${FC}")
AC_SUBST(FCV, "${FCV}")

dnl =========================================
dnl pick gfortran or g95

])dnl }}}


dnl {{{ ax_check_portaudio
AC_DEFUN([AX_CHECK_PORTAUDIO],[

HAS_PORTAUDIO_H=0
HAS_PORTAUDIO_LIB=0
HAS_PORTAUDIO=0

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

if test -e $[{portaudio_include_dir}]/portaudio.h; then
	HAS_PORTAUDIO_H=1
fi

if test -e $[{portaudio_lib_dir}]/libportaudio.so \
    -o -e $[{portaudio_lib_dir}]/libportaudio.a;then
	HAS_PORTAUDIO_LIB=1
fi

if test $[{HAS_PORTAUDIO_H}] -eq 1 -a $[{HAS_PORTAUDIO_LIB}] -eq 1; then
	LDFLAGS="-L$[{portaudio_lib_dir}] $[{LDFLAGS}]"
	LIBS="$[{LIBS}] -lportaudio"
	CPPFLAGS="-I$[{portaudio_include_dir}] $[{CPPFLAGS}]"
	AC_CHECK_LIB(portaudio, Pa_GetVersion, \
		[HAS_PORTAUDIO_VERSION=1], [HAS_PORTAUDIO_VERSION=0])
	if test $[{HAS_PORTAUDIO_VERSION}] -eq 0; then
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

	if test -e $[{portaudio_include_dir}]/portaudio.h; then
		HAS_PORTAUDIO_H=1
	fi

	if test -e $[{portaudio_lib_dir}]/libportaudio.so \
	    -o -e $[{portaudio_lib_dir}]/libportaudio.a;then
		HAS_PORTAUDIO_LIB=1
	fi

	if test $[{HAS_PORTAUDIO_H}] -eq 1 -a $[{HAS_PORTAUDIO_LIB}] -eq 1; then
		AC_MSG_RESULT([found portaudio in FreeBSD paths, double checking it is v19 ])
		LDFLAGS="-L$[{portaudio_lib_dir}] $[{LDFLAGS}]"
		LIBS="$[{LIBS}] -lportaudio"
		CPPFLAGS="-I$[{portaudio_include_dir}] $[{CPPFLAGS}]"
		AC_CHECK_LIB(portaudio, Pa_GetVersion, \
			[HAS_PORTAUDIO_VERSION=1], [HAS_PORTAUDIO_VERSION=0])
		if test $[{HAS_PORTAUDIO_VERSION}] -eq 0; then
			AC_MSG_RESULT([How did you end up with a portaudio v18 here?])
		else
			AC_MSG_RESULT([found v19])
			HAS_PORTAUDIO=1
			HAS_PORTAUDIO_H=1
		fi
	fi
fi

])dnl }}}
