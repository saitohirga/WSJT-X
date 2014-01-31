//---------------------------------------------------------- MainWindow
#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QThread>
#include <QColorDialog>

#include "soundout.h"
#include "devsetup.h"
#include "plotter.h"
#include "about.h"
#include "widegraph.h"
#include "sleep.h"
#include "getfile.h"
#include "logqso.h"

#ifdef QT5
#include <QtConcurrent/QtConcurrentRun>
#endif

int itone[NUM_JT65_SYMBOLS];	//Audio tones for all Tx symbols
int icw[NUM_CW_SYMBOLS];	//Dits for CW ID

int outBufSize;
int rc;
qint32  g_COMportOpen;
qint32  g_iptt;
static int nc1=1;
wchar_t buffer[256];


Rig* rig = NULL;
QTextEdit* pShortcuts;
QTextEdit* pPrefixes;
QTcpSocket* commanderSocket = new QTcpSocket(0);

QString rev="$Rev$";
QString Program_Title_Version="  WSJT-X   v1.3, r" + rev.mid(6,4) +
                              "    by K1JT";

//--------------------------------------------------- MainWindow constructor
// Multiple instances: new arg *thekey
MainWindow::MainWindow(QSettings * settings, QSharedMemory *shdmem, QString *thekey,
                       qint32 fontSize2, qint32 fontWeight2, unsigned downSampleFactor,
                       QWidget *parent) :
  QMainWindow(parent),
  m_settings (settings),
  ui(new Ui::MainWindow),
  m_wideGraph (new WideGraph (settings)),
  m_logDlg (new LogQSO (settings, this)),
  m_detector (RX_SAMPLE_RATE, NTMAX/2, 6912/2, downSampleFactor),
  m_audioInputDevice (QAudioDeviceInfo::defaultInputDevice ()), // start with default
  m_modulator (TX_SAMPLE_RATE, NTMAX / 2),
  m_audioOutputDevice (QAudioDeviceInfo::defaultOutputDevice ()), // start with default
  m_soundOutput (&m_modulator),
  psk_Reporter (new PSK_Reporter (this)),
  m_msAudioOutputBuffered (0u),
  m_framesAudioInputBuffered (RX_SAMPLE_RATE / 10),
  m_downSampleFactor (downSampleFactor),
  m_audioThreadPriority (QThread::HighPriority)
{
  ui->setupUi(this);

  connect (this, &MainWindow::finished, this, &MainWindow::close);

  // start audio thread and hook up slots & signals for shutdown management

  // these objects need to be in the audio thread so that invoking
  // their slots is done in a thread safe way
  m_soundOutput.moveToThread (&m_audioThread);
  m_modulator.moveToThread (&m_audioThread);
  m_soundInput.moveToThread (&m_audioThread);
  m_detector.moveToThread (&m_audioThread);

  connect (this, &MainWindow::finished, &m_audioThread, &QThread::quit); // quit thread event loop
  connect (&m_audioThread, &QThread::finished, &m_audioThread, &QThread::deleteLater); // disposal

  // hook up sound output stream slots & signals
  connect (this, SIGNAL (startAudioOutputStream (QAudioDeviceInfo const&, unsigned, unsigned)), &m_soundOutput, SLOT (startStream (QAudioDeviceInfo const&, unsigned, unsigned)));
  connect (this, SIGNAL (stopAudioOutputStream ()), &m_soundOutput, SLOT (stopStream ()));
  connect (&m_soundOutput, &SoundOutput::error, this, &MainWindow::showSoundOutError);
  // connect (&m_soundOutput, &SoundOutput::status, this, &MainWindow::showStatusMessage);
  connect (this, SIGNAL (outAttenuationChanged (qreal)), &m_soundOutput, SLOT (setAttenuation (qreal)));

  // hook up Modulator slots
  connect (this, SIGNAL (muteAudioOutput (bool)), &m_modulator, SLOT (mute (bool)));
  connect (this, SIGNAL(transmitFrequency (unsigned)), &m_modulator, SLOT (setFrequency (unsigned)));
  connect (this, SIGNAL (endTransmitMessage ()), &m_modulator, SLOT (close ()));
  connect (this, SIGNAL (tune (bool)), &m_modulator, SLOT (tune (bool)));
  connect (this, SIGNAL (sendMessage (unsigned, double, unsigned, AudioDevice::Channel, bool, double))
	   , &m_modulator, SLOT (open (unsigned, double, unsigned, AudioDevice::Channel, bool, double)));

  // hook up the audio input stream
  connect (this, SIGNAL (startAudioInputStream (QAudioDeviceInfo const&, unsigned, int, QIODevice *, unsigned))
	   , &m_soundInput, SLOT (start (QAudioDeviceInfo const&, unsigned, int, QIODevice *, unsigned)));
  connect (this, SIGNAL (stopAudioInputStream ()), &m_soundInput, SLOT (stop ()));

  connect(&m_soundInput, SIGNAL (error (QString)), this, SLOT (showSoundInError (QString)));
  // connect(&m_soundInput, SIGNAL(status(QString)), this, SLOT(showStatusMessage(QString)));

  // hook up the detector
  connect (this, SIGNAL (startDetector (AudioDevice::Channel)), &m_detector, SLOT (open (AudioDevice::Channel)));
  connect (this, SIGNAL (detectorSetMonitoring (bool)), &m_detector, SLOT (setMonitoring (bool)));
  connect (this, SIGNAL (detectorClose ()), &m_detector, SLOT (close ()));

  connect(&m_detector, SIGNAL (framesWritten (qint64)), this, SLOT (dataSink (qint64)));

  // setup the waterfall
  connect(m_wideGraph.data (), SIGNAL(freezeDecode2(int)),this,
	  SLOT(freezeDecode(int)));
  connect(m_wideGraph.data (), SIGNAL(f11f12(int)),this,
	  SLOT(bumpFqso(int)));
  connect(m_wideGraph.data (), SIGNAL(setXIT2(int)),this,
	  SLOT(setXIT(int)));
  //    connect(m_wideGraph.data (), SIGNAL(dialFreqChanged(double)),this,
  //            SLOT(dialFreqChanged2(double)));
  connect (this, &MainWindow::finished, m_wideGraph.data (), &WideGraph::close);


  // setup the log QSO dialog
  connect (m_logDlg.data (), SIGNAL (acceptQSO (bool)), this, SLOT (acceptQSO2 (bool)));


  on_EraseButton_clicked();

  QActionGroup* modeGroup = new QActionGroup(this);
  ui->actionJT9_1->setActionGroup(modeGroup);
  ui->actionJT65->setActionGroup(modeGroup);
  ui->actionJT9_JT65->setActionGroup(modeGroup);


  QActionGroup* saveGroup = new QActionGroup(this);
  ui->actionNone->setActionGroup(saveGroup);
  ui->actionSave_decoded->setActionGroup(saveGroup);
  ui->actionSave_all->setActionGroup(saveGroup);

  QActionGroup* DepthGroup = new QActionGroup(this);
  ui->actionQuickDecode->setActionGroup(DepthGroup);
  ui->actionMediumDecode->setActionGroup(DepthGroup);
  ui->actionDeepestDecode->setActionGroup(DepthGroup);

  QButtonGroup* txMsgButtonGroup = new QButtonGroup;
  txMsgButtonGroup->addButton(ui->txrb1,1);
  txMsgButtonGroup->addButton(ui->txrb2,2);
  txMsgButtonGroup->addButton(ui->txrb3,3);
  txMsgButtonGroup->addButton(ui->txrb4,4);
  txMsgButtonGroup->addButton(ui->txrb5,5);
  txMsgButtonGroup->addButton(ui->txrb6,6);
  connect(txMsgButtonGroup,SIGNAL(buttonClicked(int)),SLOT(set_ntx(int)));
  connect(ui->decodedTextBrowser2,SIGNAL(selectCallsign(bool,bool)),this,
          SLOT(doubleClickOnCall(bool,bool)));
  connect(ui->decodedTextBrowser,SIGNAL(selectCallsign(bool,bool)),this,
          SLOT(doubleClickOnCall2(bool,bool)));


  setWindowTitle(Program_Title_Version);
  createStatusBar();

  connect(&proc_jt9, SIGNAL(readyReadStandardOutput()),
                    this, SLOT(readFromStdout()));

  connect(&proc_jt9, SIGNAL(error(QProcess::ProcessError)),
          this, SLOT(jt9_error(QProcess::ProcessError)));

  connect(&proc_jt9, SIGNAL(readyReadStandardError()),
          this, SLOT(readFromStderr()));

  ui->bandComboBox->setEditable(true);
  ui->bandComboBox->lineEdit()->setReadOnly(true);
  ui->bandComboBox->lineEdit()->setAlignment(Qt::AlignCenter);
  for(int i = 0; i < ui->bandComboBox->count(); i++)
    ui->bandComboBox->setItemData(i, Qt::AlignCenter, Qt::TextAlignmentRole);

  ui->tx5->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(ui->tx5, SIGNAL(customContextMenuRequested(const QPoint&)),
      this, SLOT(showMacros(const QPoint&)));

  ui->freeTextMsg->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(ui->freeTextMsg, SIGNAL(customContextMenuRequested(const QPoint&)),
      this, SLOT(showMacros(const QPoint&)));

  QFont font=ui->decodedTextBrowser->font();
  font.setPointSize(fontSize2);
  font.setWeight(fontWeight2);
  ui->decodedTextBrowser->setFont(font);
  ui->decodedTextBrowser2->setFont(font);

  font=ui->readFreq->font();
  font.setFamily("helvetica");
  font.setPointSize(9);
  font.setWeight(75);
  ui->readFreq->setFont(font);

  connect(&m_guiTimer, SIGNAL(timeout()), this, SLOT(guiUpdate()));
  m_guiTimer.start(100);                            //Don't change the 100 ms!

  ptt0Timer = new QTimer(this);
  ptt0Timer->setSingleShot(true);
  connect (ptt0Timer, SIGNAL (timeout ()), &m_modulator, SLOT (close ()));
  connect(ptt0Timer, SIGNAL(timeout()), this, SLOT(stopTx2()));
  ptt1Timer = new QTimer(this);
  ptt1Timer->setSingleShot(true);
  connect(ptt1Timer, SIGNAL(timeout()), this, SLOT(startTx2()));

  logQSOTimer = new QTimer(this);
  logQSOTimer->setSingleShot(true);
  connect(logQSOTimer, SIGNAL(timeout()), this, SLOT(on_logQSOButton_clicked()));

  tuneButtonTimer= new QTimer(this);
  tuneButtonTimer->setSingleShot(true);
  connect (tuneButtonTimer, SIGNAL (timeout ()), &m_modulator, SLOT (close ()));
  connect(tuneButtonTimer, SIGNAL(timeout()), this,
          SLOT(on_stopTxButton_clicked()));

  killFileTimer = new QTimer(this);
  killFileTimer->setSingleShot(true);
  connect(killFileTimer, SIGNAL(timeout()), this, SLOT(killFile()));

  m_auto=false;
  m_waterfallAvg = 1;
  m_txFirst=false;
  Q_EMIT muteAudioOutput (false);
  m_btxMute=false;
  m_btxok=false;
  m_restart=false;
  m_transmitting=false;
  m_killAll=false;
  m_widebandDecode=false;
  m_ntx=1;
  m_myCall="";
  m_myGrid="FN20qi";
  m_appDir = QApplication::applicationDirPath();
  m_saveDir="/users/joe/wsjtx/install/save";
  m_rxFreq=1500;
  m_txFreq=1500;
  m_setftx=0;
  m_loopall=false;
  m_startAnother=false;
  m_saveDecoded=false;
  m_saveAll=false;
  m_sec0=-1;
  m_palette="Linrad";
  m_RxLog=1;                     //Write Date and Time to RxLog
  m_nutc0=9999;
  m_mode="JT9";
  m_rpt="-15";
  m_TRperiod=60;
  m_inGain=0;
  m_dataAvailable=false;
  g_iptt=0;
  g_COMportOpen=0;
  m_secID=0;
  m_promptToLog=false;
  m_blankLine=false;
  m_insertBlank=false;
  m_displayDXCCEntity=false;
  m_clearCallGrid=false;
  m_bMiles=false;
  m_decodedText2=false;
  m_freeText=false;
  m_msErase=0;
  m_sent73=false;
  m_watchdogLimit=5;
  m_tune=false;
  m_repeatMsg=0;
  m_bRigOpen=false;
  m_secBandChanged=0;
  m_bMultipleOK=false;
  m_dontReadFreq=false;
  m_lockTxFreq=false;
  ui->readFreq->setEnabled(false);
  m_QSOText.clear();
  m_CATerror=false;
  decodeBusy(false);

  signalMeter = new SignalMeter(ui->meterFrame);
  signalMeter->resize(50, 160);

  ui->labAz->setStyleSheet("border: 0px;");
  ui->labDist->setStyleSheet("border: 0px;");

  mem_jt9 = shdmem;
// Multiple instances:
  mykey_jt9 = thekey;

  //Band Settings
  readSettings();		         //Restore user's setup params

  // start the audio thread
  m_audioThread.start (m_audioThreadPriority);

#ifdef WIN32
  if(!m_bMultipleOK) {
    while(true) {
      int iret=killbyname("jt9.exe");
      if(iret == 603) break;
      if(iret != 0) msgBox("KillByName return code: " +
                           QString::number(iret));
    }
  }
#endif

  if(m_dFreq.length()<=1) {      //Use the startup default frequencies and band descriptions
    // default bands and JT65 frequencies
    const double dFreq[]={0.13613,0.4742,1.838,3.576,5.357,7.076,10.138,14.076,
                 18.102,21.076,24.917,28.076,50.276,70.091,144.489,432.178};
    const QStringList dBandDescription = QStringList() << "2200 m" << "630 m" << "160 m"
                                                 << "80 m" << "60 m" << "40 m"
                                                 << "30 m" << "20 m" << "17 m"
                                                 << "15 m" << "12 m" << "10 m"
                                                 << "6 m" << "4 m" << "2 m"
                                                 << "other";
    m_dFreq.clear();
    m_antDescription.clear();
    m_bandDescription.clear();
    for(int i=0; i<16; i++) {
      QString t;
      t.sprintf("%f",dFreq[i]);
      m_dFreq.append(t);
      m_antDescription.append("");
      m_bandDescription.append(dBandDescription[i]);
    }
  }

  ui->bandComboBox->clear();
  ui->bandComboBox->addItems(m_bandDescription);
  ui->bandComboBox->setCurrentIndex(m_band);

  {
    //delete any .quit file that might have been left lying around
    //since its presence will cause jt9 to exit a soon as we start it
    //and decodes will hang
    QString quitFileName (m_appDir + "/.quit");
    QFile quitFile (quitFileName);
    while (quitFile.exists ())
      {
	if (!quitFile.remove ())
	  {
	    msgBox ("Error removing " + quitFileName + " - OK to retry.");
	  }
      }
  }

  QFile lockFile(m_appDir + "/.lock");     //Create .lock so jt9 will wait
  lockFile.open(QIODevice::ReadWrite);

// Multiple instances: make the Qstring key into command line arg
// Multiple instances: start "jt9 -s <thekey>"
  QByteArray  ba = mykey_jt9->toLocal8Bit();
  const char *bc = ba.data();
//  proc_jt9.start(QDir::toNativeSeparators('"' + m_appDir + '"' + "/jt9 -s " + bc));
  QByteArray lda = m_appDir.toLocal8Bit();
  const char *ldir = lda.data();
  proc_jt9.start(QDir::toNativeSeparators('"' + m_appDir + "\"/jt9 -s " + bc + " \"" + ldir + '"'));

  m_pbdecoding_style1="QPushButton{background-color: cyan; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbmonitor_style="QPushButton{background-color: #00ff00; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbAutoOn_style="QPushButton{background-color: red; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbTune_style="QPushButton{background-color: red; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";

  getpfx();                               //Load the prefix/suffix dictionary
  genStdMsgs(m_rpt);
  m_ntx=6;
  ui->txrb6->setChecked(true);
  if(m_mode!="JT9" and m_mode!="JT65" and m_mode!="JT9+JT65") m_mode="JT9";
  on_actionWide_Waterfall_triggered();                   //###
  m_wideGraph->setRxFreq(m_rxFreq);
  m_wideGraph->setTxFreq(m_txFreq);
  m_wideGraph->setLockTxFreq(m_lockTxFreq);
  m_wideGraph->setModeTx(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  dialFreqChanged2(m_dialFreq);

  connect(m_wideGraph.data (), SIGNAL(setFreq3(int,int)),this,
          SLOT(setFreq4(int,int)));

  if(m_mode=="JT9") on_actionJT9_1_triggered();
  if(m_mode=="JT65") on_actionJT65_triggered();
  if(m_mode=="JT9+JT65") on_actionJT9_JT65_triggered();

  future1 = new QFuture<void>;
  watcher1 = new QFutureWatcher<void>;
  connect(watcher1, SIGNAL(finished()),this,SLOT(diskDat()));

  future2 = new QFuture<void>;
  watcher2 = new QFutureWatcher<void>;
  connect(watcher2, SIGNAL(finished()),this,SLOT(diskWriteFinished()));

  Q_EMIT startDetector (m_audioInputChannel);
  Q_EMIT startAudioInputStream (m_audioInputDevice, AudioDevice::Mono == m_audioInputChannel ? 1 : 2, m_framesAudioInputBuffered, &m_detector, m_downSampleFactor);

  Q_EMIT transmitFrequency (m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0));
  Q_EMIT muteAudioOutput (false);
  m_monitoring=!m_monitorStartOFF;           // Start with Monitoring ON/OFF
  Q_EMIT detectorSetMonitoring (m_monitoring);
  m_diskData=false;

// Create "m_worked", a dictionary of all calls in wsjtx.log
  QFile f("wsjtx.log");
  f.open(QIODevice::ReadOnly | QIODevice::Text);
  QTextStream in(&f);
  QString line,t,callsign;
  for(int i=0; i<99999; i++) {
    line=in.readLine();
    if(line.length()<=0) break;
    t=line.mid(18,12);
    callsign=t.mid(0,t.indexOf(","));
  }
  f.close();

  ui->decodedTextLabel->setFont(ui->decodedTextBrowser->font());
  ui->decodedTextLabel2->setFont(ui->decodedTextBrowser2->font());
  t="UTC   dB   DT Freq   Message";
  ui->decodedTextLabel->setText(t);
  ui->decodedTextLabel2->setText(t);

  psk_Reporter->setLocalStation(m_myCall,m_myGrid, m_antDescription[m_band], "WSJT-X r" + rev.mid(6,4) );

  on_actionEnable_DXCC_entity_triggered(m_displayDXCCEntity);  // sets text window proportions and (re)inits the logbook

  ui->label_9->setStyleSheet("QLabel{background-color: #aabec8}");
  ui->label_10->setStyleSheet("QLabel{background-color: #aabec8}");
  ui->labUTC->setStyleSheet( \
        "QLabel { background-color : black; color : yellow; }");
  ui->labDialFreq->setStyleSheet( \
        "QLabel { background-color : black; color : yellow; }");

  QFile f2("ALL.TXT");
  f2.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
  QTextStream out(&f2);
  out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
      << "  " << m_dialFreq << " MHz  " << m_mode << endl;
  f2.close();
}                                          // End of MainWindow constructor

//--------------------------------------------------- MainWindow destructor
MainWindow::~MainWindow()
{
  if(!m_decoderBusy) {
    QFile lockFile(m_appDir + "/.lock");
    lockFile.remove();
  }
  delete ui;
}

//-------------------------------------------------------- writeSettings()
void MainWindow::writeSettings()
{
  m_settings->beginGroup("MainWindow");
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->setValue ("state", saveState ());
  m_settings->setValue("MRUdir", m_path);
  m_settings->setValue("TxFirst",m_txFirst);
  m_settings->setValue("DXcall",ui->dxCallEntry->text());
  m_settings->setValue("DXgrid",ui->dxGridEntry->text());
  m_settings->endGroup();

  m_settings->beginGroup("Common");
  m_settings->setValue("MyCall",m_myCall);
  m_settings->setValue("MyGrid",m_myGrid);
  m_settings->setValue("IDint",m_idInt);
  m_settings->setValue("PTTmethod",m_pttMethodIndex);
  m_settings->setValue("PTTport",m_pttPort);
  m_settings->setValue("SaveDir",m_saveDir);
  m_settings->setValue("SoundInName", m_audioInputDevice.deviceName ());
  m_settings->setValue("SoundOutName", m_audioOutputDevice.deviceName ());

  m_settings->setValue ("AudioInputChannel", AudioDevice::toString (m_audioInputChannel));
  m_settings->setValue ("AudioOutputChannel", AudioDevice::toString (m_audioOutputChannel));
  m_settings->setValue("Mode",m_mode);
  m_settings->setValue("ModeTx",m_modeTx);
  m_settings->setValue("SaveNone",ui->actionNone->isChecked());
  m_settings->setValue("SaveDecoded",ui->actionSave_decoded->isChecked());
  m_settings->setValue("SaveAll",ui->actionSave_all->isChecked());
  m_settings->setValue("NDepth",m_ndepth);
  m_settings->setValue("MonitorOFF",m_monitorStartOFF);
  m_settings->setValue("DialFreq",m_dialFreq);
  m_settings->setValue("RxFreq",m_rxFreq);
  m_settings->setValue("TxFreq",m_txFreq);
  m_settings->setValue("InGain",m_inGain);
  m_settings->setValue("OutAttenuation", ui->outAttenuation->value ());
  m_settings->setValue("PSKReporter",m_pskReporter);
  m_settings->setValue("After73",m_After73);
  m_settings->setValue("Macros",m_macro);
  //Band Settings
  m_settings->setValue("BandFrequencies",m_dFreq);
  m_settings->setValue("BandDescriptions",m_bandDescription);
  m_settings->setValue("AntennaDescriptions",m_antDescription);
  m_settings->setValue("toRTTY",m_toRTTY);
  m_settings->setValue("NoSuffix",m_noSuffix);
  m_settings->setValue("dBtoComments",m_dBtoComments);
  m_settings->setValue("catEnabled",m_catEnabled);
  m_settings->setValue("Rig",m_rig);
  m_settings->setValue("RigIndex",m_rigIndex);
  m_settings->setValue("CATport",m_catPort);
  m_settings->setValue("CATportIndex",m_catPortIndex);
  m_settings->setValue("SerialRate",m_serialRate);
  m_settings->setValue("SerialRateIndex",m_serialRateIndex);
  m_settings->setValue("DataBits",m_dataBits);
  m_settings->setValue("DataBitsIndex",m_dataBitsIndex);
  m_settings->setValue("StopBits",m_stopBits);
  m_settings->setValue("StopBitsIndex",m_stopBitsIndex);
  m_settings->setValue("Handshake",m_handshake);
  m_settings->setValue("HandshakeIndex",m_handshakeIndex);
  m_settings->setValue("BandIndex",m_band);
  m_settings->setValue("PromptToLog",m_promptToLog);
  m_settings->setValue("InsertBlank",m_insertBlank);
  m_settings->setValue("DXCCEntity",m_displayDXCCEntity);
  m_settings->setValue("ClearCallGrid",m_clearCallGrid);
  m_settings->setValue("Miles",m_bMiles);
  m_settings->setValue("GUItab",ui->tabWidget->currentIndex());
  m_settings->setValue("QuickCall",m_quickCall);
  m_settings->setValue("73TxDisable",m_73TxDisable);
  m_settings->setValue("Runaway",m_runaway);
  m_settings->setValue("Tx2QSO",m_tx2QSO);
  m_settings->setValue("MultipleOK",m_bMultipleOK);
  m_settings->setValue("DTR",m_bDTR);
  m_settings->setValue("RTS",m_bRTS);  m_settings->setValue("pttData",m_pttData);
  m_settings->setValue("Polling",m_poll);
  m_settings->setValue("OutBufSize",outBufSize);
  m_settings->setValue("LockTxFreq",m_lockTxFreq);
  m_settings->setValue("TxSplit",m_bSplit);
  m_settings->setValue("UseXIT",m_bXIT);
  m_settings->setValue("XIT",m_XIT);
  m_settings->setValue("Plus2kHz",m_plus2kHz);
  m_settings->endGroup();
}

//---------------------------------------------------------- readSettings()
void MainWindow::readSettings()
{
  m_settings->beginGroup("MainWindow");
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
  restoreState (m_settings->value ("state", saveState ()).toByteArray ());
  ui->dxCallEntry->setText(m_settings->value("DXcall","").toString());
  ui->dxGridEntry->setText(m_settings->value("DXgrid","").toString());
  m_path = m_settings->value("MRUdir", m_appDir + "/save").toString();
  m_txFirst = m_settings->value("TxFirst",false).toBool();
  ui->txFirstCheckBox->setChecked(m_txFirst);
  m_settings->endGroup();

  m_settings->beginGroup("Common");
  m_myCall=m_settings->value("MyCall","").toString();
  morse_(m_myCall.toLatin1().data(),icw,&m_ncw,m_myCall.length());
  m_myGrid=m_settings->value("MyGrid","").toString();
  m_idInt=m_settings->value("IDint",0).toInt();
  m_pttMethodIndex=m_settings->value("PTTmethod",1).toInt();
  m_pttPort=m_settings->value("PTTport",0).toInt();
  m_saveDir=m_settings->value("SaveDir",m_appDir + "/save").toString();

  {
    //
    // retrieve audio input device
    //
    QString savedName = m_settings->value( "SoundInName").toString();
    QList<QAudioDeviceInfo> audioInputDevices (QAudioDeviceInfo::availableDevices (QAudio::AudioInput)); // available audio input devices
    for (QList<QAudioDeviceInfo>::const_iterator p = audioInputDevices.begin (); p != audioInputDevices.end (); ++p)
      {
	if (p->deviceName () == savedName)
	  {
	    m_audioInputDevice = *p;
	  }
      }
  }

  {
    //
    // retrieve audio output device
    //
    QString savedName = m_settings->value("SoundOutName").toString();
    QList<QAudioDeviceInfo> audioOutputDevices (QAudioDeviceInfo::availableDevices (QAudio::AudioOutput)); // available audio output devices
    for (QList<QAudioDeviceInfo>::const_iterator p = audioOutputDevices.begin (); p != audioOutputDevices.end (); ++p)
    {
      if (p->deviceName () == savedName) {
        m_audioOutputDevice = *p;
      }
    }
  }

  // retrieve audio channel info
  m_audioInputChannel = AudioDevice::fromString (m_settings->value ("AudioInputChannel", "Mono").toString ());
  m_audioOutputChannel = AudioDevice::fromString (m_settings->value ("AudioOutputChannel", "Mono").toString ());

  m_mode=m_settings->value("Mode","JT9").toString();
  m_modeTx=m_settings->value("ModeTx","JT9").toString();
  if(m_modeTx=="JT9") ui->pbTxMode->setText("Tx JT9  @");
  if(m_modeTx=="JT65") ui->pbTxMode->setText("Tx JT65  #");
  ui->actionNone->setChecked(m_settings->value("SaveNone",true).toBool());
  ui->actionSave_decoded->setChecked(m_settings->value(
                                         "SaveDecoded",false).toBool());
  ui->actionSave_all->setChecked(m_settings->value("SaveAll",false).toBool());
  m_dialFreq=m_settings->value("DialFreq",14.078).toDouble();
  m_rxFreq=m_settings->value("RxFreq",1500).toInt();
  ui->RxFreqSpinBox->setValue(m_rxFreq);
  m_txFreq=m_settings->value("TxFreq",1500).toInt();
  ui->TxFreqSpinBox->setValue(m_txFreq);
  Q_EMIT transmitFrequency (m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0));
  m_saveDecoded=ui->actionSave_decoded->isChecked();
  m_saveAll=ui->actionSave_all->isChecked();
  m_ndepth=m_settings->value("NDepth",3).toInt();
  m_inGain=m_settings->value("InGain",0).toInt();
  ui->inGain->setValue(m_inGain);

  // setup initial value of tx attenuator
  ui->outAttenuation->setValue (m_settings->value ("OutAttenuation", 0).toInt ());
  on_outAttenuation_valueChanged (ui->outAttenuation->value ());

  m_monitorStartOFF=m_settings->value("MonitorOFF",false).toBool();
  ui->actionMonitor_OFF_at_startup->setChecked(m_monitorStartOFF);
  m_pskReporter=m_settings->value("PSKReporter",false).toBool();
  m_After73=m_settings->value("After73",false).toBool();
  m_macro=m_settings->value("Macros","TNX 73 GL").toStringList();
  //Band Settings
  m_dFreq=m_settings->value("BandFrequencies","").toStringList();
  m_bandDescription=m_settings->value("BandDescriptions","").toStringList();
  m_antDescription=m_settings->value("AntennaDescriptions","").toStringList();
  m_toRTTY=m_settings->value("toRTTY",false).toBool();
  ui->actionConvert_JT9_x_to_RTTY->setChecked(m_toRTTY);
  m_noSuffix=m_settings->value("NoSuffix",false).toBool();
  m_dBtoComments=m_settings->value("dBtoComments",false).toBool();
  ui->actionLog_dB_reports_to_Comments->setChecked(m_dBtoComments);
  m_rig=m_settings->value("Rig",214).toInt();
  m_rigIndex=m_settings->value("RigIndex",100).toInt();
  m_catPort=m_settings->value("CATport","None").toString();
  m_catPortIndex=m_settings->value("CATportIndex",0).toInt();
  m_serialRate=m_settings->value("SerialRate",4800).toInt();
  m_serialRateIndex=m_settings->value("SerialRateIndex",1).toInt();
  m_dataBits=m_settings->value("DataBits",8).toInt();
  m_dataBitsIndex=m_settings->value("DataBitsIndex",1).toInt();
  m_stopBits=m_settings->value("StopBits",2).toInt();
  m_stopBitsIndex=m_settings->value("StopBitsIndex",1).toInt();
  m_handshake=m_settings->value("Handshake","None").toString();
  m_handshakeIndex=m_settings->value("HandshakeIndex",0).toInt();
  m_band=m_settings->value("BandIndex",7).toInt();
  ui->bandComboBox->setCurrentIndex(m_band);
  dialFreqChanged2(m_dialFreq);
  m_catEnabled=m_settings->value("catEnabled",false).toBool();
  m_promptToLog=m_settings->value("PromptToLog",false).toBool();
  ui->actionPrompt_to_log_QSO->setChecked(m_promptToLog);
  m_insertBlank=m_settings->value("InsertBlank",false).toBool();
  ui->actionBlank_line_between_decoding_periods->setChecked(m_insertBlank);
  m_displayDXCCEntity=m_settings->value("DXCCEntity",false).toBool();
  ui->actionEnable_DXCC_entity->setChecked(m_displayDXCCEntity);
  m_clearCallGrid=m_settings->value("ClearCallGrid",false).toBool();
  ui->actionClear_DX_Call_and_Grid_after_logging->setChecked(m_clearCallGrid);
  m_bMiles=m_settings->value("Miles",false).toBool();
  ui->actionDisplay_distance_in_miles->setChecked(m_bMiles);
  int n=m_settings->value("GUItab",0).toInt();
  ui->tabWidget->setCurrentIndex(n);
  m_quickCall=m_settings->value("QuickCall",false).toBool();
  ui->actionDouble_click_on_call_sets_Tx_Enable->setChecked(m_quickCall);
  m_73TxDisable=m_settings->value("73TxDisable",false).toBool();
  ui->action_73TxDisable->setChecked(m_73TxDisable);
  m_runaway=m_settings->value("Runaway",false).toBool();
  ui->actionRunaway_Tx_watchdog->setChecked(m_runaway);
  m_tx2QSO=m_settings->value("Tx2QSO",false).toBool();
  ui->actionTx2QSO->setChecked(m_tx2QSO);
  m_bMultipleOK=m_settings->value("MultipleOK",false).toBool();
  ui->actionAllow_multiple_instances->setChecked(m_bMultipleOK);
  m_bDTR=m_settings->value("DTR",false).toBool();
  m_bRTS=m_settings->value("RTS",false).toBool();  m_pttData=m_settings->value("pttData",false).toBool();
  m_poll=m_settings->value("Polling",0).toInt();
  outBufSize=m_settings->value("OutBufSize",4096).toInt();
  m_lockTxFreq=m_settings->value("LockTxFreq",false).toBool();
  ui->cbTxLock->setChecked(m_lockTxFreq);
  m_bSplit=m_settings->value("TxSplit",false).toBool();
  m_bXIT=m_settings->value("UseXIT",false).toBool();
  m_XIT=m_settings->value("XIT",0).toInt();
	m_plus2kHz=m_settings->value("Plus2kHz",false).toBool();
	ui->cbPlus2kHz->setChecked(m_plus2kHz);
  m_settings->endGroup();

  // use these initialisation settings to tune the audio o/p bufefr
  // size and audio thread priority
  m_settings->beginGroup ("Tune");
  m_msAudioOutputBuffered = m_settings->value ("Audio/OutputBufferMs").toInt ();
  m_framesAudioInputBuffered = m_settings->value ("Audio/InputBufferFrames", RX_SAMPLE_RATE / 10).toInt ();
  m_audioThreadPriority = static_cast<QThread::Priority> (m_settings->value ("Audio/ThreadPriority", QThread::HighPriority).toInt () % 8);
  m_settings->endGroup ();

  if(m_ndepth==1) ui->actionQuickDecode->setChecked(true);
  if(m_ndepth==2) ui->actionMediumDecode->setChecked(true);
  if(m_ndepth==3) ui->actionDeepestDecode->setChecked(true);

  statusChanged();
}

