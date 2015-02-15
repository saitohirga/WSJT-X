// -*- Mode: C++ -*-
#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QThread>
#include <QTimer>
#include <QDateTime>
#include <QList>
#include <QAudioDeviceInfo>
#include <QScopedPointer>
#include <QDir>
#include <QProgressDialog>

#include "soundin.h"
#include "AudioDevice.hpp"
#include "soundout.h"
#include "commons.h"
#include "Radio.hpp"
#include "Configuration.hpp"
#include "Transceiver.hpp"
#include "psk_reporter.h"
#include "signalmeter.h"
#include "logbook/logbook.h"
#include "Detector.hpp"
#include "Modulator.hpp"
#include "decodedtext.h"


#define NUM_JT65_SYMBOLS 126
#define NUM_JT9_SYMBOLS 85
#define NUM_CW_SYMBOLS 250
#define TX_SAMPLE_RATE 48000

extern int volatile itone[NUM_JT65_SYMBOLS]; //Audio tones for all Tx symbols
extern int volatile icw[NUM_CW_SYMBOLS];	    //Dits for CW ID


//--------------------------------------------------------------- MainWindow
namespace Ui {
  class MainWindow;
}

class QSettings;
class QLineEdit;
class QFont;
class WideGraph;
class LogQSO;
class Transceiver;
class Astro;

class MainWindow : public QMainWindow
{
  Q_OBJECT;

public:
  using Frequency = Radio::Frequency;

  // Multiple instances: call MainWindow() with *thekey
  explicit MainWindow(bool multiple, QSettings *, QSharedMemory *shdmem,
                      unsigned downSampleFactor, QWidget *parent = 0);
  ~MainWindow();

public slots:
  void showSoundInError(const QString& errorMsg);
  void showSoundOutError(const QString& errorMsg);
  void showStatusMessage(const QString& statusMsg);
  void dataSink(qint64 frames);
  void diskDat();
  void diskWriteFinished();
  void freezeDecode(int n);
  void guiUpdate();
  void doubleClickOnCall(bool shift, bool ctrl);
  void doubleClickOnCall2(bool shift, bool ctrl);
  void readFromStdout();
  void readFromStderr();
  void jt9_error(QProcess::ProcessError);
  void setXIT(int n);
  void setFreq4(int rxFreq, int txFreq);

protected:
  virtual void keyPressEvent( QKeyEvent *e );
  void  closeEvent(QCloseEvent*);
  virtual bool eventFilter(QObject *object, QEvent *event);

private slots:
  void on_tx1_editingFinished();
  void on_tx2_editingFinished();
  void on_tx3_editingFinished();
  void on_tx4_editingFinished();
  void on_tx5_currentTextChanged (QString const&);
  void on_tx6_editingFinished();
  void on_actionSettings_triggered();
  void on_monitorButton_clicked (bool);
  void on_actionAbout_triggered();
  void on_autoButton_clicked (bool);
  void on_stopTxButton_clicked();
  void on_stopButton_clicked();
  void on_actionOnline_User_Guide_triggered();
  void on_actionLocal_User_Guide_triggered();
  void on_actionWide_Waterfall_triggered();
  void on_actionOpen_triggered();
  void on_actionOpen_next_in_directory_triggered();
  void on_actionDecode_remaining_files_in_directory_triggered();
  void on_actionDelete_all_wav_files_in_SaveDir_triggered();
  void on_actionOpen_log_directory_triggered ();
  void on_actionNone_triggered();
  void on_actionSave_all_triggered();
  void on_actionKeyboard_shortcuts_triggered();
  void on_actionSpecial_mouse_commands_triggered();
  void on_DecodeButton_clicked (bool);
  void decode();
  void decodeBusy(bool b);
  void on_EraseButton_clicked();
  void on_txb1_clicked();
  void on_txFirstCheckBox_stateChanged(int arg1);
  void set_ntx(int n);
  void on_txb2_clicked();
  void on_txb3_clicked();
  void on_txb4_clicked();
  void on_txb5_clicked();
  void on_txb6_clicked();
  void on_lookupButton_clicked();
  void on_addButton_clicked();
  void on_dxCallEntry_textChanged(const QString &arg1);
  void on_dxGridEntry_textChanged(const QString &arg1);
  void on_genStdMsgsPushButton_clicked();
  void on_logQSOButton_clicked();
  void on_actionJT9_1_triggered();
  void on_actionJT65_triggered();
  void on_actionJT9_JT65_triggered();
  void on_TxFreqSpinBox_valueChanged(int arg1);
  void on_actionSave_decoded_triggered();
  void on_actionQuickDecode_triggered();
  void on_actionMediumDecode_triggered();
  void on_actionDeepestDecode_triggered();
  void on_inGain_valueChanged(int n);
  void bumpFqso(int n);
  void on_actionErase_ALL_TXT_triggered();
  void on_actionErase_wsjtx_log_adi_triggered();
  void startTx2();
  void stopTx();
  void stopTx2();
  void on_pbCallCQ_clicked();
  void on_pbAnswerCaller_clicked();
  void on_pbSendRRR_clicked();
  void on_pbAnswerCQ_clicked();
  void on_pbSendReport_clicked();
  void on_pbSend73_clicked();
  void on_rbGenMsg_toggled(bool checked);
  void on_rbFreeText_toggled(bool checked);
  void on_freeTextMsg_currentTextChanged (QString const&);
  void on_rptSpinBox_valueChanged(int n);
  void killFile();
  void on_tuneButton_clicked (bool);
  void on_pbR2T_clicked();
  void on_pbT2R_clicked();
  void acceptQSO2(bool accepted);
  void on_bandComboBox_activated (int index);
  void on_readFreq_clicked();
  void on_pbTxMode_clicked();
  void on_RxFreqSpinBox_valueChanged(int n);
  void on_cbTxLock_clicked(bool checked);
  void on_cbPlus2kHz_toggled(bool checked);
  void on_outAttenuation_valueChanged (int);
  void rigOpen ();
  void handle_transceiver_update (Transceiver::TransceiverState);
  void handle_transceiver_failure (QString reason);
  void on_actionAstronomical_data_triggered();
  void on_actionShort_list_of_add_on_prefixes_and_suffixes_triggered();
  void getpfx();
  void on_actionJT9W_1_triggered();

