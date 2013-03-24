#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#include <QtGui>
#include <QTimer>
#include <QDateTime>
#include "soundin.h"
#include "soundout.h"
#include "commons.h"

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

public:
  explicit MainWindow(QWidget *parent = 0);
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
  void readFromStdout();
  void readFromStderr();
  void jt9_error();

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
  void on_tolSlider_valueChanged(int arg1);
  void on_stopButton_clicked();
  void on_actionOnline_Users_Guide_triggered();
  void on_actionWide_Waterfall_triggered();
  void on_actionOpen_triggered();
  void on_actionOpen_next_in_directory_triggered();
  void on_actionDecode_remaining_files_in_directory_triggered();
  void on_actionDelete_all_wav_files_in_SaveDir_triggered();
  void on_actionF4_sets_Tx6_triggered();
  void on_actionNo_shorthands_if_Tx1_triggered();
  void on_actionNone_triggered();
  void on_actionSave_all_triggered();
  void on_actionKeyboard_shortcuts_triggered();
  void on_actionSpecial_mouse_commands_triggered();
  void on_actionAvailable_suffixes_and_add_on_prefixes_triggered();
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
  void on_actionJT9_2_triggered();
  void on_actionJT9_1_triggered();
  void on_actionJT9_5_triggered();
  void on_actionJT9_30_triggered();
  void on_actionJT9_10_triggered();
  void on_NBcheckBox_toggled(bool checked);
  void on_NBslider_valueChanged(int value);
  void on_TxFreqSpinBox_valueChanged(int arg1);
  void on_actionSave_synced_triggered();
  void on_actionSave_decoded_triggered();
  void on_actionQuickDecode_triggered();
  void on_actionMediumDecode_triggered();
  void on_actionDeepestDecode_triggered();
  void on_inGain_valueChanged(int n);
  void bumpFqso(int n);
  void on_actionMonitor_OFF_at_startup_triggered();
  void dialFreqChanged2(double f);
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

  void on_bandComboBox_currentIndexChanged(int index);

private:
    Ui::MainWindow *ui;

    double  m_dialFreq;

    qint32  m_nDevIn;
    qint32  m_nDevOut;
    qint32  m_idInt;
    qint32  m_waterfallAvg;
    qint32  m_pttMethodIndex;
    qint32  m_tol;
    qint32  m_QSOfreq0;
    qint32  m_ntx;
    qint32  m_pttPort;
    qint32  m_timeout;
    qint32  m_txFreq;
    qint32  m_setftx;
    qint32  m_ndepth;
    qint32  m_sec0;
    qint32  m_RxLog;
    qint32  m_nutc0;
    qint32  m_nrx;
    qint32  m_hsym0;
    qint32  m_paInDevice;
    qint32  m_paOutDevice;
    qint32  m_NBslider;
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
    qint32  m_COMportOpen;
    qint32  m_iptt;
    qint32  m_band;

    bool    m_monitoring;
    bool    m_transmitting;
    bool    m_diskData;
    bool    m_loopall;
    bool    m_decoderBusy;
    bool    m_txFirst;
    bool    m_auto;
    bool    m_restart;
    bool    m_startAnother;
    bool    m_saveSynced;
    bool    m_saveDecoded;
    bool    m_saveAll;
    bool    m_widebandDecode;
    bool    m_kb8rq;
    bool    m_NB;
    bool    m_call3Modified;
    bool    m_dataAvailable;
    bool    m_killAll;
    bool    m_bsynced;
    bool    m_bdecoded;
    bool    m_monitorStartOFF;
    bool    m_pskReporter;
    bool    m_pskReporterInit;
    bool    m_noSuffix;
    bool    m_toRTTY;
    bool    m_dBtoComments;
    bool    m_catEnabled;

    char    m_decoded[80];

    float   m_pctZap;

    QRect   m_wideGraphGeom;

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
    QProcess p3;

    QTimer* ptt0Timer;
    QTimer* ptt1Timer;

    QString m_path;
    QString m_pbdecoding_style1;
    QString m_pbmonitor_style;
    QString m_pbAutoOn_style;
    QString m_myCall;
    QString m_myGrid;
    QString m_hisCall;
    QString m_hisGrid;
    QString m_appDir;
    QString m_saveDir;
    QString m_dxccPfx;
    QString m_palette;
    QString m_dateTime;
    QString m_mode;
    QString m_fname;
    QString m_rptSent;
    QString m_rptRcvd;
    QString m_qsoStart;
    QString m_qsoStop;
    QString m_catPort;
    QString m_handshake;
    QStringList m_macro;
    QString m_cmnd;

    SoundInThread soundInThread;             //Instantiate the audio threads
    SoundOutThread soundOutThread;

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
    bool gridOK(QString g);
    QString rig_command();
};

extern void getfile(QString fname, int ntrperiod);
extern void savewav(QString fname, int ntrperiod);
extern int killbyname(const char* progName);
extern void getDev(int* numDevices,char hostAPI_DeviceName[][50],
                   int minChan[], int maxChan[],
                   int minSpeed[], int maxSpeed[]);
extern int ptt(int nport, int itx, int* iptt);
//extern int ReporterInitialize(char* hostname, char* port);


extern "C" {
//----------------------------------------------------- C and Fortran routines
void symspec_(int* k, int* ntrperiod, int* nsps, int* ingain, int* nb,
              int* m_NBslider, float* px, float s[], float red[],
              float* df3, int* nhsym, int* nzap, float* slimit,
              uchar lstrong[], int* npts8);

void genjt9_(char* msg, int* ichk, char* msgsent, int itone[],
             int* itext, int len1, int len2);

bool stdmsg_(const char* msg);

void azdist_(char* MyGrid, char* HisGrid, double* utch, int* nAz, int* nEl,
             int* nDmiles, int* nDkm, int* nHotAz, int* nHotABetter,
             int len1, int len2);
}

#endif // MAINWINDOW_H