//-------------------------------------------------------------- dataSink()
void MainWindow::dataSink(qint64 frames)
{
  static float s[NSMAX];
  static int ihsym=0;
  static int nzap=0;
  static int trmin;
  static int npts8;
  static int nflatten=0;
  static float px=0.0;
  static float df3;

  if(m_diskData) {
    jt9com_.ndiskdat=1;
  } else {
    jt9com_.ndiskdat=0;
  }

// Get power, spectrum, and ihsym
  trmin=m_TRperiod/60;
  int k (frames - 1);
  jt9com_.nfa=m_wideGraph->nStartFreq();
  jt9com_.nfb=m_wideGraph->getFmax();
  nflatten=0;
  if(m_wideGraph->flatten()) nflatten=1;
  symspec_(&k,&trmin,&m_nsps,&m_inGain,&nflatten,&px,s,&df3,&ihsym,&npts8);
  if(ihsym <=0) return;
  QString t;
  m_pctZap=nzap*100.0/m_nsps;
  t.sprintf(" Rx noise: %5.1f ",px);
  signalMeter->setValue(px);                            // Update thermometer
  if(m_monitoring || m_diskData) {
    m_wideGraph->dataSink2(s,df3,ihsym,m_diskData);
  }

  if(ihsym == m_hsymStop) {
    m_dataAvailable=true;
    jt9com_.npts8=(ihsym*m_nsps)/16;
    jt9com_.newdat=1;
    jt9com_.nagain=0;
    jt9com_.nzhsym=m_hsymStop;
    QDateTime t = QDateTime::currentDateTimeUtc();
    m_dateTime=t.toString("yyyy-MMM-dd hh:mm");
    decode();                                                //Start decoder
    if(!m_diskData) {                        //Always save; may delete later
      int ihr=t.time().toString("hh").toInt();
      int imin=t.time().toString("mm").toInt();
      imin=imin - (imin%(m_TRperiod/60));
      QString t2;
      t2.sprintf("%2.2d%2.2d",ihr,imin);
      m_fname=m_saveDir + "/" + t.date().toString("yyMMdd") + "_" +
            t2 + ".wav";
      *future2 = QtConcurrent::run(savewav, m_fname, m_TRperiod);
      watcher2->setFuture(*future2);
    }
  }
}

