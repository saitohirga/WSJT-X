#-------------------------------------------------
#
# Project created by QtCreator 2011-07-07T08:39:24
#
#-------------------------------------------------

QT       += core gui network
CONFIG   += qwt thread
#CONFIG   += console

TARGET = wsjtx
VERSION = 0.2
TEMPLATE = app

win32 {
DEFINES = WIN32
DESTDIR = ../wsjtx_install
F90 = g95
g95.output = ${QMAKE_FILE_BASE}.o
g95.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
g95.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += g95
}

unix {
DEFINES = UNIX
DESTDIR = ../wsjtx_install
F90 = gfortran
gfortran.output = ${QMAKE_FILE_BASE}.o
gfortran.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
gfortran.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += gfortran
}

SOURCES += main.cpp mainwindow.cpp plotter.cpp about.cpp \
    soundin.cpp soundout.cpp devsetup.cpp widegraph.cpp \
    getfile.cpp displaytext.cpp getdev.cpp logqso.cpp \
    psk_reporter.cpp

win32 {
SOURCES += killbyname.cpp
}

HEADERS  += mainwindow.h plotter.h soundin.h soundout.h \
            about.h devsetup.h widegraph.h getfile.h \
            commons.h sleep.h displaytext.h logqso.h \
            psk_reporter.h

DEFINES += __cplusplus

FORMS    += mainwindow.ui about.ui devsetup.ui widegraph.ui \
    logqso.ui

RC_FILE = wsjtx.rc

unix {
INCLUDEPATH += $$quote(/usr/include/qwt-qt4)
LIBS += ../wsjtx/lib/libjt9.a
LIBS += -lportaudio -lgfortran -lfftw3f -lqwt-qt4
}

win32 {
INCLUDEPATH += c:/qwt-6.0.1/include
LIBS += ../wsjtx/lib/libjt9.a
LIBS += ../wsjtx/libfftw3f_win.a
LIBS += ../wsjtx/libpskreporter.a
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
