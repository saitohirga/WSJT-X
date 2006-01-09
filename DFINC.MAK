#+
# DFINC.MAK - Visual Fortran application master NMAKE definitions file
#
# This software DFINC.MAK is part of the Visual Fortran kit.
# 
# This file should be included at the top of all MAKEFILEs as follows:
#  !include <dfinc.mak>
# 
# NMAKE Options:
#
# Use the table below to determine the additional options for NMAKE
# Application Information Type         Invoke NMAKE
# ----------------------------         ------------
# For Debugging Info                   nmake debug=1
# For linker map                       nmake linkmap=1
# For linking with the DLLs            nmake linkdll=1
#-

# Set the defaults for all the MSVCxx versions

crtimplib=msvcrt.lib

!IFNDEF link
link = link
!ENDIF
!IFNDEF libr
libr = lib
!ENDIF

# Define the compiler verbs.
FOR = df

# Macros for the compiler
!IFDEF DEBUG
df_debug =  /debug:full
lnk_debug = /debug:full /debugtype:both
!ELSE
df_debug =
lnk_debug = /debug:none
!ENDIF

!IFDEF LINKDLL
df_dll   = /call_dll
dflibs   = dfordll.lib $(crtimplib) kernel32.lib
!ELSE
df_dll   =
dflibs   = dfor.lib libc.lib kernel32.lib
!ENDIF

fflags    = $(df_debug) $(df_dll) 

# Macros for the FPP Preprocesor 
fppflags =
fpp = $(FOR) $(fflags) /fpp="$(fppflags)"

# Macros for the linker.
!IFDEF LINKMAP
lflags = /map:$(*B).map $(lflags)
!ELSE
lflags = $(lflags)
!ENDIF

# SUFFIXES list
.SUFFIXES: .exe .obj .asm .c .bas .cbl .fpp .for .f90 .pas .res .rc 

# Define the inference rules
.obj.exe:
   $(FOR) $(df_dll) $(df_debug) /link $(lflags) $(lnk_debug) $*.obj 

.for.exe:
   $(FOR) $(fflags) $*.for /link $(lflags)

.f90.exe:
   $(FOR) $(fflags) $*.f90 /link $(lflags)

.fpp.exe:
   $(fpp) $*.fpp /link $(lflags)

.for.obj:
   $(FOR) $(df_debug) $*.for /nolink /object:$@

.f90.obj:
   $(FOR) $(df_debug) $*.f90 /nolink /object:$@

.fpp.obj:
   $(FOR) $(df_debug) /nolink /object:$@ /fpp:"$(fppflags)" $*.fpp