void MainWindow::showSoundInError(const QString& errorMsg)
 {QMessageBox::critical(this, tr("Error in SoundInput"), errorMsg);}

void MainWindow::showSoundOutError(const QString& errorMsg)
 {QMessageBox::critical(this, tr("Error in SoundOutput"), errorMsg);}

void MainWindow::showStatusMessage(const QString& statusMsg)
 {statusBar()->showMessage(statusMsg);}

void MainWindow::on_actionDeviceSetup_triggered()               //Setup Dialog
{
  DevSetup dlg(this);
  dlg.m_myCall=m_myCall;
  dlg.m_myGrid=m_myGrid;
  dlg.m_idInt=m_idInt;
  dlg.m_pttMethodIndex=m_pttMethodIndex;
  dlg.m_pttPort=m_pttPort;
  dlg.m_saveDir=m_saveDir;
  dlg.m_audioInputDevice = m_audioInputDevice;
  dlg.m_audioOutputDevice = m_audioOutputDevice;
  dlg.m_audioInputChannel = m_audioInputChannel;
  dlg.m_audioOutputChannel = m_audioOutputChannel;
  dlg.m_pskReporter=m_pskReporter;
  dlg.m_After73=m_After73;
  dlg.m_macro=m_macro;
  dlg.m_dFreq=m_dFreq;
  dlg.m_antDescription=m_antDescription;
  dlg.m_bandDescription=m_bandDescription;
  dlg.m_catEnabled=m_catEnabled;
  dlg.m_rig=m_rig;
  dlg.m_rigIndex=m_rigIndex;
  dlg.m_catPort=m_catPort;
  dlg.m_catPortIndex=m_catPortIndex;
  dlg.m_serialRate=m_serialRate;
  dlg.m_serialRateIndex=m_serialRateIndex;
  dlg.m_dataBits=m_dataBits;
  dlg.m_dataBitsIndex=m_dataBitsIndex;
  dlg.m_stopBits=m_stopBits;
  dlg.m_stopBitsIndex=m_stopBitsIndex;
  dlg.m_handshake=m_handshake;
  dlg.m_handshakeIndex=m_handshakeIndex;
  dlg.m_bDTR=m_bDTR;
  dlg.m_bRTS=m_bRTS;  dlg.m_pttData=m_pttData;
  dlg.m_poll=m_poll;
  dlg.m_bSplit=m_bSplit;
  dlg.m_bXIT=m_bXIT;

  if(m_bRigOpen) {
    rig->close();
    ui->readFreq->setStyleSheet("");
    ui->readFreq->setEnabled(false);
    if(m_rig<9900) delete rig;
    m_bRigOpen=false;
    m_catEnabled=false;
    m_CATerror=false;
  }

  dlg.initDlg();
  if(dlg.exec() == QDialog::Accepted) {
    m_myCall=dlg.m_myCall;
    m_myGrid=dlg.m_myGrid;
    m_idInt=dlg.m_idInt;
    m_pttMethodIndex=dlg.m_pttMethodIndex;
    m_pttPort=dlg.m_pttPort;
    m_saveDir=dlg.m_saveDir;
    m_audioInputDevice = dlg.m_audioInputDevice;
    m_audioOutputDevice = dlg.m_audioOutputDevice;
    m_audioInputChannel = dlg.m_audioInputChannel;
    m_audioOutputChannel = dlg.m_audioOutputChannel;
    m_macro=dlg.m_macro;
    m_dFreq=dlg.m_dFreq;
    m_antDescription=dlg.m_antDescription;
    m_bandDescription=dlg.m_bandDescription;
    m_catEnabled=dlg.m_catEnabled;
    m_rig=dlg.m_rig;
    m_rigIndex=dlg.m_rigIndex;
    m_catPort=dlg.m_catPort;
    m_catPortIndex=dlg.m_catPortIndex;
    m_serialRate=dlg.m_serialRate;
    m_serialRateIndex=dlg.m_serialRateIndex;
    m_dataBits=dlg.m_dataBits;
    m_dataBitsIndex=dlg.m_dataBitsIndex;
    m_stopBits=dlg.m_stopBits;
    m_stopBitsIndex=dlg.m_stopBitsIndex;
    m_handshake=dlg.m_handshake;
    m_handshakeIndex=dlg.m_handshakeIndex;
    m_bDTR=dlg.m_bDTR;
    m_bRTS=dlg.m_bRTS;
    m_pttData=dlg.m_pttData;
    m_poll=dlg.m_poll;

	//Band Settings
    ui->bandComboBox->clear();
    ui->bandComboBox->addItems(dlg.m_bandDescription);
    ui->bandComboBox->setCurrentIndex(m_band);
    m_pskReporter=dlg.m_pskReporter;

    if(m_pskReporter) {
      psk_Reporter->setLocalStation(m_myCall, m_myGrid, m_antDescription[m_band], "WSJT-X r" + rev.mid(6,4) );
    }

    m_After73=dlg.m_After73;

    if(dlg.m_restartSoundIn) {
      Q_EMIT stopAudioInputStream ();
      Q_EMIT detectorClose ();
      Q_EMIT startDetector (m_audioInputChannel);
      Q_EMIT startAudioInputStream (m_audioInputDevice, AudioDevice::Mono == m_audioInputChannel ? 1 : 2, m_framesAudioInputBuffered, &m_detector, m_downSampleFactor);
    }

    if(dlg.m_restartSoundOut) {
      Q_EMIT stopAudioOutputStream ();
      Q_EMIT startAudioOutputStream (m_audioOutputDevice, AudioDevice::Mono == m_audioOutputChannel ? 1 : 2, m_msAudioOutputBuffered);
    }
  }
  m_catEnabled=dlg.m_catEnabled;

  if(m_catEnabled) {
    rigOpen();
  } else {
    ui->readFreq->setStyleSheet("");
  }

  if(dlg.m_bSplit!=m_bSplit or dlg.m_bXIT!=m_bXIT) {
    m_bSplit=dlg.m_bSplit;
    if(m_bSplit) ui->readFreq->setText("S");
    if(!m_bSplit) ui->readFreq->setText("");
    m_bXIT=dlg.m_bXIT;
    if(m_bSplit or m_bXIT) setXIT(m_txFreq);
    if(m_bRigOpen and !m_bSplit) {
      int ret=rig->setSplitFreq(MHz(m_dialFreq),RIG_VFO_B);
      if(ret!=RIG_OK) {
        QString rt;
        rt.sprintf("Setting VFO_B failed:  %d",ret);
        msgBox(rt);
      }
    }
  }
}

void MainWindow::on_monitorButton_clicked()                  //Monitor
{
  m_monitoring=true;
  Q_EMIT detectorSetMonitoring (true);
  //  Q_EMIT startAudioInputStream (m_audioInputDevice, AudioDevice::Mono == m_audioInputChannel ? 1 : 2, m_framesAudioInputBuffered, &m_detector, m_downSampleFactor);
  m_diskData=false;
}

void MainWindow::on_actionAbout_triggered()                  //Display "About"
{
  CAboutDlg dlg(this,Program_Title_Version);
  dlg.exec();
}

void MainWindow::on_autoButton_clicked()                     //Auto
{
  m_auto = !m_auto;
  if(m_auto) {
    ui->autoButton->setStyleSheet(m_pbAutoOn_style);
  } else {
    m_btxok=false;
    Q_EMIT muteAudioOutput ();
    ui->autoButton->setStyleSheet("");
    on_monitorButton_clicked();
    m_repeatMsg=0;
  }
}

void MainWindow::keyPressEvent( QKeyEvent *e )                //keyPressEvent
{
  int n;
  switch(e->key())
  {
  case Qt::Key_1:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb1_clicked();
      break;
    }
  case Qt::Key_2:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb2_clicked();
      break;
    }
  case Qt::Key_3:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb3_clicked();
      break;
    }
  case Qt::Key_4:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb4_clicked();
      break;
    }
  case Qt::Key_5:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb5_clicked();
      break;
    }
  case Qt::Key_6:
    if(e->modifiers() & Qt::AltModifier) {
      on_txb6_clicked();
      break;
    }
  case Qt::Key_D:
    if(e->modifiers() & Qt::ShiftModifier) {
      if(!m_decoderBusy) {
        jt9com_.newdat=0;
        jt9com_.nagain=0;
        decode();
        break;
      }
    }
    break;
  case Qt::Key_F4:
    ui->dxCallEntry->setText("");
    ui->dxGridEntry->setText("");
    genStdMsgs("");
    m_ntx=6;
    ui->txrb6->setChecked(true);
    break;
  case Qt::Key_F6:
    if(e->modifiers() & Qt::ShiftModifier) {
      on_actionDecode_remaining_files_in_directory_triggered();
    }
    break;
  case Qt::Key_F11:
    n=11;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    bumpFqso(n);
    break;
  case Qt::Key_F12:
    n=12;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    bumpFqso(n);
    break;
  case Qt::Key_F:
    if(e->modifiers() & Qt::ControlModifier) {
      if(ui->tabWidget->currentIndex()==0) {
        ui->tx5->clear();
        ui->tx5->setFocus();
      } else {
        ui->freeTextMsg->clear();
        ui->freeTextMsg->setFocus();
      }
      break;
    }
  case Qt::Key_G:
    if(e->modifiers() & Qt::AltModifier) {
      genStdMsgs(m_rpt);
      break;
    }
  case Qt::Key_H:
    if(e->modifiers() & Qt::AltModifier) {
      on_stopTxButton_clicked();
      break;
    }
  case Qt::Key_L:
    if(e->modifiers() & Qt::ControlModifier) {
      lookup();
      genStdMsgs(m_rpt);
      break;
    }
  case Qt::Key_V:
    if(e->modifiers() & Qt::AltModifier) {
      m_fileToSave=m_fname;
      break;
    }
  }
}

