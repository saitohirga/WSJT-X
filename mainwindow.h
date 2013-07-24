#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QTimer>
#include <QDateTime>
#include "soundin.h"
#include "soundout.h"
#include "commons.h"
#include "psk_reporter.h"
#include "rigclass.h"
#include "signalmeter.h"

#ifdef WIN32
#include "PSKReporter.h"
#endif

//--------------------------------------------------------------- MainWindow
namespace Ui {
    class MainWindow;
}

class MainWindow : public QMainWindow
{
  Q_OBJECT

// Multiple instances: call MainWindow() with *thekey
public:
  explicit MainWindow(QSharedMemory *shdmem, QString *thekey, \
                      qint32 fontSize2, qint32 fontWeight2, \
                      QWidget *parent = 0);
  ~MainWindow();

public slots:
  void showSoundInError(const QString& errorMsg);
  void showStatusMessage(const QString& statusMsg);
  void dataSink(int k);
  void diskDat();
  void diskWriteFinished();
  void freezeDecode(int n);
  void guiUpdate();
  void doubleClickOnCall(bool shift, bool ctrl);
  void doubleClickOnCall2(bool shift, bool ctrl);
  void readFromStdout();
  void readFromStderr();
  void jt9_error();
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
  void on_tx5_editingFinished();
  void on_tx6_editingFinished();
  void on_actionDeviceSetup_triggered();
  void on_monitorButton_clicked();
  void on_actionExit_triggered();
  void on_actionAbout_triggered();
  void OnExit();
  void on_actionLinrad_triggered();
  void on_actionCuteSDR_triggered();
  void on_autoButton_clicked();
  void on_stopTxButton_clicked();
  void on_stopButton_clicked();
  void on_actionOnline_Users_Guide_triggered();
  void on_actionWide_Waterfall_triggered();
  void on_actionOpen_triggered();
  void on_actionOpen_next_in_directory_triggered();
  void on_actionDecode_remaining_files_in_directory_triggered();
  void on_actionDelete_all_wav_files_in_SaveDir_triggered();
  void on_actionNone_triggered();
  void on_actionSave_all_triggered();
  void on_actionKeyboard_shortcuts_triggered();
  void on_actionSpecial_mouse_commands_triggered();
  void on_DecodeButton_clicked();
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
  void on_actionAFMHot_triggered();
  void on_actionBlue_triggered();
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
  void on_actionMonitor_OFF_at_startup_triggered();
  void on_actionErase_ALL_TXT_triggered();
  void on_actionErase_wsjtx_log_adi_triggered();
  void showMacros(const QPoint& pos);
  void onPopup1();
  void onPopup2();
  void onPopup3();
  void onPopup4();
  void onPopup5();
  void onPopup6();
  void onPopup7();
  void onPopup8();
  void onPopup9();
  void onPopup10();
  void on_actionConvert_JT9_x_to_RTTY_triggered(bool checked);
  void on_actionLog_JT9_without_submode_triggered(bool checked);
  void on_actionLog_dB_reports_to_Comments_triggered(bool checked);
  void startTx2();
  void stopTx();
  void stopTx2();
  void on_actionPrompt_to_log_QSO_triggered(bool checked);
  void on_actionBlank_line_between_decoding_periods_triggered(bool checked);
  void on_actionClear_DX_Call_and_Grid_after_logging_triggered(bool checked);
  void on_actionDisplay_distance_in_miles_triggered(bool checked);
  void on_pbCallCQ_clicked();
  void on_pbAnswerCaller_clicked();
  void on_pbSendRRR_clicked();
  void on_pbAnswerCQ_clicked();
  void on_pbSendReport_clicked();
  void on_pbSend73_clicked();
  void on_rbGenMsg_toggled(bool checked);
  void on_rbFreeText_toggled(bool checked);
  void on_freeTextMsg_editingFinished();
  void on_actionDouble_click_on_call_sets_Tx_Enable_triggered(bool checked);
  void on_rptSpinBox_valueChanged(int n);
  void on_action_73TxDisable_triggered(bool checked);
  void on_actionRunaway_Tx_watchdog_triggered(bool checked);
  void killFile();
  void on_tuneButton_clicked();
  void on_actionAllow_multiple_instances_triggered(bool checked);
  void on_pbR2T_clicked();
  void on_pbT2R_clicked();
  void acceptQSO2(bool accepted);
  void on_bandComboBox_activated(int index);
  void on_readFreq_clicked();
  void on_pbTxMode_clicked();
  void on_RxFreqSpinBox_valueChanged(int n);
  void on_cbTxLock_clicked(bool checked);
  void on_actionTx2QSO_triggered(bool checked);  
  void on_cbPlus2kHz_toggled(bool checked);

private:
    Ui::MainWindow *ui;

