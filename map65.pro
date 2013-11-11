#-------------------------------------------------
#
# Project created by QtCreator 2011-07-07T08:39:24
#
#-------------------------------------------------

QT       += core gui network
CONFIG   += qwt thread
#CONFIG   += console

TARGET = map65
VERSION = 2.3.0
TEMPLATE = app

win32 {
DEFINES = WIN32
DESTDIR = ../map65_install
F90 = g95
g95.output = ${QMAKE_FILE_BASE}.o
g95.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
g95.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += g95
}

unix {
DEFINES = UNIX
DESTDIR = ../map65_install
F90 = gfortran
gfortran.output = ${QMAKE_FILE_BASE}.o
gfortran.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
gfortran.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += gfortran
}

SOURCES += main.cpp mainwindow.cpp plotter.cpp about.cpp \
    soundin.cpp soundout.cpp devsetup.cpp \
    widegraph.cpp getfile.cpp messages.cpp bandmap.cpp \
    astro.cpp displaytext.cpp getdev.cpp \
    txtune.cpp

win32 {
SOURCES += killbyname.cpp     set570.cpp
}

HEADERS  += mainwindow.h plotter.h soundin.h soundout.h \
            about.h devsetup.h widegraph.h getfile.h messages.h \
            bandmap.h commons.h sleep.h astro.h displaytext.h \
    txtune.h

DEFINES += __cplusplus

FORMS    += mainwindow.ui about.ui devsetup.ui widegraph.ui \
    messages.ui bandmap.ui astro.ui \
    txtune.ui

RC_FILE = map65.rc

unix {
INCLUDEPATH += -lqwt
LIBS += ../map65/libm65/libm65.a
LIBS += -lfftw3f -lportaudio -lgfortran
#LIBS +- -lusb
}

win32 {
INCLUDEPATH += c:/qwt-6.0.1/include
LIBS += ../map65/libm65/libm65.a
LIBS += ../map65/libfftw3f_win.a
LIBS += ../QtSupport/palir-02.dll
LIBS += libwsock32
LIBS += C:/MinGW/lib/libf95.a
CONFIG(release) {
   LIBS += C:/qwt-6.0.1/lib/qwt.dll
} else {
   LIBS += C:/qwt-6.0.1/lib/qwtd.dll
}
LIBS += -lusb
}