void MainWindow::bumpFqso(int n)                                 //bumpFqso()
{
  int i;
  bool ctrl = (n>=100);
  n=n%100;
  i=m_wideGraph->rxFreq();
  if(n==11) i--;
  if(n==12) i++;
  m_wideGraph->setRxFreq(i);
  if(ctrl) {
    ui->TxFreqSpinBox->setValue(i);
    m_wideGraph->setTxFreq(i);
  }
}

void MainWindow::dialFreqChanged2(double f)
{
  m_dialFreq=f;
  if(m_band<0 or m_band>15 or m_dFreq.length()<=1) return;
  QString t;
  t.sprintf("%.6f",m_dialFreq);
  int n=t.length();
  t=t.mid(0,n-3) + " " + t.mid(n-3,3);
  double fBand=m_dFreq[m_band].toDouble();
  if(qAbs(m_dialFreq-fBand)<0.01) {
    ui->labDialFreq->setStyleSheet( \
        "QLabel { background-color : black; color : yellow; }");
  } else {
    ui->labDialFreq->setStyleSheet( \
          "QLabel { background-color : red; color : yellow; }");
    ui->labDialFreq->setText(t);
  }
  ui->labDialFreq->setText(t);
  statusChanged();
  m_wideGraph->setDialFreq(m_dialFreq);
}

void MainWindow::statusChanged()
{
  QFile f("wsjtx_status.txt");
  if(f.open(QFile::WriteOnly | QIODevice::Text)) {
    QTextStream out(&f);
    out << m_dialFreq << ";" << m_mode << ";" << m_hisCall << ";"
        << ui->rptSpinBox->value() << ";" << m_modeTx << endl;
    f.close();
  } else {
    msgBox("Cannot open file \"wsjtx_status.txt\".");
    return;
  }
}

bool MainWindow::eventFilter(QObject *object, QEvent *event)  //eventFilter()
{
  if (event->type() == QEvent::KeyPress) {
    QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
    MainWindow::keyPressEvent(keyEvent);
    return QObject::eventFilter(object, event);
  }
  return QObject::eventFilter(object, event);
}

void MainWindow::createStatusBar()                           //createStatusBar
{
  lab1 = new QLabel("Receiving");
  lab1->setAlignment(Qt::AlignHCenter);
  lab1->setMinimumSize(QSize(80,18));
  lab1->setStyleSheet("QLabel{background-color: #00ff00}");
  lab1->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab1);


  lab2 = new QLabel("");
  lab2->setAlignment(Qt::AlignHCenter);
  lab2->setMinimumSize(QSize(80,18));
  lab2->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab2);

  lab3 = new QLabel("");
  lab3->setAlignment(Qt::AlignHCenter);
  lab3->setMinimumSize(QSize(150,18));
  lab3->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab3);
}

void MainWindow::on_actionExit_triggered()                     //Exit()
{
  OnExit();
}

void MainWindow::closeEvent(QCloseEvent * e)
{
  writeSettings ();
  OnExit();
  QMainWindow::closeEvent (e);
}

void MainWindow::OnExit()
{
  m_guiTimer.stop ();
  if(m_fname != "") killFile();
  m_killAll=true;
  mem_jt9->detach();
  QFile quitFile(m_appDir + "/.quit");
  quitFile.open(QIODevice::ReadWrite);
  QFile lockFile(m_appDir + "/.lock");
  lockFile.remove();                      // Allow jt9 to terminate
  bool b=proc_jt9.waitForFinished(1000);
  if(!b) proc_jt9.kill();
  quitFile.remove();

  Q_EMIT finished ();
  m_audioThread.wait ();
}

void MainWindow::on_stopButton_clicked()                       //stopButton
{
  m_monitoring=false;
  Q_EMIT detectorSetMonitoring (m_monitoring);
  m_loopall=false;  
}

void MainWindow::msgBox(QString t)                             //msgBox
{
  msgBox0.setText(t);
  msgBox0.exec();
}

void MainWindow::on_actionOnline_Users_Guide_triggered()      //Display manual
{
  QDesktopServices::openUrl(QUrl(
    "http://www.physics.princeton.edu/pulsar/K1JT/wsjtx-doc/wsjtx-main-toc2.html",
                              QUrl::TolerantMode));
}

void MainWindow::on_actionWide_Waterfall_triggered()      //Display Waterfalls
{
  m_wideGraph->show();
}

void MainWindow::on_actionOpen_triggered()                     //Open File
{
  m_monitoring=false;
  Q_EMIT detectorSetMonitoring (m_monitoring);
  QString fname;
  fname=QFileDialog::getOpenFileName(this, "Open File", m_path,
                                       "WSJT Files (*.wav)");
  if(fname != "") {
    m_path=fname;
    int i;
    i=fname.indexOf(".wav") - 11;
    if(i>=0) {
      lab1->setStyleSheet("QLabel{background-color: #66ff66}");
      lab1->setText(" " + fname.mid(i,15) + " ");
    }
    on_stopButton_clicked();
    m_diskData=true;
    *future1 = QtConcurrent::run(getfile, fname, m_TRperiod);
    watcher1->setFuture(*future1);         // call diskDat() when done
  }
}

void MainWindow::on_actionOpen_next_in_directory_triggered()   //Open Next
{
  int i,len;
  QFileInfo fi(m_path);
  QStringList list;
  list= fi.dir().entryList().filter(".wav");
  for (i = 0; i < list.size()-1; ++i) {
    if(i==list.size()-2) m_loopall=false;
    len=list.at(i).length();
    if(list.at(i)==m_path.right(len)) {
      int n=m_path.length();
      QString fname=m_path.replace(n-len,len,list.at(i+1));
      m_path=fname;
      int i;
      i=fname.indexOf(".wav") - 11;
      if(i>=0) {
        lab1->setStyleSheet("QLabel{background-color: #66ff66}");
        lab1->setText(" " + fname.mid(i,len) + " ");
      }
      m_diskData=true;
      *future1 = QtConcurrent::run(getfile, fname, m_TRperiod);
      watcher1->setFuture(*future1);
      return;
    }
  }
}
                                                   //Open all remaining files
void MainWindow::on_actionDecode_remaining_files_in_directory_triggered()
{
  m_loopall=true;
  on_actionOpen_next_in_directory_triggered();
}

void MainWindow::diskDat()                                   //diskDat()
{
  int k;
  int kstep=m_nsps/2;
  m_diskData=true;
  for(int n=1; n<=m_hsymStop; n++) {              // Do the half-symbol FFTs
    k=(n+1)*kstep;
    jt9com_.npts8=k/8;
    dataSink(k * sizeof (jt9com_.d2[0]));
    if(n%10 == 1 or n == m_hsymStop)
        qApp->processEvents();                   //Keep GUI responsive
  }
}

void MainWindow::diskWriteFinished()                       //diskWriteFinished
{
}

//Delete ../save/*.wav
void MainWindow::on_actionDelete_all_wav_files_in_SaveDir_triggered()
{
  int i;
  QString fname;
  int ret = QMessageBox::warning(this, "Confirm Delete",
      "Are you sure you want to delete all *.wav files in\n" +
       QDir::toNativeSeparators(m_saveDir) + " ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QDir dir(m_saveDir);
    QStringList files=dir.entryList(QDir::Files);
    QList<QString>::iterator f;
    for(f=files.begin(); f!=files.end(); ++f) {
      fname=*f;
      i=(fname.indexOf(".wav"));
      if(i>10) dir.remove(fname);
    }
  }
}

void MainWindow::on_actionNone_triggered()                    //Save None
{
  m_saveDecoded=false;
  m_saveAll=false;
  ui->actionNone->setChecked(true);
}

void MainWindow::on_actionSave_decoded_triggered()
{
  m_saveDecoded=true;
  m_saveAll=false;
  ui->actionSave_decoded->setChecked(true);
}

void MainWindow::on_actionSave_all_triggered()                //Save All
{
  m_saveDecoded=false;
  m_saveAll=true;
  ui->actionSave_all->setChecked(true);
}

void MainWindow::on_actionKeyboard_shortcuts_triggered()
{
  pShortcuts = new QTextEdit(0);
  pShortcuts->setReadOnly(true);
  pShortcuts->setFontPointSize(10);
  pShortcuts->setWindowTitle("Keyboard Shortcuts");
  pShortcuts->setGeometry(QRect(45,50,430,460));
  Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
      Qt::WindowMinimizeButtonHint;
  pShortcuts->setWindowFlags(flags);
  QString shortcuts = m_appDir + "/shortcuts.txt";
  QFile f(shortcuts);
  if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + shortcuts);
    return;
  }
  QTextStream s(&f);
  QString t;
  for(int i=0; i<100; i++) {
    t=s.readLine();
    pShortcuts->append(t);
    if(s.atEnd()) break;
  }
  pShortcuts->show();
}

void MainWindow::on_actionSpecial_mouse_commands_triggered()
{
  QTextEdit* pMouseCmnds;
  pMouseCmnds = new QTextEdit(0);
  pMouseCmnds->setReadOnly(true);
  pMouseCmnds->setFontPointSize(10);
  pMouseCmnds->setWindowTitle("Special Mouse Commands");
  pMouseCmnds->setGeometry(QRect(45,50,440,300));
  Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
      Qt::WindowMinimizeButtonHint;
  pMouseCmnds->setWindowFlags(flags);
  QString mouseCmnds = m_appDir + "/mouse_commands.txt";
  QFile f(mouseCmnds);
  if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + mouseCmnds);
    return;
  }
  QTextStream s(&f);
  QString t;
  for(int i=0; i<100; i++) {
    t=s.readLine();
    pMouseCmnds->append(t);
    if(s.atEnd()) break;
  }
  pMouseCmnds->show();
}

void MainWindow::on_DecodeButton_clicked()                    //Decode request
{
  if(!m_decoderBusy) {
    jt9com_.newdat=0;
    jt9com_.nagain=1;
    m_blankLine=false; // don't insert the separator again
    decode();
  }
}

void MainWindow::freezeDecode(int n)                          //freezeDecode()
{
  bool ctrl = (n>=100);
  int i=m_wideGraph->rxFreq();
  if(ctrl) {
    ui->TxFreqSpinBox->setValue(i);
    m_wideGraph->setTxFreq(i);
  }
  if((n%100)==2) on_DecodeButton_clicked();
}

void MainWindow::decode()                                       //decode()
{
  if(!m_dataAvailable) return;
  ui->DecodeButton->setStyleSheet(m_pbdecoding_style1);
  if(jt9com_.newdat==1 && (!m_diskData)) {
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int imin=ms/60000;
    int ihr=imin/60;
    imin=imin % 60;
    imin=imin - (imin % (m_TRperiod/60));
    jt9com_.nutc=100*ihr + imin;
  }

  jt9com_.nfqso=m_wideGraph->rxFreq();
  jt9com_.ndepth=m_ndepth;
  jt9com_.ndiskdat=0;
  if(m_diskData) jt9com_.ndiskdat=1;
  jt9com_.nfa=m_wideGraph->nStartFreq();
  jt9com_.nfSplit=m_wideGraph->getFmin();
  jt9com_.nfb=m_wideGraph->getFmax();
  jt9com_.ntol=20;
  if(jt9com_.nutc < m_nutc0) m_RxLog = 1;       //Date and Time to all.txt
  m_nutc0=jt9com_.nutc;
  jt9com_.ntxmode=9;
  if(m_modeTx=="JT65") jt9com_.ntxmode=65;
  jt9com_.nmode=9;
  if(m_mode=="JT65") jt9com_.nmode=65;
  if(m_mode=="JT9+JT65") jt9com_.nmode=9+65;
  jt9com_.ntrperiod=m_TRperiod;
  m_nsave=0;
  if(m_saveDecoded) m_nsave=2;
  jt9com_.nsave=m_nsave;
  strncpy(jt9com_.datetime, m_dateTime.toLatin1(), 20);

  //newdat=1  ==> this is new data, must do the big FFT
  //nagain=1  ==> decode only at fQSO +/- Tol

  char *to = (char*)mem_jt9->data();
  char *from = (char*) jt9com_.ss;
  int size=sizeof(jt9com_);
  if(jt9com_.newdat==0) {
    int noffset = 4*184*NSMAX + 4*NSMAX + 2*NTMAX*12000;
    to += noffset;
    from += noffset;
    size -= noffset;
  }
  memcpy(to, from, qMin(mem_jt9->size(), size));

  QFile lockFile(m_appDir + "/.lock");       // Allow jt9 to start
  lockFile.remove();
  decodeBusy(true);
}

void MainWindow::jt9_error(QProcess::ProcessError e)                                     //jt9_error
{
  if(!m_killAll) {
    msgBox("Error starting or running\n" + m_appDir + "/jt9 -s");
    exit(1);
  }
}

void MainWindow::readFromStderr()                             //readFromStderr
{
  QByteArray t=proc_jt9.readAllStandardError();
  msgBox(t);
}

void MainWindow::readFromStdout()                             //readFromStdout
{
  while(proc_jt9.canReadLine())
  {
    QByteArray t=proc_jt9.readLine();
    if(t.indexOf("<DecodeFinished>") >= 0)
    {
      m_bdecoded = (t.mid(23,1).toInt()==1);
      bool keepFile=m_saveAll or (m_saveDecoded and m_bdecoded);
      if(!keepFile and !m_diskData) killFileTimer->start(45*1000); //Kill in 45 s
      jt9com_.nagain=0;
      jt9com_.ndiskdat=0;
      QFile lockFile(m_appDir + "/.lock");
      lockFile.open(QIODevice::ReadWrite);
      ui->DecodeButton->setStyleSheet("");
      decodeBusy(false);
      m_RxLog=0;
      m_startAnother=m_loopall;
      m_blankLine=true;
      return;
    } else {
      QFile f("ALL.TXT");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      if(m_RxLog==1) {
        out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
            << "  " << m_dialFreq << " MHz  " << m_mode << endl;
        m_RxLog=0;
      }
      int n=t.length();
      out << t.mid(0,n-2) << endl;
      f.close();

      if(m_insertBlank and m_blankLine)
      {
          ui->decodedTextBrowser->insertLineSpacer();
          m_blankLine=false;
      }

      DecodedText decodedtext;
      decodedtext = t.replace("\n",""); //t.replace("\n","").mid(0,t.length()-4);

      // the left band display
      ui->decodedTextBrowser->displayDecodedText(decodedtext,m_myCall,m_displayDXCCEntity,m_logBook);

      if (abs(decodedtext.frequencyOffset() - m_wideGraph->rxFreq()) <= 10) // this msg is within 10 hertz of our tuned frequency
      {
          // the right QSO window
          ui->decodedTextBrowser2->displayDecodedText(decodedtext,m_myCall,false,m_logBook);

          bool b65=decodedtext.isJT65();
          if(b65 and m_modeTx!="JT65") on_pbTxMode_clicked();
          if(!b65 and m_modeTx=="JT65") on_pbTxMode_clicked();
          m_QSOText=decodedtext;
      }

      // find and extract any report for myCall
      bool stdMsg = decodedtext.report(m_myCall,/*mod*/m_rptRcvd);

      // extract details and send to PSKreporter
      int nsec=QDateTime::currentMSecsSinceEpoch()/1000-m_secBandChanged;
      bool okToPost=(nsec>50);
      if(m_pskReporter and stdMsg and !m_diskData and okToPost)
      {
          QString msgmode="JT9";
          if (decodedtext.isJT65())
              msgmode="JT65";

          QString deCall;
          QString grid;
          decodedtext.deCallAndGrid(/*out*/deCall,grid);
          int audioFrequency = decodedtext.frequencyOffset();
          int snr = decodedtext.snr();
          uint frequency = 1000000.0*m_dialFreq + audioFrequency + 0.5;

          psk_Reporter->setLocalStation(m_myCall, m_myGrid, m_antDescription[m_band], "WSJT-X r" + rev.mid(6,4) );
          if(gridOK(grid))
              psk_Reporter->addRemoteStation(deCall,grid,QString::number(frequency),msgmode,QString::number(snr),
                                             QString::number(QDateTime::currentDateTime().toTime_t()));
      }
    }
  }
}