  void band_changed (Frequency);
  void monitor (bool);
  void stop_tuning ();
  void auto_tx_mode (bool);

private:
  void enable_DXCC_entity (bool on);

  Q_SIGNAL void initializeAudioOutputStream (QAudioDeviceInfo, unsigned channels, unsigned msBuffered) const;
  Q_SIGNAL void stopAudioOutputStream () const;

  Q_SIGNAL void startAudioInputStream (QAudioDeviceInfo const&, int framesPerBuffer, AudioDevice * sink, unsigned downSampleFactor, AudioDevice::Channel) const;
  Q_SIGNAL void suspendAudioInputStream () const;
  Q_SIGNAL void resumeAudioInputStream () const;

  Q_SIGNAL void startDetector (AudioDevice::Channel) const;
  Q_SIGNAL void detectorClose () const;

  Q_SIGNAL void finished () const;
  Q_SIGNAL void transmitFrequency (unsigned) const;
  Q_SIGNAL void endTransmitMessage (bool quick = false) const;
  Q_SIGNAL void tune (bool = true) const;
  Q_SIGNAL void sendMessage (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, double toneSpacing, SoundOutput *, AudioDevice::Channel = AudioDevice::Mono, bool synchronize = true, double dBSNR = 99.) const;
  Q_SIGNAL void outAttenuationChanged (qreal) const;

private:
  QDir m_dataDir;
  QString m_revision;
  bool m_multiple;
  QSettings * m_settings;

  QScopedPointer<Ui::MainWindow> ui;

  // other windows
  Configuration m_config;
  QMessageBox m_rigErrorMessageBox;

  QScopedPointer<WideGraph> m_wideGraph;
  QScopedPointer<LogQSO> m_logDlg;
  QScopedPointer<Astro> m_astroWidget;
  QScopedPointer<QTextEdit> m_shortcuts;
  QScopedPointer<QTextEdit> m_prefixes;
  QScopedPointer<QTextEdit> m_mouseCmnds;

  Frequency  m_dialFreq;

  Detector m_detector;
  SoundInput m_soundInput;
  Modulator m_modulator;
  SoundOutput m_soundOutput;
  QThread * m_audioThread;

  qint64  m_msErase;
  qint64  m_secBandChanged;

  qint32  m_waterfallAvg;
  qint32  m_ntx;
  qint32  m_timeout;
  qint32  m_XIT;
  qint32  m_setftx;
  qint32  m_ndepth;
  qint32  m_sec0;
  qint32  m_RxLog;
  qint32  m_nutc0;
  qint32  m_nrx;
  qint32  m_hsym;
  qint32  m_TRperiod;
  qint32  m_nsps;
  qint32  m_hsymStop;
  qint32  m_len1;
  qint32  m_inGain;
  qint32  m_nsave;
  qint32  m_ncw;
  qint32  m_secID;
  qint32  m_repeatMsg;
  qint32  m_watchdogLimit;
  qint32  m_astroFont;

  bool    m_btxok;		//True if OK to transmit
  bool    m_diskData;
  bool    m_loopall;
  bool    m_decoderBusy;
  bool    m_txFirst;
  bool    m_auto;
  bool    m_restart;
  bool    m_startAnother;
  bool    m_saveDecoded;
  bool    m_saveAll;
  bool    m_widebandDecode;
  bool    m_call3Modified;
  bool    m_dataAvailable;
  bool    m_killAll;
  bool    m_bdecoded;
  bool    m_monitorStartOFF;
  bool    m_pskReporterInit;
  bool    m_noSuffix;
  bool    m_toRTTY;
  bool    m_dBtoComments;
  bool    m_promptToLog;
  bool    m_blankLine;
  bool    m_insertBlank;
  bool    m_displayDXCCEntity;
  bool    m_clearCallGrid;
  bool    m_bMiles;
  bool    m_decodedText2;
  bool    m_freeText;
  bool    m_quickCall;
  bool    m_73TxDisable;
  bool    m_sent73;
  bool    m_runaway;
  bool    m_bMultipleOK;
  bool    m_lockTxFreq;
  bool    m_tx2QSO;
  bool    m_CATerror;
  bool    m_plus2kHz;
  bool    m_bAstroData;

