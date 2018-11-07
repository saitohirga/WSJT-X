#-------------------------------------------------
#
# Project created by QtCreator 2011-07-07T08:39:24
#
#-------------------------------------------------

QT       += network multimedia
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets sql
CONFIG   += thread
#CONFIG   += console

TARGET = wsjtx
VERSION = "Not for Release"
TEMPLATE = app
DEFINES = QT5
QMAKE_CXXFLAGS += -std=c++11
DEFINES += PROJECT_MANUAL="'\"http://www.physics.princeton.edu/pulsar/K1JT/wsjtx-doc/wsjtx-main.html\"'"

isEmpty (DESTDIR) {
DESTDIR = ../wsjtx_exp_install
}

isEmpty (HAMLIB_DIR) {
HAMLIB_DIR = ../../hamlib3/mingw32
}

isEmpty (FFTW3_DIR) {
FFTW3_DIR = .
}

F90 = gfortran
gfortran.output = ${QMAKE_FILE_BASE}.o
gfortran.commands = $$F90 -c -O2 -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
gfortran.input = F90_SOURCES
QMAKE_EXTRA_COMPILERS += gfortran

win32 {
DEFINES += WIN32
QT += axcontainer
TYPELIBS = $$system(dumpcpp -getfile {4FE359C5-A58F-459D-BE95-CA559FB4F270})
}

unix {
DEFINES += UNIX
}

#
# Order matters here as the link is in this order so referrers need to be after referred
#
SOURCES += \
  logbook/adif.cpp logbook/countriesworked.cpp logbook/logbook.cpp \
        logbook/AD1CCty.cpp logbook/WorkedBefore.cpp \
  widgets/astro.cpp Radio.cpp NetworkServerLookup.cpp revision_utils.cpp \
  Transceiver.cpp TransceiverBase.cpp TransceiverFactory.cpp \
  PollingTransceiver.cpp EmulateSplitTransceiver.cpp widgets/LettersSpinBox.cpp \
  HRDTransceiver.cpp DXLabSuiteCommanderTransceiver.cpp \
  HamlibTransceiver.cpp FrequencyLineEdit.cpp models/Bands.cpp \
  models/FrequencyList.cpp models/StationList.cpp item_delegates/ForeignKeyDelegate.cpp \
  item_delegates/FrequencyItemDelegate.cpp validators/LiveFrequencyValidator.cpp \
  Configuration.cpp	psk_reporter.cpp AudioDevice.cpp \
  Modulator.cpp Detector.cpp widgets/logqso.cpp widgets/displaytext.cpp \
  getfile.cpp soundout.cpp soundin.cpp widgets/meterwidget.cpp widgets/signalmeter.cpp \
  WFPalette.cpp widgets/plotter.cpp widgets/widegraph.cpp widgets/about.cpp \
  WsprTxScheduler.cpp widgets/mainwindow.cpp \
  main.cpp decodedtext.cpp wsprnet.cpp widgets/messageaveraging.cpp \
  widgets/echoplot.cpp widgets/echograph.cpp widgets/fastgraph.cpp \
  widgets/fastplot.cpp models/Modes.cpp \
  WSPRBandHopping.cpp MessageAggregator.cpp SampleDownloader.cpp qt_helpers.cpp\
  MultiSettings.cpp PhaseEqualizationDialog.cpp models/IARURegions.cpp \
  widgets/MessageBox.cpp \
  EqualizationToolsDialog.cpp validators/CallsignValidator.cpp \
  widgets/colorhighlighting.cpp widgets/ExportCabrillo.cpp LotWUsers.cpp TraceFile.cpp

HEADERS  += qt_helpers.hpp \
  pimpl_h.hpp pimpl_impl.hpp \
  Radio.hpp NetworkServerLookup.hpp revision_utils.hpp \
  widgets/mainwindow.h widgets/plotter.h soundin.h soundout.h widgets/astro.h \
  widgets/about.h WFPalette.hpp widgets/widegraph.h getfile.h decodedtext.h \
  commons.h sleep.h widgets/displaytext.h widgets/logqso.h widgets/LettersSpinBox.hpp \
  models/Bands.hpp models/FrequencyList.hpp models/StationList.hpp \
  item_delegates/ForeignKeyDelegate.hpp item_delegates/FrequencyItemDelegate.hpp \
  validators/LiveFrequencyValidator.hpp \
  widgets/FrequencyLineEdit.hpp AudioDevice.hpp Detector.hpp Modulator.hpp psk_reporter.h \
  Transceiver.hpp TransceiverBase.hpp TransceiverFactory.hpp PollingTransceiver.hpp \
  EmulateSplitTransceiver.hpp DXLabSuiteCommanderTransceiver.hpp HamlibTransceiver.hpp \
  Configuration.hpp wsprnet.h widgets/signalmeter.h widgets/meterwidget.h logbook/WorkedBefore.hpp \
  logbook/logbook.h logbook/countriesworked.h logbook/adif.h logbook/AD1CCty.h \
  widgets/messageaveraging.h widgets/echoplot.h widgets/echograph.h widgets/fastgraph.h \
  widgets/fastplot.h models/Modes.hpp WSPRBandHopping.hpp \
  WsprTxScheduler.h SampleDownloader.hpp MultiSettings.hpp PhaseEqualizationDialog.hpp \
  models/IARURegions.hpp widgets/MessageBox.hpp EqualizationToolsDialog.hpp \
  validators/CallsignValidator.hpp \
  widgets/colorhighlighting.h widgets/ExportCabrillo.h LotWUsers.h TraceFile.hpp


INCLUDEPATH += qmake_only

win32 {
SOURCES += killbyname.cpp OmniRigTransceiver.cpp
HEADERS += OmniRigTransceiver.hpp
}

FORMS    += widgets/mainwindow.ui widgets/about.ui Configuration.ui \
    widgets/widegraph.ui widgets/astro.ui \
    widgets/logqso.ui wf_palette_design_dialog.ui widgets/messageaveraging.ui
    widgets/echograph.ui \
    widgets/fastgraph.ui widgets/colorhighlighting.ui wodgets/ExportCabrillo.ui \
    widgets/FoxLogWindow.ui

RC_FILE = wsjtx.rc
RESOURCES = wsjtx.qrc

unix {
LIBS += -L lib -ljt9
LIBS += -lhamlib
LIBS += -lfftw3f $$system($$F90 -print-file-name=libgfortran.so)
}

win32 {
INCLUDEPATH += $${HAMLIB_DIR}/include
INCLUDEPATH += C:\JTSDK\wsjtx_exp\build\Release
INCLUDEPATH += C:\JTSDK\hamlib3\include
INCLUDEPATH += C:\JTSDK\qt5\5.2.1\mingw48_32\include\QtSerialPort

LIBS += -L$${HAMLIB_DIR}/lib -lhamlib
LIBS += -L./lib -lastro -ljt9
LIBS += -L$${FFTW3_DIR} -lfftw3f-3
LIBS += -lws2_32
LIBS += $$system($$F90 -print-file-name=libgfortran.a)
}