void MainWindow::killFile()
{
  if(m_fname==m_fileToSave) {
  } else {
    QFile savedFile(m_fname);
    savedFile.remove();
  }
}

void MainWindow::on_EraseButton_clicked()                          //Erase
{
  qint64 ms=QDateTime::currentMSecsSinceEpoch();
  ui->decodedTextBrowser2->clear();
  m_QSOText.clear();
  if((ms-m_msErase)<500) {
      ui->decodedTextBrowser->clear();
      QFile f(m_appDir + "/decoded.txt");
      if(f.exists()) f.remove();
  }
  m_msErase=ms;
}

void MainWindow::decodeBusy(bool b)                             //decodeBusy()
{
  m_decoderBusy=b;
  ui->DecodeButton->setEnabled(!b);
  ui->actionOpen->setEnabled(!b);
  ui->actionOpen_next_in_directory->setEnabled(!b);
  ui->actionDecode_remaining_files_in_directory->setEnabled(!b);
}

//------------------------------------------------------------- //guiUpdate()
void MainWindow::guiUpdate()
{
  static int iptt0=0;
  static bool btxok0=false;
  static char message[29];
  static char msgsent[29];
  static int nsendingsh=0;
  static int giptt00=-1;
  static int gcomport00=-1;
  static double onAirFreq0=0.0;
  int ret=0;
  QString rt;

  double tx1=0.0;
  double tx2=1.0 + 85.0*m_nsps/12000.0 + icw[0]*2560.0/48000.0;
  if(m_modeTx=="JT65") tx2=1.0 + 126*4096/11025.0 + icw[0]*2560.0/48000.0;

  if(!m_txFirst) {
    tx1 += m_TRperiod;
    tx2 += m_TRperiod;
  }
  qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
  int nsec=ms/1000;
  double tsec=0.001*ms;
  double t2p=fmod(tsec,2*m_TRperiod);
  bool bTxTime = ((t2p >= tx1) and (t2p < tx2)) or m_tune;

  if(m_auto or m_tune) {
    QFile f("txboth");
    if(f.exists() and fmod(tsec,m_TRperiod) < (1.0 + 85.0*m_nsps/12000.0)) {
      bTxTime=true;
    }

    double onAirFreq=m_dialFreq+1.e-6*m_txFreq;
    if(onAirFreq>10.139900 and onAirFreq<10.140320) {
      bTxTime=false;
      if(m_tune) on_tuneButton_clicked();
      if(onAirFreq!=onAirFreq0) {
        onAirFreq0=onAirFreq;
        on_autoButton_clicked();
        QString t="Please choose another Tx frequency.\n";
        t+="WSJT-X will not knowingly transmit\n";
        t+="in the WSPR sub-band on 30 m.";
        msgBox0.setText(t);
        msgBox0.show();
      }
    }

    float fTR=float((nsec%m_TRperiod))/m_TRperiod;
    if(g_iptt==0 and ((bTxTime and !m_btxMute and fTR<0.4) or m_tune )) {
      icw[0]=m_ncw;

//Raise PTT
      if(m_catEnabled and m_bRigOpen and  m_pttMethodIndex==0) {
        g_iptt=1;
        if(m_pttData) ret=rig->setPTT(RIG_PTT_ON_DATA, RIG_VFO_CURR);
        if(!m_pttData) ret=rig->setPTT(RIG_PTT_ON_MIC, RIG_VFO_CURR);
        if(ret!=RIG_OK) {
          rt.sprintf("CAT control PTT failed:  %d",ret);
          msgBox(rt);
        }

      }

      if(m_pttMethodIndex==1 or m_pttMethodIndex==2) {  //DTR or RTS
        ptt(m_pttPort,1,&g_iptt,&g_COMportOpen);
      }
      if(m_pttMethodIndex==3) {                    //VOX
        g_iptt=1;
      }
      ptt1Timer->start(200);                       //Sequencer delay
    }
    if(!bTxTime || m_btxMute) {
      m_btxok=false;
      Q_EMIT muteAudioOutput ();
    }
  }

// Calculate Tx tones when needed
  if((g_iptt==1 && iptt0==0) || m_restart) {
    QByteArray ba;
    if(m_ntx == 1) ba=ui->tx1->text().toLocal8Bit();
    if(m_ntx == 2) ba=ui->tx2->text().toLocal8Bit();
    if(m_ntx == 3) ba=ui->tx3->text().toLocal8Bit();
    if(m_ntx == 4) ba=ui->tx4->text().toLocal8Bit();
    if(m_ntx == 5) ba=ui->tx5->text().toLocal8Bit();
    if(m_ntx == 6) ba=ui->tx6->text().toLocal8Bit();
    if(m_ntx == 7) ba=ui->genMsg->text().toLocal8Bit();
    if(m_ntx == 8) ba=ui->freeTextMsg->text().toLocal8Bit();

    ba2msg(ba,message);
//    ba2msg(ba,msgsent);
    int len1=22;
    int ichk=0,itext=0;
    if(m_modeTx=="JT9") genjt9_(message,&ichk,msgsent,itone,&itext,len1,len1);
    if(m_modeTx=="JT65") gen65_(message,&ichk,msgsent,itone,&itext,len1,len1);
    msgsent[22]=0;
    QString t=QString::fromLatin1(msgsent);
    if(m_tune) t="TUNE";
    lab3->setText("Last Tx:  " + t);
    if(m_restart) {
      QFile f("ALL.TXT");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      out << QDateTime::currentDateTimeUtc().toString("hhmm")
          << "  Transmitting " << m_dialFreq << " MHz  " << m_modeTx
          << ":  " << t << endl;
      f.close();
      if(m_tx2QSO)
          ui->decodedTextBrowser2->displayTransmittedText(t,m_modeTx,m_txFreq);
    }

    QStringList w=t.split(" ",QString::SkipEmptyParts);
    t="";
    if(w.length()==3) t=w[2];
    icw[0]=0;
    m_sent73=(t=="73" or itext!=0);
    if(m_sent73)  {
      if(m_After73)  icw[0]=m_ncw;
      if(m_promptToLog and !m_tune) logQSOTimer->start(200);
    }

    if(m_idInt>0) {
      int nmin=(m_sec0-m_secID)/60;
      if(nmin >= m_idInt) {
        icw[0]=m_ncw;
        m_secID=m_sec0;
      }
    }

    QString t2=QDateTime::currentDateTimeUtc().toString("hhmm");
    if(itext==0 and w.length()>=3 and w[1]==m_myCall) {
      int i1;
      bool ok;
      i1=t.toInt(&ok);
      if(ok and i1>=-50 and i1<50) {
        m_rptSent=t;
        m_qsoStart=t2;
      } else {
        if(t.mid(0,1)=="R") {
          i1=t.mid(1).toInt(&ok);
          if(ok and i1>=-50 and i1<50) {
            m_rptSent=t.mid(1);
            m_qsoStart=t2;
          }
        }
      }
    }
    if(itext==1 or (w.length()==3 and w[2]=="73")) m_qsoStop=t2;
    m_restart=false;
  }


// If PTT was just raised, start a countdown for raising TxOK:
// NB: could be better implemented with a timer
  if(g_iptt == 1 && iptt0 == 0) {
      nc1=-9;    // TxDelay = 0.8 s
  }
  if(nc1 <= 0) {
      nc1++;
  }
  if(nc1 == 0) {
    QString t=QString::fromLatin1(msgsent);
    if(t==m_msgSent0) {
      m_repeatMsg++;
    } else {
      m_repeatMsg=0;
      m_msgSent0=t;
    }

    signalMeter->setValue(0);
    m_monitoring=false;
    Q_EMIT detectorSetMonitoring (false);
    m_btxok=true;
    Q_EMIT muteAudioOutput (false);
    m_transmitting=true;
    ui->pbTxMode->setEnabled(false);
    if(!m_tune) {
      QFile f("ALL.TXT");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      out << QDateTime::currentDateTimeUtc().toString("hhmm")
          << "  Transmitting " << m_dialFreq << " MHz  " << m_modeTx
          << ":  " << t << endl;
      f.close();
    }
    if(m_tx2QSO and !m_tune)
        ui->decodedTextBrowser2->displayTransmittedText(t,m_modeTx,m_txFreq);
  }

  if(!m_btxok && btxok0 && g_iptt==1) stopTx();

/*
// If m_btxok was just lowered, start a countdown for lowering PTT
  if(!m_btxok && btxok0 && g_iptt==1) nc0=-11;  //RxDelay = 1.0 s
  if(nc0 <= 0) {
    nc0++;
  }
*/

  if(m_monitoring) {
    ui->monitorButton->setStyleSheet(m_pbmonitor_style);
  } else {
    ui->monitorButton->setStyleSheet("");
  }

  if(m_startAnother) {
    m_startAnother=false;
    on_actionOpen_next_in_directory_triggered();
  }

  if(m_catEnabled and !m_bRigOpen) {
		rigOpen();
		if(m_bSplit or m_bXIT) setXIT(m_txFreq);
		if(m_bRigOpen and !m_bSplit) {
			int ret=rig->setSplitFreq(MHz(m_dialFreq),RIG_VFO_B);
			if(ret!=RIG_OK) {
				QString rt;
				rt.sprintf("Setting VFO_B failed:  %d",ret);
				msgBox(rt);
			}
		}
  }

  if(nsec != m_sec0) {                                     //Once per second
    QDateTime t = QDateTime::currentDateTimeUtc();
    if(m_transmitting) {
      if(nsendingsh==1) {
        lab1->setStyleSheet("QLabel{background-color: #66ffff}");
      } else if(nsendingsh==-1) {
        lab1->setStyleSheet("QLabel{background-color: #ffccff}");
      } else {
        lab1->setStyleSheet("QLabel{background-color: #ffff33}");
      }
      if(m_tune) {
        lab1->setText("Tx: TUNE");
      } else {
          char s[37];
          sprintf(s,"Tx: %s",msgsent);
          lab1->setText(s);
      }
    } else if(m_monitoring) {
      lab1->setStyleSheet("QLabel{background-color: #00ff00}");
      lab1->setText("Receiving ");
    } else if (!m_diskData) {
      lab1->setStyleSheet("");
      lab1->setText("");
    }

    m_setftx=0;
    QString utc = t.date().toString("yyyy MMM dd") + "\n " +
            t.time().toString() + " ";
    ui->labUTC->setText(utc);
    if(!m_monitoring and !m_diskData) {
      signalMeter->setValue(0);
    }

    if(m_catEnabled and m_poll>0 and (nsec%m_poll)==0 and
       !m_decoderBusy) pollRigFreq();
    m_sec0=nsec;
  }

  if(g_iptt!=giptt00 or g_COMportOpen!=gcomport00) {
    giptt00=g_iptt;
    gcomport00=g_COMportOpen;
  }

  iptt0=g_iptt;
  btxok0=m_btxok;
}               //End of GUIupdate


void MainWindow::startTx2()
{
  if (!m_modulator.isActive ()) {
    QString t=ui->tx6->text();
    double snr=t.mid(1,5).toDouble();
    if(snr>0.0 or snr < -50.0) snr=99.0;
    transmit (snr);
    signalMeter->setValue(0);
    m_monitoring=false;
    Q_EMIT detectorSetMonitoring (false);
    m_btxok=true;
    Q_EMIT muteAudioOutput (false);
    m_transmitting=true;
    ui->pbTxMode->setEnabled(false);
  }
}

void MainWindow::stopTx()
{
  Q_EMIT endTransmitMessage ();
  Q_EMIT stopAudioOutputStream ();
  m_transmitting=false;
  ui->pbTxMode->setEnabled(true);
  g_iptt=0;
  lab1->setStyleSheet("");
  lab1->setText("");
  ptt0Timer->start(200);                       //Sequencer delay
  m_monitoring=true;
  Q_EMIT detectorSetMonitoring (true);
}

void MainWindow::stopTx2()
{
  int ret=0;
  QString rt;

//Lower PTT
  if(m_catEnabled and m_bRigOpen and  m_pttMethodIndex==0) {
    ret=rig->setPTT(RIG_PTT_OFF, RIG_VFO_CURR);  //CAT control for PTT=0
    if(ret!=RIG_OK) {
      rt.sprintf("CAT control PTT failed:  %d",ret);
      msgBox(rt);
    }
  }
  if(m_pttMethodIndex==1 or m_pttMethodIndex==2) {
    ptt(m_pttPort,0,&g_iptt,&g_COMportOpen);
  }
  if(m_73TxDisable and m_sent73) on_stopTxButton_clicked();

  if(m_runaway and m_repeatMsg>m_watchdogLimit) {
    on_stopTxButton_clicked();
    msgBox0.setText("Runaway Tx watchdog");
    msgBox0.show();
    m_repeatMsg=0;
  }
}

void MainWindow::ba2msg(QByteArray ba, char message[])             //ba2msg()
{
  int iz=ba.length();
  for(int i=0;i<22; i++) {
    if(i<iz) {
      message[i]=ba[i];
    } else {
      message[i]=32;
    }
  }
  message[22]=0;
}

void MainWindow::on_txFirstCheckBox_stateChanged(int nstate)        //TxFirst
{
  m_txFirst = (nstate==2);
}

void MainWindow::set_ntx(int n)                                   //set_ntx()
{
  m_ntx=n;
}

void MainWindow::on_txb1_clicked()                                //txb1
{
  m_ntx=1;
  ui->txrb1->setChecked(true);
  m_restart=true;
}

void MainWindow::on_txb2_clicked()                                //txb2
{
  m_ntx=2;
  ui->txrb2->setChecked(true);
  m_restart=true;
}

void MainWindow::on_txb3_clicked()                                //txb3
{
  m_ntx=3;
  ui->txrb3->setChecked(true);
  m_restart=true;
}

void MainWindow::on_txb4_clicked()                                //txb4
{
  m_ntx=4;
  ui->txrb4->setChecked(true);
  m_restart=true;
}

void MainWindow::on_txb5_clicked()                                //txb5
{
  m_ntx=5;
  ui->txrb5->setChecked(true);
  m_restart=true;
}

void MainWindow::on_txb6_clicked()                                //txb6
{
  m_ntx=6;
  ui->txrb6->setChecked(true);
  m_restart=true;
}

void MainWindow::doubleClickOnCall2(bool shift, bool ctrl)
{
  m_decodedText2=true;
  doubleClickOnCall(shift,ctrl);
  m_decodedText2=false;
}