  float   m_pctZap;

  // labels in status bar
  QLabel * tx_status_label;
  QLabel * mode_label;
  QLabel * last_tx_label;
  QLabel * auto_tx_label;

  QMessageBox msgBox0;

  QFuture<void>* future1;
  QFuture<void>* future2;
  QFuture<void>* future3;
  QFutureWatcher<void>* watcher1;
  QFutureWatcher<void>* watcher2;
  QFutureWatcher<void>* watcher3;

  QProcess proc_jt9;

  QTimer m_guiTimer;
  QTimer* ptt1Timer;                 //StartTx delay
  QTimer* ptt0Timer;                 //StopTx delay
  QTimer* logQSOTimer;
  QTimer* killFileTimer;
  QTimer* tuneButtonTimer;

  QString m_path;
  QString m_pbdecoding_style1;
  QString m_pbmonitor_style;
  QString m_pbAutoOn_style;
  QString m_pbTune_style;
  QString m_baseCall;
  QString m_hisCall;
  QString m_hisGrid;
  QString m_appDir;
  QString m_dxccPfx;
  QString m_palette;
  QString m_dateTime;
  QString m_mode;
  QString m_modeTx;
  QString m_fname;
  QString m_rpt;
  QString m_rptSent;
  QString m_rptRcvd;
  QString m_qsoStart;
  QString m_qsoStop;
  QString m_cmnd;
  QString m_msgSent0;
  QString m_fileToSave;
  QString  m_band;

  QStringList m_prefix;
  QStringList m_suffix;

  QHash<QString,bool> m_pfx;
  QHash<QString,bool> m_sfx;

  QDateTime m_dateTimeQSO;
  QRect   m_astroGeom;

  QSharedMemory *mem_jt9;
  PSK_Reporter *psk_Reporter;
  SignalMeter *signalMeter;
  LogBook m_logBook;
  DecodedText m_QSOText;
  unsigned m_msAudioOutputBuffered;
  unsigned m_framesAudioInputBuffered;
  unsigned m_downSampleFactor;
  QThread::Priority m_audioThreadPriority;
  bool m_bandEdited;
  bool m_splitMode;
  bool m_monitoring;
  bool m_transmitting;
  bool m_tune;
  Frequency m_lastMonitoredFrequency;
  double m_toneSpacing;
  int m_firstDecode;
  QProgressDialog m_optimizingProgress;

  //---------------------------------------------------- private functions
  void readSettings();
  void setDecodedTextFont (QFont const&);
  void writeSettings();
  void createStatusBar();
  void updateStatusBar();
  void msgBox(QString t);
  void genStdMsgs(QString rpt);
  void lookup();
  void ba2msg(QByteArray ba, char* message);
  void msgtype(QString t, QLineEdit* tx);
  void stub();
  void statusChanged();
  void qsy(Frequency f);
  bool gridOK(QString g);
  bool shortList(QString callsign);
  QString baseCall(QString t);
  void transmit (double snr = 99.);
  void rigFailure (QString const& reason, QString const& detail);
  void pskSetLocal ();
  void displayDialFrequency ();
  void transmitDisplay (bool);
};

extern void getfile(QString fname, int ntrperiod);
extern void savewav(QString fname, int ntrperiod);
extern int killbyname(const char* progName);
extern void getDev(int* numDevices,char hostAPI_DeviceName[][50],
                   int minChan[], int maxChan[],
                   int minSpeed[], int maxSpeed[]);
extern int ptt(int nport, int ntx, int* iptt, int* nopen);

extern "C" {
  //----------------------------------------------------- C and Fortran routines
  void symspec_(int* k, int* ntrperiod, int* nsps, int* ingain, int* nflatten,
                float* px, float s[], float* df3, int* nhsym, int* npts8);

  void genjt9_(char* msg, int* ichk, char* msgsent, int itone[],
               int* itext, int len1, int len2);

  void gen65_(char* msg, int* ichk, char* msgsent, int itone[],
              int* itext, int len1, int len2);

  bool stdmsg_(const char* msg, int len);

  void azdist_(char* MyGrid, char* HisGrid, double* utch, int* nAz, int* nEl,
               int* nDmiles, int* nDkm, int* nHotAz, int* nHotABetter,
               int len1, int len2);

  void morse_(char* msg, int* icw, int* ncw, int len);

  int ptt_(int nport, int ntx, int* iptt, int* nopen);

  int fftwf_import_wisdom_from_filename(const char *);
  int fftwf_export_wisdom_to_filename(const char *);

}

#endif // MAINWINDOW_H