    double  m_dialFreq;

    qint64  m_msErase;
    qint64  m_secBandChanged;

    qint32  m_idInt;
    qint32  m_waterfallAvg;
    qint32  m_pttMethodIndex;
    qint32  m_ntx;
    qint32  m_pttPort;
    qint32  m_timeout;
    qint32  m_rxFreq;
    qint32  m_txFreq;
    qint32  m_setftx;
    qint32  m_ndepth;
    qint32  m_sec0;
    qint32  m_RxLog;
    qint32  m_nutc0;
    qint32  m_nrx;
    qint32  m_hsym;
    qint32  m_paInDevice;
    qint32  m_paOutDevice;
    qint32  m_TRperiod;
    qint32  m_nsps;
    qint32  m_hsymStop;
    qint32  m_len1;
    qint32  m_inGain;
    qint32  m_nsave;
    qint32  m_catPortIndex;
    qint32  m_rig;
    qint32  m_rigIndex;
    qint32  m_serialRate;
    qint32  m_serialRateIndex;
    qint32  m_dataBits;
    qint32  m_dataBitsIndex;
    qint32  m_stopBits;
    qint32  m_stopBitsIndex;
    qint32  m_handshakeIndex;
    qint32  m_ncw;
    qint32  m_secID;
    qint32  m_band;
    qint32  m_repeatMsg;
    qint32  m_watchdogLimit;
    qint32  m_poll;
    qint32  m_fMin;
    qint32  m_fMax;
    qint32  m_bad;

    bool    m_monitoring;
    bool    m_transmitting;
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
    bool    m_pskReporter;
    bool    m_pskReporterInit;
    bool    m_noSuffix;
    bool    m_toRTTY;
    bool    m_dBtoComments;
    bool    m_catEnabled;
    bool    m_After73;
    bool    m_promptToLog;
    bool    m_blankLine;
    bool    m_insertBlank;
    bool    m_clearCallGrid;
    bool    m_bMiles;
    bool    m_decodedText2;
    bool    m_freeText;
    bool    m_quickCall;
    bool    m_73TxDisable;
    bool    m_sent73;
    bool    m_runaway;
    bool    m_tune;
    bool    m_bRigOpen;
    bool    m_bMultipleOK;
    bool    m_bDTR;
    bool    m_bRTS;
    bool    m_pttData;
    bool    m_dontReadFreq;
    bool    m_lockTxFreq;
    bool    m_saveTxPower;
    bool    m_saveComments;
    bool    m_tx2QSO;
    bool    m_CATerror;
    bool    m_bSplit;
    bool    m_bXIT;
    bool    m_plus2kHz;

    char    m_decoded[80];

    float   m_pctZap;

    QRect   m_wideGraphGeom;
    QRect   m_logQSOgeom;

    QLabel* lab1;                            // labels in status bar
    QLabel* lab2;
    QLabel* lab3;
    QLabel* lab4;
    QLabel* lab5;
    QLabel* lab6;

    QMessageBox msgBox0;

    QFuture<void>* future1;
    QFuture<void>* future2;
    QFuture<void>* future3;
    QFutureWatcher<void>* watcher1;
    QFutureWatcher<void>* watcher2;
    QFutureWatcher<void>* watcher3;

    QProcess proc_jt9;

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
    QString m_myCall;
    QString m_myGrid;
    QString m_baseCall;
    QString m_hisCall;
    QString m_hisGrid;
    QString m_appDir;
    QString m_saveDir;
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
    QString m_catPort;
    QString m_handshake;
    QString m_cmnd;
    QString m_msgSent0;
    QString m_fileToSave;
    QString m_QSOmsg;
    QString m_txPower;
    QString m_logComments;

    QStringList m_macro;
    QStringList m_dFreq;           // per band frequency in MHz as a string
    QStringList m_antDescription;  // per band antenna description
    QStringList m_bandDescription; // per band description

    QDateTime m_dateTimeQSO;

    SoundInThread soundInThread;             //Instantiate the audio threads
    SoundOutThread soundOutThread;
    QSharedMemory *mem_jt9;
 // Multiple instances:
    QString       *mykey_jt9;
    PSK_Reporter *psk_Reporter;
    SignalMeter *signalMeter;

//---------------------------------------------------- private functions
    void readSettings();
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
    void dialFreqChanged2(double f);
    void freeText();
    void displayTxMsg(QString t);
    void rigOpen();
    void pollRigFreq();
    bool gridOK(QString g);
    QString baseCall(QString t);
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
void symspec_(int* k, int* ntrperiod, int* nsps, int* ingain, float* slope,
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

}

#endif // MAINWINDOW_H