void MainWindow::doubleClickOnCall(bool shift, bool ctrl)
{
  QTextCursor cursor;
  if(!m_decodedText2) cursor=ui->decodedTextBrowser2->textCursor();
  if(m_decodedText2) cursor=ui->decodedTextBrowser->textCursor();
  cursor.select(QTextCursor::LineUnderCursor);
  int i2=cursor.position();
  if(shift and i2==-9999) return;        //Silence compiler warning

  QString t;
  if(!m_decodedText2) t= ui->decodedTextBrowser2->toPlainText(); //Full contents
  if(m_decodedText2) t= ui->decodedTextBrowser->toPlainText();

  QString t1 = t.mid(0,i2);              //contents up to \n on selected line
  int i1=t1.lastIndexOf("\n") + 1;       //points to first char of line
  DecodedText decodedtext;
  decodedtext = t1.mid(i1,i2-i1);         //selected line

  if (decodedtext.indexOf(" CQ ") > 0)
  {
      // TODO this magic 36 characters is also referenced in DisplayText::_appendDXCCWorkedB4()
      int s3 = decodedtext.indexOf(" ",35);
      if (s3 < 35)
          s3 = 35; // we always want at least the characters to position 35
      s3 += 1; // convert the index into a character count
      decodedtext = decodedtext.left(s3);  // remove DXCC entity and worked B4 status. TODO need a better way to do this
  }


//  if(decodedtext.indexOf("Tx")==6) return;        //Ignore Tx line
  int i4=t.mid(i1).length();
  if(i4>55) i4=55;
  QString t3=t.mid(i1,i4);
  int i5=t3.indexOf(" CQ DX ");
  if(i5>0) t3=t3.mid(0,i5+3) + "_" + t3.mid(i5+4);  //Make it "CQ_DX" (one word)
  QStringList t4=t3.split(" ",QString::SkipEmptyParts);
  if(t4.length() <5) return;             //Skip the rest if no decoded text

  int i9=m_QSOText.indexOf(decodedtext.string());
  if (i9<0 and !decodedtext.isTX())
  {
    ui->decodedTextBrowser2->displayDecodedText(decodedtext,m_myCall,false,m_logBook);
    m_QSOText=decodedtext;
  }


  int frequency = decodedtext.frequencyOffset();
  m_wideGraph->setRxFreq(frequency);                 //Set Rx freq
  if (decodedtext.isTX())
  {
    if (ctrl)
        ui->TxFreqSpinBox->setValue(frequency);      //Set Tx freq
    return;
  }

  QString firstcall = decodedtext.call();
  // Don't change Tx freq if a station is calling me, unless m_lockTxFreq
  // is true or CTRL is held down
  if ((firstcall!=m_myCall) or m_lockTxFreq or ctrl)
    ui->TxFreqSpinBox->setValue(frequency);

  if (decodedtext.isJT9())
  {
    m_modeTx="JT9";
    ui->pbTxMode->setText("Tx JT9  @");
    m_wideGraph->setModeTx(m_modeTx);
  }
  else
      if (decodedtext.isJT65())
      {
          m_modeTx="JT65";
          ui->pbTxMode->setText("Tx JT65  #");
          m_wideGraph->setModeTx(m_modeTx);
      }

  QString hiscall;
  QString hisgrid;
  decodedtext.deCallAndGrid(/*out*/hiscall,hisgrid);
  if (hiscall != ui->dxCallEntry->text())
      ui->dxGridEntry->setText("");
  ui->dxCallEntry->setText(hiscall);
  if (gridOK(hisgrid))
      ui->dxGridEntry->setText(hisgrid);
  if (ui->dxGridEntry->text()=="")
      lookup();
  m_hisGrid = ui->dxGridEntry->text();

  int n = decodedtext.timeInSeconds();
  int nmod=n%(m_TRperiod/30);
  m_txFirst=(nmod!=0);
  ui->txFirstCheckBox->setChecked(m_txFirst);

  QString rpt = decodedtext.report();
  ui->rptSpinBox->setValue(rpt.toInt());
  genStdMsgs(rpt);

  // determine the appropriate response to the received msg
  if(decodedtext.indexOf(m_myCall)>=0)
  {
    if (t4.length()>=7   // enough fields for a normal msg
        and !gridOK(t4.at(7))) // but no grid on end of msg
    {
      QString r=t4.at(7);
      if(r.mid(0,3)=="RRR") {
        m_ntx=5;
        ui->txrb5->setChecked(true);
        if(ui->tabWidget->currentIndex()==1) {
          ui->genMsg->setText(ui->tx5->text());
          m_ntx=7;
          ui->rbGenMsg->setChecked(true);
        }
      } else if(r.mid(0,1)=="R") {
        m_ntx=4;
        ui->txrb4->setChecked(true);
        if(ui->tabWidget->currentIndex()==1) {
          ui->genMsg->setText(ui->tx4->text());
          m_ntx=7;
          ui->rbGenMsg->setChecked(true);
        }
      } else if(r.toInt()>=-50 and r.toInt()<=49) {
        m_ntx=3;
        ui->txrb3->setChecked(true);
        if(ui->tabWidget->currentIndex()==1) {
          ui->genMsg->setText(ui->tx3->text());
          m_ntx=7;
          ui->rbGenMsg->setChecked(true);
        }
      } else if(r.toInt()==73) {
        m_ntx=5;
        ui->txrb5->setChecked(true);
        if(ui->tabWidget->currentIndex()==1) {
          ui->genMsg->setText(ui->tx5->text());
          m_ntx=7;
          ui->rbGenMsg->setChecked(true);
        }
      }
    } else {
      m_ntx=2;
      ui->txrb2->setChecked(true);
      if(ui->tabWidget->currentIndex()==1) {
        ui->genMsg->setText(ui->tx2->text());
        m_ntx=7;
        ui->rbGenMsg->setChecked(true);
      }
    }

  }
  else // myCall not in msg
  {
    m_ntx=1;
    ui->txrb1->setChecked(true);
    if(ui->tabWidget->currentIndex()==1) {
      ui->genMsg->setText(ui->tx1->text());
      m_ntx=7;
      ui->rbGenMsg->setChecked(true);
    }
  }
  if(m_quickCall) {
    m_auto=true;
    ui->autoButton->setStyleSheet(m_pbAutoOn_style);
  }
}

void MainWindow::genStdMsgs(QString rpt)                       //genStdMsgs()
{
  QString t;
  QString hisCall=ui->dxCallEntry->text().toUpper().trimmed();
  ui->dxCallEntry->setText(hisCall);
  if(hisCall=="") {
    ui->labAz->setText("");
    ui->labDist->setText("");
    ui->tx1->setText("");
    ui->tx2->setText("");
    ui->tx3->setText("");
    ui->tx4->setText("");
    ui->tx5->setText("");
    ui->tx6->setText("");
    if(m_myCall!="" and m_myGrid!="") {
      t="CQ " + m_myCall + " " + m_myGrid.mid(0,4);
      msgtype(t, ui->tx6);
    }
    ui->genMsg->setText("");
    ui->freeTextMsg->setText("");
    return;
  }
  QString hisBase=baseCall(hisCall);
  QString myBase=baseCall(m_myCall);

  QString t0=hisBase + " " + myBase + " ";
  t=t0 + m_myGrid.mid(0,4);
//  if(myBase!=m_myCall) t="DE " + m_myCall + " " + m_myGrid.mid(0,4);  //###
  msgtype(t, ui->tx1);
  if(rpt == "") {
    t=t+" OOO";
    msgtype(t, ui->tx2);
    msgtype("RO", ui->tx3);
    msgtype("RRR", ui->tx4);
    msgtype("73", ui->tx5);
  } else {
    t=t0 + rpt;
    msgtype(t, ui->tx2);
    t=t0 + "R" + rpt;
    msgtype(t, ui->tx3);
    t=t0 + "RRR";
    msgtype(t, ui->tx4);
    t=t0 + "73";
//    if(myBase!=m_myCall) t="DE " + m_myCall + " 73";                  //###
    msgtype(t, ui->tx5);
  }

  t="CQ " + m_myCall + " " + m_myGrid.mid(0,4);
  msgtype(t, ui->tx6);

  if(m_myCall!=myBase) {
    if(shortList(m_myCall)) {
      t="CQ " + m_myCall;
      msgtype(t, ui->tx6);
    } else {
      t="DE " + m_myCall + " " + m_myGrid.mid(0,4);
      msgtype(t, ui->tx2);
      t="DE " + m_myCall + " 73";
      msgtype(t, ui->tx5);
      t="CQ " + m_myCall + " " + m_myGrid.mid(0,4);
      msgtype(t, ui->tx6);
    }
  } else {
    if(hisCall!=hisBase) {
      if(shortList(hisCall)) {
        t=hisCall + " " + m_myCall;
        msgtype(t, ui->tx2);
      }
    }
  }
  m_ntx=1;
  ui->txrb1->setChecked(true);
  m_rpt=rpt;
}

QString MainWindow::baseCall(QString t)
{
  int n1=t.indexOf("/");
  if(n1<0) return t;
  int n2=t.length()-n1-1;
  if(n2>=n1) return t.mid(n1+1);
  return t.mid(0,n1);
}

void MainWindow::lookup()                                       //lookup()
{
  QString hisCall=ui->dxCallEntry->text().toUpper().trimmed();
  ui->dxCallEntry->setText(hisCall);
  QString call3File = m_appDir + "/CALL3.TXT";
  QFile f(call3File);
  if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + call3File);
    return;
  }
  char c[132];
  qint64 n=0;
  for(int i=0; i<999999; i++) {
    n=f.readLine(c,sizeof(c));
    if(n <= 0) {
      ui->dxGridEntry->setText("");
      break;
     }
    QString t=QString(c);
    if(t.indexOf(hisCall)==0) {
      int i1=t.indexOf(",");
      QString hisgrid=t.mid(i1+1,6);
      i1=hisgrid.indexOf(",");
      if(i1>0) {
        hisgrid=hisgrid.mid(0,4);
      } else {
        hisgrid=hisgrid.mid(0,4) + hisgrid.mid(4,2).toLower();
      }
      ui->dxGridEntry->setText(hisgrid);
      break;
    }
  }
  f.close();
}

void MainWindow::on_lookupButton_clicked()                    //Lookup button
{
  lookup();
}

void MainWindow::on_addButton_clicked()                       //Add button
{
  if(ui->dxGridEntry->text()=="") {
    msgBox("Please enter a valid grid locator.");
    return;
  }
  m_call3Modified=false;
  QString hisCall=ui->dxCallEntry->text().toUpper().trimmed();
  QString hisgrid=ui->dxGridEntry->text().trimmed();
  QString newEntry=hisCall + "," + hisgrid;

//  int ret = QMessageBox::warning(this, "Add",
//       newEntry + "\n" + "Is this station known to be active on EME?",
//       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
//  if(ret==QMessageBox::Yes) {
//    newEntry += ",EME,,";
//  } else {
    newEntry += ",,,";
//  }

  QString call3File = m_appDir + "/CALL3.TXT";
  QFile f1(call3File);
  if(!f1.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + call3File);
    return;
  }
  if(f1.size()==0) {
    f1.close();
    f1.open(QIODevice::WriteOnly | QIODevice::Text);
    QTextStream out(&f1);
    out << "ZZZZZZ" << endl;
    f1.close();
    f1.open(QIODevice::ReadOnly | QIODevice::Text);
  }
  QString tmpFile = m_appDir + "/CALL3.TMP";
  QFile f2(tmpFile);
  if(!f2.open(QIODevice::WriteOnly | QIODevice::Text)) {
    msgBox("Cannot open " + tmpFile);
    return;
  }
  QTextStream in(&f1);
  QTextStream out(&f2);
  QString hc=hisCall;
  QString hc1="";
  QString hc2="AAAAAA";
  QString s;
  do {
    s=in.readLine();
    hc1=hc2;
    if(s.mid(0,2)=="//") {
      out << s + "\n";
    } else {
      int i1=s.indexOf(",");
      hc2=s.mid(0,i1);
      if(hc>hc1 && hc<hc2) {
        out << newEntry + "\n";
        if(s.mid(0,6)=="ZZZZZZ") {
          out << s + "\n";
//          exit;                             //Statement has no effect!
        }
        m_call3Modified=true;
      } else if(hc==hc2) {
        QString t=s + "\n\n is already in CALL3.TXT\n" +
            "Do you wish to replace it?";
        int ret = QMessageBox::warning(this, "Add",t,
             QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
        if(ret==QMessageBox::Yes) {
          out << newEntry + "\n";
          m_call3Modified=true;
        }
      } else {
        if(s!="") out << s + "\n";
      }
    }
  } while(!s.isNull());

  f1.close();
  if(hc>hc1 && !m_call3Modified) {
    out << newEntry + "\n";
  }
  if(m_call3Modified) {
    QFile f0(m_appDir + "/CALL3.OLD");
    if(f0.exists()) f0.remove();
    QFile f1(m_appDir + "/CALL3.TXT");
    f1.rename(m_appDir + "/CALL3.OLD");
    f2.rename(m_appDir + "/CALL3.TXT");
    f2.close();
  }
}

void MainWindow::msgtype(QString t, QLineEdit* tx)               //msgtype()
{
  char message[23];
  char msgsent[23];
  int len1=22;

  t=t.toUpper();
  QByteArray s=t.toUpper().toLocal8Bit();
  ba2msg(s,message);
  int ichk=1,itext=0;
  genjt9_(message,&ichk,msgsent,itone,&itext,len1,len1);
  msgsent[22]=0;
  bool text=false;
  if(itext!=0) text=true;
  QString t1;
  t1.fromLatin1(msgsent);
  if(text) t1=t1.mid(0,13);
  QPalette p(tx->palette());
  if(text) {
    p.setColor(QPalette::Base,"#ffccff");
  } else {
    p.setColor(QPalette::Base,Qt::white);
  }
  tx->setPalette(p);
  int len=t.length();
  if(text) {
    len=qMin(len,13);
    tx->setText(t.mid(0,len).toUpper());
  } else {
    tx->setText(t);
  }
}

void MainWindow::on_tx1_editingFinished()                       //tx1 edited
{
  QString t=ui->tx1->text();
  msgtype(t, ui->tx1);
}

void MainWindow::on_tx2_editingFinished()                       //tx2 edited
{
  QString t=ui->tx2->text();
  msgtype(t, ui->tx2);
}

void MainWindow::on_tx3_editingFinished()                       //tx3 edited
{
  QString t=ui->tx3->text();
  msgtype(t, ui->tx3);
}

void MainWindow::on_tx4_editingFinished()                       //tx4 edited
{
  QString t=ui->tx4->text();
  msgtype(t, ui->tx4);
}

void MainWindow::on_tx5_editingFinished()                       //tx5 edited
{
  QString t=ui->tx5->text();
  msgtype(t, ui->tx5);
}

void MainWindow::on_tx6_editingFinished()                       //tx6 edited
{
  QString t=ui->tx6->text();
  msgtype(t, ui->tx6);

  // G4WJS: disabled setting of snr from msg 6 on live edit, will
  // still generate noise on next full tx period

  // double snr=t.mid(1,5).toDouble();
  // if(snr>0.0 or snr < -50.0) snr=99.0;
  // m_modulator.setTxSNR(snr);
}

