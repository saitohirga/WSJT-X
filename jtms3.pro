#-------------------------------------------------
#
# Project created by QtCreator 2011-07-07T08:39:24
#
#-------------------------------------------------

QT       += core gui network
CONFIG   += qwt thread
#CONFIG   += console

TARGET = jtms3
VERSION = 0.1
TEMPLATE = app

win32 {
DEFINES = WIN32
DESTDIR = ../jtms3_install
F90 = g95
g95.output = ${QMAKE_FILE_BASE}.o
g95.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
g95.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += g95
}

unix {
DEFINES = UNIX
DESTDIR = ../jtms3_install
F90 = gfortran
gfortran.output = ${QMAKE_FILE_BASE}.o
gfortran.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
gfortran.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += gfortran
}

SOURCES += main.cpp mainwindow.cpp plotter.cpp about.cpp \
    soundin.cpp soundout.cpp devsetup.cpp \
    widegraph.cpp getfile.cpp \
    displaytext.cpp getdev.cpp

win32 {
SOURCES += killbyname.cpp     set570.cpp
}

HEADERS  += mainwindow.h plotter.h soundin.h soundout.h \
            about.h devsetup.h widegraph.h getfile.h \
            commons.h sleep.h displaytext.h \

DEFINES += __cplusplus

FORMS    += mainwindow.ui about.ui devsetup.ui widegraph.ui

RC_FILE = jtms3.rc

unix {
INCLUDEPATH += $$quote(/usr/include/qwt-qt4)
LIBS += -lfftw3f /usr/lib/libgfortran.so.3
LIBS += ../jtms3/libm65/libm65.a
LIBS += /usr/lib/libqwt-qt4.so
LIBS += -lportaudio
#LIBS +- -lusb
}

win32 {
INCLUDEPATH += c:/qwt-6.0.1/include
LIBS += ../jtms3/libm65/libm65.a
LIBS += ../jtms3/libfftw3f_win.a
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
