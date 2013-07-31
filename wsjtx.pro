#-------------------------------------------------
#
# Project created by QtCreator 2011-07-07T08:39:24
#
#-------------------------------------------------

QT       += core gui network multimedia
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets
CONFIG   += thread
#CONFIG   += console

TARGET = wsjtx
#DESTDIR = ../qt4_install
DESTDIR = ../wsjtx_install
VERSION = 1.1
TEMPLATE = app
#DEFINES = QT4
DEFINES = QT5
#DEFINES += QAUDIO_INPUT

win32 {
DEFINES += WIN32
F90 = g95
g95.output = ${QMAKE_FILE_BASE}.o
g95.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
g95.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += g95
}

unix {
DEFINES += UNIX
F90 = gfortran
gfortran.output = ${QMAKE_FILE_BASE}.o
gfortran.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
gfortran.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += gfortran
}

SOURCES += main.cpp mainwindow.cpp plotter.cpp about.cpp \
    soundin.cpp soundout.cpp devsetup.cpp widegraph.cpp \
    getfile.cpp displaytext.cpp getdev.cpp logqso.cpp \
    psk_reporter.cpp rigclass.cpp \
    signalmeter.cpp \
    meterwidget.cpp \
    logbook/logbook.cpp \
    logbook/countrydat.cpp \
    logbook/countriesworked.cpp \
    logbook/adif.cpp

win32 {
SOURCES += killbyname.cpp
}

HEADERS  += mainwindow.h plotter.h soundin.h soundout.h \
            about.h devsetup.h widegraph.h getfile.h \
            commons.h sleep.h displaytext.h logqso.h \
            psk_reporter.h rigclass.h \
    signalmeter.h \
    meterwidget.h \
    logbook/logbook.h \
    logbook/countrydat.h \
    logbook/countriesworked.h \
    logbook/adif.h

# (Is the following really needed???)
#DEFINES += __cplusplus

FORMS    += mainwindow.ui about.ui devsetup.ui widegraph.ui \
    logqso.ui

RC_FILE = wsjtx.rc

unix {
LIBS += ../wsjtx/lib/libjt9.a
LIBS += -lhamlib
LIBS += -lportaudio -lgfortran -lfftw3f
}

win32 {
INCLUDEPATH += ../../hamlib-1.2.15.3/include
LIBS += ../../hamlib-1.2.15.3/src/.libs/libhamlib.dll.a
#LIBS += ../../hamlib-1.2.15.3/lib/gcc/libhamlib.dll.a
LIBS += ../wsjtx/lib/libjt9.a
LIBS += ../wsjtx/libfftw3f_win.a
LIBS += ../wsjtx/libpskreporter.a
LIBS += ../wsjtx/libHRDInterface001.a
#LIBS += ../QtSupport/palir-02.dll
LIBS += /users/joe/wsjt/QtSupport/palir-02.dll
LIBS += libwsock32
LIBS += C:/MinGW/lib/libf95.a

}