void MainWindow::on_dxCallEntry_textChanged(const QString &t) //dxCall changed
{
  m_hisCall=t.toUpper().trimmed();
  ui->dxCallEntry->setText(m_hisCall);
  statusChanged();
}

void MainWindow::on_dxGridEntry_textChanged(const QString &t) //dxGrid changed
{
  int n=t.length();
  if(n!=4 and n!=6) {
    ui->labAz->setText("");
    ui->labDist->setText("");
    return;
  }
  if(!t[0].isLetter() or !t[1].isLetter()) return;
  if(!t[2].isDigit() or !t[3].isDigit()) return;
  if(n==4) m_hisGrid=t.mid(0,2).toUpper() + t.mid(2,2);
  if(n==6) m_hisGrid=t.mid(0,2).toUpper() + t.mid(2,2) +
      t.mid(4,2).toLower();
  ui->dxGridEntry->setText(m_hisGrid);
  if(gridOK(m_hisGrid)) {
    qint64 nsec = QDateTime::currentMSecsSinceEpoch() % 86400;
    double utch=nsec/3600.0;
    int nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter;

    azdist_(m_myGrid.toLatin1().data(),m_hisGrid.toLatin1().data(),&utch,
           &nAz,&nEl,&nDmiles,&nDkm,&nHotAz,&nHotABetter,6,6);
    QString t;
    t.sprintf("Az: %d",nAz);
    ui->labAz->setText(t);
    if(m_bMiles) t.sprintf("%d mi",int(0.621371*nDkm));
    if(!m_bMiles) t.sprintf("%d km",nDkm);
    ui->labDist->setText(t);
  } else {
    ui->labAz->setText("");
    ui->labDist->setText("");
  }
}

void MainWindow::on_genStdMsgsPushButton_clicked()         //genStdMsgs button
{
  genStdMsgs(m_rpt);
}

void MainWindow::on_logQSOButton_clicked()                 //Log QSO button
{
  if(m_hisCall=="") return;
  m_dateTimeQSO=QDateTime::currentDateTimeUtc();

  m_logDlg->initLogQSO(m_hisCall,m_hisGrid,m_modeTx,m_rptSent,m_rptRcvd,
                     m_dateTimeQSO,m_dialFreq+m_txFreq/1.0e6,
                     m_myCall,m_myGrid,m_noSuffix,m_toRTTY,m_dBtoComments);
}

void MainWindow::acceptQSO2(bool accepted)
{
    if(accepted)
    {
        QString band = ADIF::bandFromFrequency(m_dialFreq+m_txFreq/1.0e6);
        QString date = m_dateTimeQSO.toString("yyyy-MM-dd");
        date=date.mid(0,4) + date.mid(5,2) + date.mid(8,2);
        m_logBook.addAsWorked(m_hisCall,band,m_modeTx,date);

        if (m_clearCallGrid)
        {
          m_hisCall="";
          ui->dxCallEntry->setText("");
          m_hisGrid="";
          ui->dxGridEntry->setText("");
          m_rptSent="";
          m_rptRcvd="";
          m_qsoStart="";
          m_qsoStop="";
        }
    }
}

void MainWindow::on_actionJT9_1_triggered()
{
  m_mode="JT9";
  if(m_modeTx!="JT9") on_pbTxMode_clicked();
  statusChanged();
  m_TRperiod=60;
  m_nsps=6912;
  m_hsymStop=173;
  lab2->setStyleSheet("QLabel{background-color: #ff6ec7}");
  lab2->setText(m_mode);
  ui->actionJT9_1->setChecked(true);
  m_wideGraph->setPeriod(m_TRperiod,m_nsps);
  m_wideGraph->setMode(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  ui->pbTxMode->setEnabled(false);
}

void MainWindow::on_actionJT65_triggered()
{
  m_mode="JT65";
  if(m_modeTx!="JT65") on_pbTxMode_clicked();
  statusChanged();
  m_TRperiod=60;
  m_nsps=6912;                   //For symspec only
  m_hsymStop=173;
  lab2->setStyleSheet("QLabel{background-color: #ffff00}");
  lab2->setText(m_mode);
  ui->actionJT65->setChecked(true);
  m_wideGraph->setPeriod(m_TRperiod,m_nsps);
  m_wideGraph->setMode(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  ui->pbTxMode->setEnabled(false);
}

void MainWindow::on_actionJT9_JT65_triggered()
{
  m_mode="JT9+JT65";
//  if(m_modeTx!="JT9") on_pbTxMode_clicked();
  statusChanged();
  m_TRperiod=60;
  m_nsps=6912;
  m_hsymStop=173;
  lab2->setStyleSheet("QLabel{background-color: #ffa500}");
  lab2->setText(m_mode);
  ui->actionJT9_JT65->setChecked(true);
  m_wideGraph->setPeriod(m_TRperiod,m_nsps);
  m_wideGraph->setMode(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  ui->pbTxMode->setEnabled(true);
}

void MainWindow::on_TxFreqSpinBox_valueChanged(int n)
{
  m_txFreq=n;
  m_wideGraph->setTxFreq(n);
  if(m_lockTxFreq) ui->RxFreqSpinBox->setValue(n);
  Q_EMIT transmitFrequency (m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0));
}

void MainWindow::on_RxFreqSpinBox_valueChanged(int n)
{
  m_rxFreq=n;
  m_wideGraph->setRxFreq(n);
  if(m_lockTxFreq) ui->TxFreqSpinBox->setValue(n);
}

void MainWindow::on_actionQuickDecode_triggered()
{
  m_ndepth=1;
  ui->actionQuickDecode->setChecked(true);
}

void MainWindow::on_actionMediumDecode_triggered()
{
  m_ndepth=2;
  ui->actionMediumDecode->setChecked(true);
}

void MainWindow::on_actionDeepestDecode_triggered()
{
  m_ndepth=3;
  ui->actionDeepestDecode->setChecked(true);
}

void MainWindow::on_inGain_valueChanged(int n)
{
  m_inGain=n;
}

void MainWindow::on_actionMonitor_OFF_at_startup_triggered()
{
  m_monitorStartOFF=!m_monitorStartOFF;
}

void MainWindow::on_actionErase_ALL_TXT_triggered()          //Erase ALL.TXT
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file ALL.TXT ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QFile f("ALL.TXT");
    f.remove();
    m_RxLog=1;
  }
}

void MainWindow::on_actionErase_wsjtx_log_adi_triggered()
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file wsjtx_log.adi ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QFile f("wsjtx_log.adi");
    f.remove();
  }
}

void MainWindow::showMacros(const QPoint &pos)
{
  if(m_macro.length()<10) return;
  QPoint globalPos = ui->tx5->mapToGlobal(pos);
  QMenu popupMenu;
  QAction* popup1 = new QAction(m_macro[0],ui->tx5);
  QAction* popup2 = new QAction(m_macro[1],ui->tx5);
  QAction* popup3 = new QAction(m_macro[2],ui->tx5);
  QAction* popup4 = new QAction(m_macro[3],ui->tx5);
  QAction* popup5 = new QAction(m_macro[4],ui->tx5);
  QAction* popup6 = new QAction(m_macro[5],ui->tx5);
  QAction* popup7 = new QAction(m_macro[6],ui->tx5);
  QAction* popup8 = new QAction(m_macro[7],ui->tx5);
  QAction* popup9 = new QAction(m_macro[8],ui->tx5);
  QAction* popup10 = new QAction(m_macro[9],ui->tx5);

  if(m_macro[0]!="") popupMenu.addAction(popup1);
  if(m_macro[1]!="") popupMenu.addAction(popup2);
  if(m_macro[2]!="") popupMenu.addAction(popup3);
  if(m_macro[3]!="") popupMenu.addAction(popup4);
  if(m_macro[4]!="") popupMenu.addAction(popup5);
  if(m_macro[5]!="") popupMenu.addAction(popup6);
  if(m_macro[6]!="") popupMenu.addAction(popup7);
  if(m_macro[7]!="") popupMenu.addAction(popup8);
  if(m_macro[8]!="") popupMenu.addAction(popup9);
  if(m_macro[9]!="") popupMenu.addAction(popup10);

  connect(popup1,SIGNAL(triggered()), this, SLOT(onPopup1()));
  connect(popup2,SIGNAL(triggered()), this, SLOT(onPopup2()));
  connect(popup3,SIGNAL(triggered()), this, SLOT(onPopup3()));
  connect(popup4,SIGNAL(triggered()), this, SLOT(onPopup4()));
  connect(popup5,SIGNAL(triggered()), this, SLOT(onPopup5()));
  connect(popup6,SIGNAL(triggered()), this, SLOT(onPopup6()));
  connect(popup7,SIGNAL(triggered()), this, SLOT(onPopup7()));
  connect(popup8,SIGNAL(triggered()), this, SLOT(onPopup8()));
  connect(popup9,SIGNAL(triggered()), this, SLOT(onPopup9()));
  connect(popup10,SIGNAL(triggered()), this, SLOT(onPopup10()));
  popupMenu.exec(globalPos);
}

void MainWindow::onPopup1() { ui->tx5->setText(m_macro[0]); freeText(); }
void MainWindow::onPopup2() { ui->tx5->setText(m_macro[1]); freeText(); }
void MainWindow::onPopup3() { ui->tx5->setText(m_macro[2]); freeText(); }
void MainWindow::onPopup4() { ui->tx5->setText(m_macro[3]); freeText(); }
void MainWindow::onPopup5() { ui->tx5->setText(m_macro[4]); freeText(); }
void MainWindow::onPopup6() { ui->tx5->setText(m_macro[5]); freeText(); }
void MainWindow::onPopup7() { ui->tx5->setText(m_macro[6]); freeText(); }
void MainWindow::onPopup8() { ui->tx5->setText(m_macro[7]); freeText(); }
void MainWindow::onPopup9() { ui->tx5->setText(m_macro[8]); freeText(); }
void MainWindow::onPopup10() { ui->tx5->setText(m_macro[9]); freeText(); }

void MainWindow::freeText() { ui->freeTextMsg->setText(ui->tx5->text()); }

bool MainWindow::gridOK(QString g)
{
  bool b=g.mid(0,1).compare("A")>=0 and
      g.mid(0,1).compare("R")<=0 and
      g.mid(1,1).compare("A")>=0 and
      g.mid(1,1).compare("R")<=0 and
      g.mid(2,1).compare("0")>=0 and
      g.mid(2,1).compare("9")<=0 and
      g.mid(3,1).compare("0")>=0 and
      g.mid(3,1).compare("9")<=0;
  return b;
}

void MainWindow::on_actionConvert_JT9_x_to_RTTY_triggered(bool checked)
{
  m_toRTTY=checked;
}

void MainWindow::on_actionLog_dB_reports_to_Comments_triggered(bool checked)
{
  m_dBtoComments=checked;
}

void MainWindow::on_bandComboBox_activated(int index)
{
  int ret=0;
  QString rt;

  // Upload any queued spots before changing band
  psk_Reporter->sendReport();

  m_band=index;
  QString t=m_dFreq[index];
  m_dialFreq=t.toDouble();
  if(m_plus2kHz) m_dialFreq+=0.002;
  dialFreqChanged2(m_dialFreq);
  m_repeatMsg=0;
  m_secBandChanged=QDateTime::currentMSecsSinceEpoch()/1000;
  if(m_catEnabled) {
    if(!m_bRigOpen) {
      rigOpen();
    }
    if(m_bRigOpen) {
      m_dontReadFreq=true;
      ret=rig->setFreq(MHz(m_dialFreq));
      if(m_bSplit or m_bXIT) setXIT(m_txFreq);

      bumpFqso(11);
      bumpFqso(12);

      if(ret!=RIG_OK) {
        rt.sprintf("Set rig frequency failed:  %d",ret);
        msgBox(rt);
      }
    }
  }
  QFile f2("ALL.TXT");
  f2.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
  QTextStream out(&f2);
  out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
      << "  " << m_dialFreq << " MHz  " << m_mode << endl;
  f2.close();
  psk_Reporter->setLocalStation(m_myCall, m_myGrid, m_antDescription[m_band], "WSJT-X r" + rev.mid(6,4) );
}

void MainWindow::on_actionPrompt_to_log_QSO_triggered(bool checked)
{
  m_promptToLog=checked;
}

void MainWindow::on_actionBlank_line_between_decoding_periods_triggered(bool checked)
{
  m_insertBlank=checked;
}

void MainWindow::on_actionEnable_DXCC_entity_triggered(bool checked)
{
  m_displayDXCCEntity=checked;
  if (checked)
      m_logBook.init();  // re-read the log and cty.dat files

  if (checked)  // adjust the proportions between the two text displays
  {
      ui->gridLayout->setColumnStretch(0,55);
      ui->gridLayout->setColumnStretch(1,45);
  }
  else
  {
      ui->gridLayout->setColumnStretch(0,0);
      ui->gridLayout->setColumnStretch(1,0);
  }
}

void MainWindow::on_actionClear_DX_Call_and_Grid_after_logging_triggered(bool checked)
{
  m_clearCallGrid=checked;
}

void MainWindow::on_actionDisplay_distance_in_miles_triggered(bool checked)
{
  m_bMiles=checked;
  on_dxGridEntry_textChanged(m_hisGrid);
}

void MainWindow::on_pbCallCQ_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx6->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_pbAnswerCaller_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx2->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_pbSendRRR_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx4->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_pbAnswerCQ_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx1->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_pbSendReport_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx3->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_pbSend73_clicked()
{
  genStdMsgs(m_rpt);
  ui->genMsg->setText(ui->tx5->text());
  m_ntx=7;
  ui->rbGenMsg->setChecked(true);
  if(m_transmitting) m_restart=true;
}

void MainWindow::on_rbGenMsg_toggled(bool checked)
{
  m_freeText=!checked;
  if(!m_freeText) {
    m_ntx=7;
    if(m_transmitting) m_restart=true;
  }
}

void MainWindow::on_rbFreeText_toggled(bool checked)
{
  m_freeText=checked;
  if(m_freeText) {
    m_ntx=8;
    if (m_transmitting) m_restart=true;
  }
}

void MainWindow::on_freeTextMsg_editingFinished()
{
  QString t=ui->freeTextMsg->text();
  msgtype(t, ui->freeTextMsg);
}

void MainWindow::on_actionDouble_click_on_call_sets_Tx_Enable_triggered(bool checked)
{
  m_quickCall=checked;
  if(checked) {
    lab3->setText("Tx-Enable Armed");
  } else {
    lab3->setText("Tx-Enable Disarmed");
  }
}

void MainWindow::on_rptSpinBox_valueChanged(int n)
{
  m_rpt=QString::number(n);
  int ntx0=m_ntx;
  QString t=ui->tx5->text();
  genStdMsgs(m_rpt);
  ui->tx5->setText(t);
  m_ntx=ntx0;
  if(m_ntx==1) ui->txrb1->setChecked(true);
  if(m_ntx==2) ui->txrb2->setChecked(true);
  if(m_ntx==3) ui->txrb3->setChecked(true);
  if(m_ntx==4) ui->txrb4->setChecked(true);
  if(m_ntx==5) ui->txrb5->setChecked(true);
  if(m_ntx==6) ui->txrb6->setChecked(true);
  statusChanged();
}

void MainWindow::on_action_73TxDisable_triggered(bool checked)
{
  m_73TxDisable=checked;
}

void MainWindow::on_actionRunaway_Tx_watchdog_triggered(bool checked)
{
  m_runaway=checked;
}

void MainWindow::on_tuneButton_clicked()
{
  if(m_tune) {
    nc1=1;                                 //disable the countdown timer
    tuneButtonTimer->start(250);
  } else {
    m_tune=true;
    m_sent73=false;
    Q_EMIT tune ();
    m_repeatMsg=0;
    ui->tuneButton->setStyleSheet(m_pbTune_style);
  }
}

void MainWindow::on_stopTxButton_clicked()                    //Stop Tx
{
  if(m_tune) {
    m_tune=false;
    Q_EMIT tune (m_tune);
  }
  if(m_auto) on_autoButton_clicked();
  m_btxok=false;
  Q_EMIT muteAudioOutput ();
  m_repeatMsg=0;
  ui->tuneButton->setStyleSheet("");
}

void MainWindow::rigOpen()
{
  QString t;
  int ret;
  rig = new Rig();

  if(m_rig<9900) {
    if (!rig->init(m_rig)) {
      msgBox("Rig init failure");
      return;
    }
    QString sCATport=m_catPort;
#ifdef WIN32
    sCATport="\\\\.\\" + m_catPort;    //Allow COM ports above 9
#endif
    rig->setConf("rig_pathname", sCATport.toLatin1().data());
    char buf[80];
    sprintf(buf,"%d",m_serialRate);
    rig->setConf("serial_speed",buf);
    sprintf(buf,"%d",m_dataBits);
    rig->setConf("data_bits",buf);
    sprintf(buf,"%d",m_stopBits);
    rig->setConf("stop_bits",buf);
    rig->setConf("serial_handshake",m_handshake.toLatin1().data());
    if(m_handshakeIndex != 2) {
      rig->setConf("rts_state",m_bRTS ? "ON" : "OFF");
      rig->setConf("dtr_state",m_bDTR ? "ON" : "OFF");
    }
  }

  ret=rig->open(m_rig);
  if(ret==RIG_OK) {
    m_bRigOpen=true;
    m_bad=0;
    if(m_poll==0) ui->readFreq->setEnabled(true);
    m_CATerror=false;
  } else {
    t="Open rig failed";
    msgBox(t);
    m_catEnabled=false;
    m_bRigOpen=false;
    m_CATerror=true;
  }

  if(m_bRigOpen) {
		if(m_poll>0) {
			ui->readFreq->setStyleSheet("QPushButton{background-color: #00ff00; \
																	border-width: 0px; border-radius: 5px;}");
	} else {
		ui->readFreq->setStyleSheet("QPushButton{background-color: orange; \
																border-width: 0px; border-radius: 5px;}");
  }

  if(m_bSplit) ui->readFreq->setText("S");
  if(!m_bSplit) ui->readFreq->setText("");
  } else {
  if(m_CATerror) ui->readFreq->setStyleSheet("QPushButton{background-color: red; \
																					 border-width: 0px; border-radius: 5px;}");
  if(!m_CATerror) ui->readFreq->setStyleSheet("");
  ui->readFreq->setText("");
  }
}

void MainWindow::on_actionAllow_multiple_instances_triggered(bool checked)
{
  m_bMultipleOK=checked;
}

void MainWindow::on_pbR2T_clicked()
{
  int n=m_wideGraph->rxFreq();
  ui->TxFreqSpinBox->setValue(n);
}

void MainWindow::on_pbT2R_clicked()
{
  m_wideGraph->setRxFreq(m_txFreq);
}


void MainWindow::on_readFreq_clicked()
{
  if(m_transmitting) return;
  m_dontReadFreq=false;
  double fMHz=rig->getFreq(RIG_VFO_CURR)/1000000.0;
  if(fMHz<0.0) {
    QString rt;
    rt.sprintf("Rig control error %d\nFailed to read frequency.",
               int(1000000.0*fMHz));
    msgBox(rt);
    m_catEnabled=false;
  }
  if(fMHz<0.01 or fMHz>1300.0) fMHz=0;
  int ndiff=1000000.0*(fMHz-m_dialFreq);
  if(ndiff!=0) dialFreqChanged2(fMHz);
}

void MainWindow::on_pbTxMode_clicked()
{
  if(m_modeTx=="JT9") {
    m_modeTx="JT65";
    ui->pbTxMode->setText("Tx JT65  #");
  } else {
    m_modeTx="JT9";
    ui->pbTxMode->setText("Tx JT9  @");
  }
  m_wideGraph->setModeTx(m_modeTx);
  statusChanged();
}

void MainWindow::setXIT(int n)
{
  int ret;
  m_XIT = 0;
  if(m_bRigOpen) {
    m_XIT=(n/500)*500 - 1500;
    if(m_bXIT) {
      ret=rig->setXit((shortfreq_t)m_XIT,RIG_VFO_TX);
      if(ret!=RIG_OK) {
        QString rt;
        rt.sprintf("Setting RIG_VFO_TX failed:  %d",ret);
        msgBox(rt);
      }
    }
    if(m_bSplit) {
      ret=rig->setSplitFreq(MHz(m_dialFreq)+m_XIT,RIG_VFO_B);
    }
  }
  Q_EMIT transmitFrequency (m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0));
}

void MainWindow::setFreq4(int rxFreq, int txFreq)
{
  m_rxFreq=rxFreq;
  m_txFreq=txFreq;
  ui->RxFreqSpinBox->setValue(m_rxFreq);
  ui->TxFreqSpinBox->setValue(m_txFreq);
}

void MainWindow::on_cbTxLock_clicked(bool checked)
{
  m_lockTxFreq=checked;
  m_wideGraph->setLockTxFreq(m_lockTxFreq);
  if(m_lockTxFreq) on_pbR2T_clicked();
}

void MainWindow::on_actionTx2QSO_triggered(bool checked)
{
  m_tx2QSO=checked;
}

void MainWindow::on_cbPlus2kHz_toggled(bool checked)
{
  m_plus2kHz=checked;
  on_bandComboBox_activated(m_band);
}

void MainWindow::pollRigFreq()
{
  double fMHz;
  if(m_dontReadFreq) {
    m_dontReadFreq=false;
  } else if(!m_transmitting) {
    fMHz=rig->getFreq(RIG_VFO_CURR)/1000000.0;
    if(fMHz<0.0) {
      m_bad++;
      if(m_bad>=20) {
        QString rt;
        rt.sprintf("Rig control error %d\nFailed to read frequency.",
                   int(1000000.0*fMHz));
        msgBox(rt);
        m_catEnabled=false;
        ui->readFreq->setStyleSheet("QPushButton{background-color: red; \
                                    border-width: 0px; border-radius: 5px;}");
      }
    } else {
      int ndiff=1000000.0*(fMHz-m_dialFreq);
      if(ndiff!=0) dialFreqChanged2(fMHz);
    }
  }
}

void MainWindow::transmit (double snr)
{
  if (m_modeTx == "JT65")
    {
      Q_EMIT sendMessage (NUM_JT65_SYMBOLS, 4096.0 * 12000.0 / 11025.0, m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0), m_audioOutputChannel, true, snr);
    }
  else
    {
      Q_EMIT sendMessage (NUM_JT9_SYMBOLS, m_nsps, m_txFreq - (m_bSplit || m_bXIT ? m_XIT : 0), m_audioOutputChannel, true, snr);
    }
  Q_EMIT startAudioOutputStream (m_audioOutputDevice, AudioDevice::Mono == m_audioOutputChannel ? 1 : 2, m_msAudioOutputBuffered);
}

void MainWindow::on_outAttenuation_valueChanged (int a)
{
  qreal dBAttn (a / 10.);      // slider interpreted as hundredths of a dB
  ui->outAttenuation->setToolTip (tr ("Transmit digital gain ") + (a ? QString::number (-dBAttn, 'f', 1) : "0") + "dB");
  Q_EMIT outAttenuationChanged (dBAttn);
}

void MainWindow::on_actionShort_list_of_add_on_prefixes_and_suffixes_triggered()
{
  pPrefixes = new QTextEdit(0);
  pPrefixes->setReadOnly(true);
  pPrefixes->setFontPointSize(10);
  pPrefixes->setWindowTitle("Prefixes");
  pPrefixes->setGeometry(QRect(45,50,565,450));
  Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
      Qt::WindowMinimizeButtonHint;
  pPrefixes->setWindowFlags(flags);
  QString prefixes = m_appDir + "/prefixes.txt";
  QFile f(prefixes);
  if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + prefixes);
    return;
  }
  QTextStream s(&f);
  QString t;
  for(int i=0; i<100; i++) {
    t=s.readLine();
    pPrefixes->append(t);
    if(s.atEnd()) break;
  }
  pPrefixes->show();
}

void MainWindow::getpfx()
{
  m_prefix <<"1A" <<"1S" <<"3A" <<"3B6" <<"3B8" <<"3B9" <<"3C" <<"3C0" \
        <<"3D2" <<"3D2C" <<"3D2R" <<"3DA" <<"3V" <<"3W" <<"3X" <<"3Y" \
        <<"3YB" <<"3YP" <<"4J" <<"4L" <<"4S" <<"4U1I" <<"4U1U" <<"4W" \
        <<"4X" <<"5A" <<"5B" <<"5H" <<"5N" <<"5R" <<"5T" <<"5U" \
        <<"5V" <<"5W" <<"5X" <<"5Z" <<"6W" <<"6Y" <<"7O" <<"7P" \
        <<"7Q" <<"7X" <<"8P" <<"8Q" <<"8R" <<"9A" <<"9G" <<"9H" \
        <<"9J" <<"9K" <<"9L" <<"9M2" <<"9M6" <<"9N" <<"9Q" <<"9U" \
        <<"9V" <<"9X" <<"9Y" <<"A2" <<"A3" <<"A4" <<"A5" <<"A6" \
        <<"A7" <<"A9" <<"AP" <<"BS7" <<"BV" <<"BV9" <<"BY" <<"C2" \
        <<"C3" <<"C5" <<"C6" <<"C9" <<"CE" <<"CE0X" <<"CE0Y" <<"CE0Z" \
        <<"CE9" <<"CM" <<"CN" <<"CP" <<"CT" <<"CT3" <<"CU" <<"CX" \
        <<"CY0" <<"CY9" <<"D2" <<"D4" <<"D6" <<"DL" <<"DU" <<"E3" \
        <<"E4" <<"EA" <<"EA6" <<"EA8" <<"EA9" <<"EI" <<"EK" <<"EL" \
        <<"EP" <<"ER" <<"ES" <<"ET" <<"EU" <<"EX" <<"EY" <<"EZ" \
        <<"F" <<"FG" <<"FH" <<"FJ" <<"FK" <<"FKC" <<"FM" <<"FO" \
        <<"FOA" <<"FOC" <<"FOM" <<"FP" <<"FR" <<"FRG" <<"FRJ" <<"FRT" \
        <<"FT5W" <<"FT5X" <<"FT5Z" <<"FW" <<"FY" <<"M" <<"MD" <<"MI" \
        <<"MJ" <<"MM" <<"MU" <<"MW" <<"H4" <<"H40" <<"HA" \
        <<"HB" <<"HB0" <<"HC" <<"HC8" <<"HH" <<"HI" <<"HK" <<"HK0A" \
        <<"HK0M" <<"HL" <<"HM" <<"HP" <<"HR" <<"HS" <<"HV" <<"HZ" \
        <<"I" <<"IS" <<"IS0" <<"J2" <<"J3" <<"J5" <<"J6" \
        <<"J7" <<"J8" <<"JA" <<"JDM" <<"JDO" <<"JT" <<"JW" \
        <<"JX" <<"JY" <<"K" <<"KG4" <<"KH0" <<"KH1" <<"KH2" <<"KH3" \
        <<"KH4" <<"KH5" <<"KH5K" <<"KH6" <<"KH7" <<"KH8" <<"KH9" <<"KL" \
        <<"KP1" <<"KP2" <<"KP4" <<"KP5" <<"LA" <<"LU" <<"LX" <<"LY" \
        <<"LZ" <<"OA" <<"OD" <<"OE" <<"OH" <<"OH0" <<"OJ0" <<"OK" \
        <<"OM" <<"ON" <<"OX" <<"OY" <<"OZ" <<"P2" <<"P4" <<"PA" \
        <<"PJ2" <<"PJ7" <<"PY" <<"PY0F" <<"PT0S" <<"PY0T" <<"PZ" <<"R1F" \
        <<"R1M" <<"S0" <<"S2" <<"S5" <<"S7" <<"S9" <<"SM" <<"SP" \
        <<"ST" <<"SU" <<"SV" <<"SVA" <<"SV5" <<"SV9" <<"T2" <<"T30" \
        <<"T31" <<"T32" <<"T33" <<"T5" <<"T7" <<"T8" <<"T9" <<"TA" \
        <<"TF" <<"TG" <<"TI" <<"TI9" <<"TJ" <<"TK" <<"TL" \
        <<"TN" <<"TR" <<"TT" <<"TU" <<"TY" <<"TZ" <<"UA" <<"UA2" \
        <<"UA9" <<"UK" <<"UN" <<"UR" <<"V2" <<"V3" <<"V4" <<"V5" \
        <<"V6" <<"V7" <<"V8" <<"VE" <<"VK" <<"VK0H" <<"VK0M" <<"VK9C" \
        <<"VK9L" <<"VK9M" <<"VK9N" <<"VK9W" <<"VK9X" <<"VP2E" <<"VP2M" <<"VP2V" \
        <<"VP5" <<"VP6" <<"VP6D" <<"VP8" <<"VP8G" <<"VP8H" <<"VP8O" <<"VP8S" \
        <<"VP9" <<"VQ9" <<"VR" <<"VU" <<"VU4" <<"VU7" <<"XE" <<"XF4" \
        <<"XT" <<"XU" <<"XW" <<"XX9" <<"XZ" <<"YA" <<"YB" <<"YI" \
        <<"YJ" <<"YK" <<"YL" <<"YN" <<"YO" <<"YS" <<"YU" <<"YV" \
        <<"YV0" <<"Z2" <<"Z3" <<"ZA" <<"ZB" <<"ZC4" <<"ZD7" <<"ZD8" \
        <<"ZD9" <<"ZF" <<"ZK1N" <<"ZK1S" <<"ZK2" <<"ZK3" <<"ZL" <<"ZL7" \
        <<"ZL8" <<"ZL9" <<"ZP" <<"ZS" <<"ZS8" <<"KC4" <<"E5";

  m_suffix << "P" << "0" << "1" << "2" << "3" << "4" << "5" << "6" \
         << "7" << "8" << "9" << "A";

  for(int i=0; i<12; i++) {
    m_sfx.insert(m_suffix[i],true);
  }
  for(int i=0; i<339; i++) {
    m_pfx.insert(m_prefix[i],true);
  }
}

bool MainWindow::shortList(QString callsign)
{
  int n=callsign.length();
  int i1=callsign.indexOf("/");
  Q_ASSERT(i1>0 and i1<n);
  QString t1=callsign.mid(0,i1);
  QString t2=callsign.mid(i1+1,n-i1-1);
  bool b=(m_pfx.contains(t1) or m_sfx.contains(t2));
  return b;
}
