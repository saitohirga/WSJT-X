//-------------------------------------------------------------- MainWindow
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "devsetup.h"
#include "plotter.h"
#include "about.h"
#include "widegraph.h"
#include "sleep.h"
#include <portaudio.h>

#define NFFT 32768

short int iwave[30*48000];            //Wave file for Tx audio
int nwave;                            //Length of Tx waveform
bool btxok;                           //True if OK to transmit
double outputLatency;                 //Latency in seconds
qint16 id[30*48000];

WideGraph* g_pWideGraph = NULL;
QSharedMemory mem_m65("mem_m65");

QString rev="$Rev$";
QString Program_Title_Version="  JTMS3   v0.1, r" + rev.mid(6,4) +
                              "    by K1JT";

//-------------------------------------------------- MainWindow constructor
MainWindow::MainWindow(QWidget *parent) :
  QMainWindow(parent),
  ui(new Ui::MainWindow)
{
  ui->setupUi(this);

  on_EraseButton_clicked();
  ui->labUTC->setStyleSheet( \
        "QLabel { background-color : black; color : yellow; }");
  ui->labTol1->setStyleSheet( \
        "QLabel { background-color : white; color : black; }");
  ui->labTol1->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  ui->dxStationGroupBox->setStyleSheet("QFrame{border: 5px groove red}");

  QActionGroup* paletteGroup = new QActionGroup(this);
  ui->actionCuteSDR->setActionGroup(paletteGroup);
  ui->actionLinrad->setActionGroup(paletteGroup);
  ui->actionAFMHot->setActionGroup(paletteGroup);
  ui->actionBlue->setActionGroup(paletteGroup);

  QActionGroup* modeGroup = new QActionGroup(this);
  ui->actionJT65A->setActionGroup(modeGroup);
  ui->actionJT65B->setActionGroup(modeGroup);
  ui->actionJT65C->setActionGroup(modeGroup);

  QActionGroup* saveGroup = new QActionGroup(this);
  ui->actionSave_all->setActionGroup(saveGroup);
  ui->actionNone->setActionGroup(saveGroup);

  QActionGroup* DepthGroup = new QActionGroup(this);
  ui->actionNo_Deep_Search->setActionGroup(DepthGroup);
  ui->actionNormal_Deep_Search->setActionGroup(DepthGroup);
  ui->actionAggressive_Deep_Search->setActionGroup(DepthGroup);

  QButtonGroup* txMsgButtonGroup = new QButtonGroup;
  txMsgButtonGroup->addButton(ui->txrb1,1);
  txMsgButtonGroup->addButton(ui->txrb2,2);
  txMsgButtonGroup->addButton(ui->txrb3,3);
  txMsgButtonGroup->addButton(ui->txrb4,4);
  txMsgButtonGroup->addButton(ui->txrb5,5);
  txMsgButtonGroup->addButton(ui->txrb6,6);
  connect(txMsgButtonGroup,SIGNAL(buttonClicked(int)),SLOT(set_ntx(int)));
  connect(ui->decodedTextBrowser,SIGNAL(selectCallsign(bool)),this,
          SLOT(selectCall2(bool)));

  setWindowTitle(Program_Title_Version);

  connect(&soundInThread, SIGNAL(readyForFFT(int)),
             this, SLOT(dataSink(int)));
  connect(&soundInThread, SIGNAL(error(QString)), this,
          SLOT(showSoundInError(QString)));
  connect(&soundInThread, SIGNAL(status(QString)), this,
          SLOT(showStatusMessage(QString)));
  createStatusBar();

  connect(&proc_m65, SIGNAL(readyReadStandardOutput()),
                    this, SLOT(readFromStdout()));

  connect(&proc_m65, SIGNAL(error(QProcess::ProcessError)),
          this, SLOT(m65_error()));

  connect(&proc_m65, SIGNAL(readyReadStandardError()),
          this, SLOT(readFromStderr()));

  QTimer *guiTimer = new QTimer(this);
  connect(guiTimer, SIGNAL(timeout()), this, SLOT(guiUpdate()));
  guiTimer->start(100);                            //Don't change the 100 ms!

  m_auto=false;
  m_waterfallAvg = 1;
  m_network = true;
  m_txFirst=false;
  m_txMute=false;
  btxok=false;
  m_restart=false;
  m_transmitting=false;
  m_killAll=false;
  m_widebandDecode=false;
  m_ntx=1;
  m_myCall="K1JT";
  m_myGrid="FN20qi";
  m_appDir = QApplication::applicationDirPath();
  m_saveDir="/users/joe/jtms3/install/save";
  m_txFreq=125;
  m_setftx=0;
  m_loopall=false;
  m_startAnother=false;
  m_saveAll=false;
  m_onlyEME=false;
  m_sec0=-1;
  m_hsym0=-1;
  m_palette="CuteSDR";
  m_jtms3RxLog=1;                     //Write Date and Time to RxLog
  m_nutc0=9999;
  m_kb8rq=false;
  m_NB=false;
  m_mode="JT65B";
  m_mode65=2;
  m_fs96000=true;
  m_udpPort=50004;
  m_adjustIQ=0;
  m_applyIQcal=0;
  m_colors="000066ff0000ffff00969696646464";

  ui->xThermo->setFillBrush(Qt::green);

#ifdef WIN32
  while(true) {
      int iret=killbyname("m65.exe");
      if(iret == 603) break;
      if(iret != 0) msgBox("KillByName return code: " +
                           QString::number(iret));
  }
#endif
/*
  if(!mem_m65.attach()) {
    if (!mem_m65.create(sizeof(datcom_))) {
      msgBox("Unable to create shared memory segment.");
    }
  }
  char *to = (char*)mem_m65.data();
  int size=sizeof(datcom_);
  if(datcom_.newdat==0) {
    int noffset = 4*4*5760000 + 4*4*322*32768 + 4*4*32768;
    to += noffset;
    size -= noffset;
  }
  memset(to,0,size);         //Zero all decoding params in shared memory
*/
  PaError paerr=Pa_Initialize();                    //Initialize Portaudio
  if(paerr!=paNoError) {
    msgBox("Unable to initialize PortAudio.");
  }
  readSettings();		             //Restore user's setup params
  QFile lockFile(m_appDir + "/.lock"); //Create .lock so m65 will wait
  lockFile.open(QIODevice::ReadWrite);
  QFile quitFile(m_appDir + "/.lock");
  quitFile.remove();
//  proc_m65.start(QDir::toNativeSeparators(m_appDir + "/m65 -s"));

  m_pbdecoding_style1="QPushButton{background-color: cyan; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbmonitor_style="QPushButton{background-color: #00ff00; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbAutoOn_style="QPushButton{background-color: red; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";

  genStdMsgs("-26");
  on_actionWide_Waterfall_triggered();                   //###

  future1 = new QFuture<void>;
  watcher1 = new QFutureWatcher<void>;
  connect(watcher1, SIGNAL(finished()),this,SLOT(diskDat()));

  future2 = new QFuture<void>;
  watcher2 = new QFutureWatcher<void>;
  connect(watcher2, SIGNAL(finished()),this,SLOT(diskWriteFinished()));

// Assign input device and start input thread
  soundInThread.setInputDevice(m_paInDevice);
  soundInThread.start(QThread::HighestPriority);

  // Assign output device and start output thread
  soundOutThread.setOutputDevice(m_paOutDevice);
//  soundOutThread.start(QThread::HighPriority);

  m_monitoring=true;                           // Start with Monitoring ON
  soundInThread.setMonitoring(m_monitoring);
  m_diskData=false;
  m_tol=500;
  g_pWideGraph->setTol(m_tol);
  g_pWideGraph->setFsample(48000);

// Create "m_worked", a dictionary of all calls in wsjt.log
  QFile f("wsjt.log");
  f.open(QIODevice::ReadOnly);
  QTextStream in(&f);
  QString line,t,callsign;
  for(int i=0; i<99999; i++) {
    line=in.readLine();
    if(line.length()<=0) break;
    t=line.mid(18,12);
    callsign=t.mid(0,t.indexOf(","));
    m_worked[callsign]=true;
  }
  f.close();

  if(ui->actionLinrad->isChecked()) on_actionLinrad_triggered();
  if(ui->actionCuteSDR->isChecked()) on_actionCuteSDR_triggered();
  if(ui->actionAFMHot->isChecked()) on_actionAFMHot_triggered();
  if(ui->actionBlue->isChecked()) on_actionBlue_triggered();
                                             // End of MainWindow constructor
}

  //--------------------------------------------------- MainWindow destructor
MainWindow::~MainWindow()
{
  writeSettings();
  if (soundInThread.isRunning()) {
    soundInThread.quit();
    soundInThread.wait(3000);
  }
  if (soundOutThread.isRunning()) {
    soundOutThread.quitExecution=true;
    soundOutThread.wait(3000);
  }
  if(!m_decoderBusy) {
    QFile lockFile(m_appDir + "/.lock");
    lockFile.remove();
  }
  delete ui;
}

//-------------------------------------------------------- writeSettings()
void MainWindow::writeSettings()
{
  QString inifile = m_appDir + "/jtms3.ini";
  QSettings settings(inifile, QSettings::IniFormat);

  settings.beginGroup("MainWindow");
  settings.setValue("geometry", saveGeometry());
  settings.setValue("MRUdir", m_path);
  settings.setValue("TxFirst",m_txFirst);
  settings.setValue("DXcall",ui->dxCallEntry->text());
  settings.setValue("DXgrid",ui->dxGridEntry->text());

  if(g_pWideGraph->isVisible()) {
    m_wideGraphGeom = g_pWideGraph->geometry();
    settings.setValue("WideGraphGeom",m_wideGraphGeom);
  }

  settings.endGroup();

  settings.beginGroup("Common");
  settings.setValue("MyCall",m_myCall);
  settings.setValue("MyGrid",m_myGrid);
  settings.setValue("IDint",m_idInt);
  settings.setValue("PTTport",m_pttPort);
  settings.setValue("Xpol",m_xpol);
  settings.setValue("XpolX",m_xpolx);
  settings.setValue("SaveDir",m_saveDir);
  settings.setValue("AzElDir",m_azelDir);
  settings.setValue("DXCCpfx",m_dxccPfx);
  settings.setValue("Timeout",m_timeout);
  settings.setValue("IQamp",m_IQamp);
  settings.setValue("IQphase",m_IQphase);
  settings.setValue("ApplyIQcal",m_applyIQcal);
  settings.setValue("dPhi",m_dPhi);
  settings.setValue("Fcal",m_fCal);
  settings.setValue("Fadd",m_fAdd);
  settings.setValue("NetworkInput", m_network);
  settings.setValue("FSam96000", m_fs96000);
  settings.setValue("SoundInIndex",m_nDevIn);
  settings.setValue("paInDevice",m_paInDevice);
  settings.setValue("SoundOutIndex",m_nDevOut);
  settings.setValue("paOutDevice",m_paOutDevice);
  settings.setValue("IQswap",m_IQswap);
  settings.setValue("Plus10dB",m_10db);
  settings.setValue("InitIQplus",m_initIQplus);
  settings.setValue("UDPport",m_udpPort);
  settings.setValue("PaletteCuteSDR",ui->actionCuteSDR->isChecked());
  settings.setValue("PaletteLinrad",ui->actionLinrad->isChecked());
  settings.setValue("PaletteAFMHot",ui->actionAFMHot->isChecked());
  settings.setValue("PaletteBlue",ui->actionBlue->isChecked());
  settings.setValue("Mode",m_mode);
  settings.setValue("SaveNone",ui->actionNone->isChecked());
  settings.setValue("SaveAll",ui->actionSave_all->isChecked());
  settings.setValue("NDepth",m_ndepth);
  settings.setValue("NEME",m_onlyEME);
  settings.setValue("KB8RQ",m_kb8rq);
  settings.setValue("NB",m_NB);
  settings.setValue("NBslider",m_NBslider);
  settings.setValue("GainX",(double)m_gainx);
  settings.setValue("GainY",(double)m_gainy);
  settings.setValue("PhaseX",(double)m_phasex);
  settings.setValue("PhaseY",(double)m_phasey);
  settings.setValue("Mult570",m_mult570);
  settings.setValue("Cal570",m_cal570);
  settings.setValue("Colors",m_colors);
  settings.endGroup();
}

//---------------------------------------------------------- readSettings()
void MainWindow::readSettings()
{
  QString inifile = m_appDir + "/jtms3.ini";
  QSettings settings(inifile, QSettings::IniFormat);
  settings.beginGroup("MainWindow");
  restoreGeometry(settings.value("geometry").toByteArray());
  ui->dxCallEntry->setText(settings.value("DXcall","").toString());
  ui->dxGridEntry->setText(settings.value("DXgrid","").toString());
  m_wideGraphGeom = settings.value("WideGraphGeom", \
                                   QRect(45,30,1023,340)).toRect();
  m_path = settings.value("MRUdir", m_appDir + "/save").toString();
  m_txFirst = settings.value("TxFirst",false).toBool();
  ui->txFirstCheckBox->setChecked(m_txFirst);
  settings.endGroup();

  settings.beginGroup("Common");
  m_myCall=settings.value("MyCall","").toString();
  m_myGrid=settings.value("MyGrid","").toString();
  m_idInt=settings.value("IDint",0).toInt();
  m_pttPort=settings.value("PTTport",0).toInt();
  m_xpol=settings.value("Xpol",false).toBool();
  ui->actionFind_Delta_Phi->setEnabled(m_xpol);
  m_xpolx=settings.value("XpolX",false).toBool();
  m_saveDir=settings.value("SaveDir",m_appDir + "/save").toString();
  m_azelDir=settings.value("AzElDir",m_appDir).toString();
  m_dxccPfx=settings.value("DXCCpfx","").toString();
  m_timeout=settings.value("Timeout",20).toInt();
  m_IQamp=settings.value("IQamp",1.0000).toDouble();
  m_IQphase=settings.value("IQphase",0.0).toDouble();
  m_applyIQcal=settings.value("ApplyIQcal",0).toInt();
  ui->actionApply_IQ_Calibration->setChecked(m_applyIQcal!=0);
  m_dPhi=settings.value("dPhi",0).toInt();
  m_fCal=settings.value("Fcal",0).toInt();
  m_fAdd=settings.value("FAdd",0).toDouble();
  m_network = settings.value("NetworkInput",true).toBool();
  m_fs96000 = settings.value("FSam96000",true).toBool();
  m_nDevIn = settings.value("SoundInIndex", 0).toInt();
  m_paInDevice = settings.value("paInDevice",0).toInt();
  m_nDevOut = settings.value("SoundOutIndex", 0).toInt();
  m_paOutDevice = settings.value("paOutDevice",0).toInt();
  ui->actionCuteSDR->setChecked(settings.value(
                                  "PaletteCuteSDR",true).toBool());
  ui->actionLinrad->setChecked(settings.value(
                                 "PaletteLinrad",false).toBool());
  ui->actionAFMHot->setChecked(settings.value(
                                 "PaletteAFMHot",false).toBool());
  ui->actionBlue->setChecked(settings.value(
                                 "PaletteBlue",false).toBool());
  m_mode=settings.value("Mode","JT65B").toString();
  ui->actionNone->setChecked(settings.value("SaveNone",true).toBool());
  ui->actionSave_all->setChecked(settings.value("SaveAll",false).toBool());
  m_saveAll=ui->actionSave_all->isChecked();
  m_ndepth=settings.value("NDepth",0).toInt();
  m_onlyEME=settings.value("NEME",false).toBool();
  ui->actionOnly_EME_calls->setChecked(m_onlyEME);
  m_kb8rq=settings.value("KB8RQ",false).toBool();
  ui->actionF4_sets_Tx6->setChecked(m_kb8rq);
  m_gainx=settings.value("GainX",1.0).toFloat();
  m_gainy=settings.value("GainY",1.0).toFloat();
  m_phasex=settings.value("PhaseX",0.0).toFloat();
  m_phasey=settings.value("PhaseY",0.0).toFloat();
  m_mult570=settings.value("Mult570",2).toInt();
  m_cal570=settings.value("Cal570",0.0).toDouble();
  m_colors=settings.value("Colors","000066ff0000ffff00969696646464").toString();
  settings.endGroup();

  if(!ui->actionLinrad->isChecked() && !ui->actionCuteSDR->isChecked() &&
    !ui->actionAFMHot->isChecked() && !ui->actionBlue->isChecked()) {
    on_actionLinrad_triggered();
    ui->actionLinrad->setChecked(true);
  }
  if(m_ndepth==0) ui->actionNo_Deep_Search->setChecked(true);
  if(m_ndepth==1) ui->actionNormal_Deep_Search->setChecked(true);
  if(m_ndepth==2) ui->actionAggressive_Deep_Search->setChecked(true);
}

//-------------------------------------------------------------- dataSink()
void MainWindow::dataSink(int k)
{
  static int ndiskdat;
  static int nwrite=0;
  static int k0=99999999;
  static float px=0.0;
  static float sq0=0.0;
  static float sqave=1000.0;

  if(k < k0) {
    nwrite=0;
  }

  if(m_diskData) {
    ndiskdat=1;
    datcom_.ndiskdat=1;
  } else {
    ndiskdat=0;
    datcom_.ndiskdat=0;
  }

  float sq=0.0;
  float x;
  float fac=1.0/30.0;
  for(int i=0; i<6192; i++) {
    x=fac*datcom_.d2[k-6192+i];
    sq += x*x;
  }
  sqave=0.5*(sq+sq0);
  sq0=sq;
//  qDebug() << "rms:" << sqrt(sq/6192.0);
  px = 10.0*log10(sqave/6192.0);
  if(px>60.0) px=60.0;
  if(px<0.0) px=0.0;
  QString t;
  t.sprintf(" Rx noise: %5.1f ",px);
  lab2->setText(t);
  ui->xThermo->setValue((double)px);   //Update the bargraphs

  /*
  if(m_monitoring || m_diskData) {
    g_pWideGraph->dataSink2(s,nkhz,ihsym,m_diskData,lstrong);
  }

  //Average over specified number of spectra
  if (n==0) {
    for (int i=0; i<NFFT; i++)
      splot[i]=s[i];
  } else {
    for (int i=0; i<NFFT; i++)
      splot[i] += s[i];
  }
  n++;

  if (n>=m_waterfallAvg) {
    for (int i=0; i<NFFT; i++) {
        splot[i] /= n;                           //Normalize the average
    }

// Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int n60 = (ms/1000) % 60;
    if((m_diskData && ihsym <= m_waterfallAvg) || (!m_diskData && n60<n60z)) {
      for (int i=0; i<NFFT; i++) {
        splot[i] = 1.e30;
      }
    }
    n60z=n60;
    n=0;
  }
*/

  if(k >= (int)(29.5*48000) and nwrite==0) {
    nwrite=1;
    if(m_saveAll) {
      QDateTime t = QDateTime::currentDateTimeUtc();
      m_dateTime=t.toString("yyyy-MMM-dd hh:mm");
      QString fname=m_saveDir + "/" + m_hisCall + "_" +
          t.date().toString("yyMMdd") + "_" +
          t.time().toString("hhmmss") + ".wav";
      int i0=fname.indexOf(".wav");
      if(fname.mid(i0-2,2)=="29") fname=fname.mid(0,i0-2)+"00.wav";
      if(fname.mid(i0-2,2)=="59") fname=fname.mid(0,i0-2)+"30.wav";
      *future2 = QtConcurrent::run(savewav, fname);
      watcher2->setFuture(*future2);
    }
  }
  k0=k;
  soundInThread.m_dataSinkBusy=false;
}

void MainWindow::showSoundInError(const QString& errorMsg)
 {QMessageBox::critical(this, tr("Error in SoundIn"), errorMsg);}

void MainWindow::showStatusMessage(const QString& statusMsg)
 {statusBar()->showMessage(statusMsg);}

void MainWindow::on_actionDeviceSetup_triggered()               //Setup Dialog
{
  DevSetup dlg(this);
  dlg.m_myCall=m_myCall;
  dlg.m_myGrid=m_myGrid;
  dlg.m_idInt=m_idInt;
  dlg.m_pttPort=m_pttPort;
  dlg.m_saveDir=m_saveDir;
  dlg.m_azelDir=m_azelDir;
  dlg.m_dxccPfx=m_dxccPfx;
  dlg.m_nDevIn=m_nDevIn;
  dlg.m_nDevOut=m_nDevOut;

  dlg.initDlg();
  if(dlg.exec() == QDialog::Accepted) {
    m_myCall=dlg.m_myCall;
    m_myGrid=dlg.m_myGrid;
    m_idInt=dlg.m_idInt;
    m_pttPort=dlg.m_pttPort;
    m_saveDir=dlg.m_saveDir;
    m_dxccPfx=dlg.m_dxccPfx;
    g_pWideGraph->setFcal(m_fCal);
    m_nDevIn=dlg.m_nDevIn;
    m_paInDevice=dlg.m_paInDevice;
    m_nDevOut=dlg.m_nDevOut;
    m_paOutDevice=dlg.m_paOutDevice;

    if(dlg.m_restartSoundIn) {
      soundInThread.quit();
      soundInThread.wait(1000);
      soundInThread.setInputDevice(m_paInDevice);
      soundInThread.start(QThread::HighestPriority);
    }

    if(dlg.m_restartSoundOut) {
      soundOutThread.quitExecution=true;
      soundOutThread.wait(1000);
      soundOutThread.setOutputDevice(m_paOutDevice);
//      soundOutThread.start(QThread::HighPriority);
    }
  }
}

void MainWindow::on_monitorButton_clicked()                  //Monitor
{
  m_monitoring=true;
  soundInThread.setMonitoring(true);
  m_diskData=false;
}
void MainWindow::on_actionLinrad_triggered()                 //Linrad palette
{
  if(g_pWideGraph != NULL) g_pWideGraph->setPalette("Linrad");
}

void MainWindow::on_actionCuteSDR_triggered()                //CuteSDR palette
{
  if(g_pWideGraph != NULL) g_pWideGraph->setPalette("CuteSDR");
}

void MainWindow::on_actionAFMHot_triggered()
{
  if(g_pWideGraph != NULL) g_pWideGraph->setPalette("AFMHot");
}

void MainWindow::on_actionBlue_triggered()
{
  if(g_pWideGraph != NULL) g_pWideGraph->setPalette("Blue");
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
    ui->autoButton->setText("Auto is ON");
  } else {
    btxok=false;
    ui->autoButton->setStyleSheet("");
    ui->autoButton->setText("Auto is OFF");
    on_monitorButton_clicked();
  }
}

void MainWindow::on_stopTxButton_clicked()                    //Stop Tx
{
  if(m_auto) on_autoButton_clicked();
  btxok=false;
}

void MainWindow::keyPressEvent( QKeyEvent *e )                //keyPressEvent
{
  switch(e->key())
  {
  case Qt::Key_F3:
    m_txMute=!m_txMute;
    break;
  case Qt::Key_F4:
    ui->dxCallEntry->setText("");
    ui->dxGridEntry->setText("");
    if(m_kb8rq) {
      m_ntx=6;
      ui->txrb6->setChecked(true);
    }
  case Qt::Key_F6:
    if(e->modifiers() & Qt::ShiftModifier) {
      on_actionDecode_remaining_files_in_directory_triggered();
    }
    break;
  case Qt::Key_F11:
    if(e->modifiers() & Qt::ShiftModifier) {
    } else {
      int n0=g_pWideGraph->DF();
      int n=(n0 + 10000) % 5;
      if(n==0) n=5;
      g_pWideGraph->setDF(n0-n);
    }
    break;
  case Qt::Key_F12:
    if(e->modifiers() & Qt::ShiftModifier) {
    } else {
      int n0=g_pWideGraph->DF();
      int n=(n0 + 10000) % 5;
      if(n==0) n=5;
      g_pWideGraph->setDF(n0+n);
    }
    break;
  case Qt::Key_G:
    if(e->modifiers() & Qt::AltModifier) {
      genStdMsgs("-26");
      break;
    }
  case Qt::Key_L:
    if(e->modifiers() & Qt::ControlModifier) {
      lookup();
      genStdMsgs("-26");
      break;
    }
  }
}

void MainWindow::bumpDF(int n)                                  //bumpDF()
{
  if(n==11) {
    int n0=g_pWideGraph->DF();
    int n=(n0 + 10000) % 5;
    if(n==0) n=5;
    g_pWideGraph->setDF(n0-n);
  }
  if(n==12) {
    int n0=g_pWideGraph->DF();
    int n=(n0 + 10000) % 5;
    if(n==0) n=5;
    g_pWideGraph->setDF(n0+n);
  }
}

bool MainWindow::eventFilter(QObject *object, QEvent *event)  //eventFilter()
{
  if (event->type() == QEvent::KeyPress) {
    //Use the event in parent using its keyPressEvent()
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
  lab1->setMinimumSize(QSize(80,10));
  lab1->setStyleSheet("QLabel{background-color: #00ff00}");
  lab1->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab1);

  lab2 = new QLabel("");
  lab2->setAlignment(Qt::AlignHCenter);
  lab2->setMinimumSize(QSize(90,10));
  lab2->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab2);

  lab3 = new QLabel("Freeze DF:   0");
  lab3->setAlignment(Qt::AlignHCenter);
  lab3->setMinimumSize(QSize(80,10));
  lab3->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab3);

  /*
  lab4 = new QLabel("");
  lab4->setAlignment(Qt::AlignHCenter);
  lab4->setMinimumSize(QSize(80,10));
  lab4->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab4);

  lab5 = new QLabel("");
  lab5->setAlignment(Qt::AlignHCenter);
  lab5->setMinimumSize(QSize(50,10));
  lab5->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab5);
  */
}

void MainWindow::on_tolSpinBox_valueChanged(int i)             //tolSpinBox
{
  static int ntol[] = {10,20,50,100,200,500,1000};
  m_tol=ntol[i];
  g_pWideGraph->setTol(m_tol);
  ui->labTol1->setText(QString::number(ntol[i]));
}

void MainWindow::on_actionExit_triggered()                     //Exit()
{
  OnExit();
}

void MainWindow::closeEvent(QCloseEvent*)
{
  OnExit();
}

void MainWindow::OnExit()
{
  g_pWideGraph->saveSettings();
  m_killAll=true;
  mem_m65.detach();
  QFile quitFile(m_appDir + "/.quit");
  quitFile.open(QIODevice::ReadWrite);
  QFile lockFile(m_appDir + "/.lock");
  lockFile.remove();                      // Allow m65 to terminate
  bool b=proc_m65.waitForFinished(1000);
  if(!b) proc_m65.kill();
  quitFile.remove();
  qApp->exit(0);                          // Exit the event loop
}

void MainWindow::on_stopButton_clicked()                       //stopButton
{
  m_monitoring=false;
  soundInThread.setMonitoring(m_monitoring);
  m_loopall=false;  
}

void MainWindow::msgBox(QString t)                             //msgBox
{
  msgBox0.setText(t);
  msgBox0.exec();
}

void MainWindow::stub()                                        //stub()
{
  msgBox("Not yet implemented.");
}

void MainWindow::on_actionOnline_Users_Guide_triggered()      //Display manual
{
  QDesktopServices::openUrl(QUrl(
  "http://www.physics.princeton.edu/pulsar/K1JT/JTMS3_Users_Guide.pdf",
                              QUrl::TolerantMode));
}

void MainWindow::on_actionWide_Waterfall_triggered()      //Display Waterfalls
{
  if(g_pWideGraph==NULL) {
    g_pWideGraph = new WideGraph(0);
    g_pWideGraph->setWindowTitle("Wide Graph");
    g_pWideGraph->setGeometry(m_wideGraphGeom);
    Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
        Qt::WindowMinimizeButtonHint;
    g_pWideGraph->setWindowFlags(flags);
    connect(g_pWideGraph, SIGNAL(freezeDecode2(int)),this,
            SLOT(freezeDecode(int)));
    connect(g_pWideGraph, SIGNAL(f11f12(int)),this,
            SLOT(bumpDF(int)));
  }
//  g_pWideGraph->show();
}

void MainWindow::on_actionOpen_triggered()                     //Open File
{
  m_monitoring=false;
  soundInThread.setMonitoring(m_monitoring);
  QString fname;
  fname=QFileDialog::getOpenFileName(this, "Open File", m_path,
                                       "JTMS3 Files (*.wav)");
  if(fname != "") {
    m_path=fname;
    int i;
    i=fname.indexOf(".iq") - 11;
    if(m_xpol) i=fname.indexOf(".tf2") - 11;
    if(i>=0) {
      lab1->setStyleSheet("QLabel{background-color: #66ff66}");
      lab1->setText(" " + fname.mid(i,15) + " ");
    }
    on_stopButton_clicked();
    m_diskData=true;
    int dbDgrd=0;
    if(m_myCall=="K1JT" and m_idInt<0) dbDgrd=m_idInt;
    *future1 = QtConcurrent::run(getfile, fname, m_xpol, dbDgrd);
    watcher1->setFuture(*future1);
  }
}

void MainWindow::on_actionOpen_next_in_directory_triggered()   //Open Next
{
  int i,len;
  QFileInfo fi(m_path);
  QStringList list;
  if(m_xpol) {
      list= fi.dir().entryList().filter(".tf2");
      len=15;
  } else {
      list= fi.dir().entryList().filter(".iq");
      len=14;
  }
  for (i = 0; i < list.size()-1; ++i) {
    if(i==list.size()-2) m_loopall=false;
    if(list.at(i)==m_path.right(len)) {
      int n=m_path.length();
      QString fname=m_path.replace(n-len,len,list.at(i+1));
      m_path=fname;
      int i;
      i=fname.indexOf(".iq") - 11;
      if(m_xpol) i=fname.indexOf(".tf2") - 11;
      if(i>=0) {
        lab1->setStyleSheet("QLabel{background-color: #66ff66}");
        lab1->setText(" " + fname.mid(i,len) + " ");
      }
      m_diskData=true;
      int dbDgrd=0;
      if(m_myCall=="K1JT" and m_idInt<0) dbDgrd=m_idInt;
      *future1 = QtConcurrent::run(getfile, fname, m_xpol, dbDgrd);
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
  //These may be redundant??
  m_diskData=true;
//  datcom_.newdat=1;

  /*
  double hsym;
  if(m_fs96000) hsym=2048.0*96000.0/11025.0;   //Samples per JT65 half-symbol
  if(!m_fs96000) hsym=2048.0*95238.1/11025.0;
  for(int i=0; i<281; i++) {              // Do the half-symbol FFTs
    int k = i*hsym + 2048.5;
    dataSink(k);
    if(i%10 == 0) qApp->processEvents();   //Keep the GUI responsive
  }
  */
}

void MainWindow::diskWriteFinished()                       //diskWriteFinished
{
//  qDebug() << "diskWriteFinished";
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

void MainWindow::on_actionFind_Delta_Phi_triggered()              //Find dPhi
{
  m_jtms3RxLog |= 8;
  on_DecodeButton_clicked();
}

void MainWindow::on_actionF4_sets_Tx6_triggered()                //F4 sets Tx6
{
  m_kb8rq = !m_kb8rq;
}

void MainWindow::on_actionOnly_EME_calls_triggered()          //EME calls only
{
  m_onlyEME = ui->actionOnly_EME_calls->isChecked();
}

void MainWindow::on_actionNo_shorthands_if_Tx1_triggered()
{
  stub();
}

void MainWindow::on_actionNo_Deep_Search_triggered()          //No Deep Search
{
  m_ndepth=0;
}

void MainWindow::on_actionNormal_Deep_Search_triggered()      //Normal DS
{
  m_ndepth=1;
}

void MainWindow::on_actionAggressive_Deep_Search_triggered()  //Aggressive DS
{
  m_ndepth=2;
}

void MainWindow::on_actionNone_triggered()                    //Save None
{
  m_saveAll=false;
}

// ### Implement "Save Last" here? ###

void MainWindow::on_actionSave_all_triggered()                //Save All
{
  m_saveAll=true;
}
                                          //Display list of keyboard shortcuts
void MainWindow::on_actionKeyboard_shortcuts_triggered()
{
  stub();
}
                                              //Display list of mouse commands
void MainWindow::on_actionSpecial_mouse_commands_triggered()
{
  stub();
}
                                              //Diaplay list of Add-On pfx/sfx
void MainWindow::on_actionAvailable_suffixes_and_add_on_prefixes_triggered()
{
  stub();
}

void MainWindow::on_DecodeButton_clicked()                    //Decode request
{
  /*
  int n=m_sec0%60;
  if(m_monitoring and n>47 and (n<52 or m_decoderBusy)) return;
  if(!m_decoderBusy) {
    datcom_.newdat=0;
    datcom_.nagain=1;
    decode();
  }
  */
}

void MainWindow::freezeDecode(int n)                          //freezeDecode()
{
  /*
  if(n==2) {
    ui->tolSpinBox->setValue(5);
    datcom_.ntol=m_tol;
    datcom_.mousedf=0;
  } else {
    ui->tolSpinBox->setValue(3);
    datcom_.ntol=m_tol;
  }
  if(!m_decoderBusy) {
    datcom_.nagain=1;
    datcom_.newdat=0;
    decode();
  }
  */
}

void MainWindow::decode()                                       //decode()
{
/*
  ui->DecodeButton->setStyleSheet(m_pbdecoding_style1);
  if(datcom_.nagain==0 && (!m_diskData)) {
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int imin=ms/60000;
    int ihr=imin/60;
    imin=imin % 60;
    datcom_.nutc=100*ihr + imin;
  }

  datcom_.idphi=m_dPhi;
  datcom_.mousedf=g_pWideGraph->DF();
  datcom_.mousefqso=g_pWideGraph->QSOfreq();
  datcom_.ndepth=m_ndepth;
  datcom_.ndiskdat=0;
  if(m_diskData) datcom_.ndiskdat=1;
  datcom_.neme=0;
  if(ui->actionOnly_EME_calls->isChecked()) datcom_.neme=1;

  int ispan=int(g_pWideGraph->fSpan());
  if(ispan%2 == 1) ispan++;
  int ifc=int(1000.0*(datcom_.fcenter - int(datcom_.fcenter))+0.5);
  int nfa=g_pWideGraph->nStartFreq();
  int nfb=nfa+ispan;
  int nfshift=nfa + ispan/2 - ifc;

  datcom_.nfa=nfa;
  datcom_.nfb=nfb;
  datcom_.nfcal=m_fCal;
  datcom_.nfshift=nfshift;
  datcom_.mcall3=0;
  if(m_call3Modified) datcom_.mcall3=1;
  datcom_.ntimeout=m_timeout;
  datcom_.ntol=m_tol;
  datcom_.nxant=0;
  if(m_xpolx) datcom_.nxant=1;
  if(datcom_.nutc < m_nutc0) m_jtms3RxLog |= 1;  //Date and Time to all65.txt
  m_nutc0=datcom_.nutc;
//  datcom_.jtms3RxLog=m_jtms3RxLog;
  datcom_.nfsample=96000;
  if(!m_fs96000) datcom_.nfsample=95238;
  datcom_.nxpol=0;
  if(m_xpol) datcom_.nxpol=1;
  datcom_.mode65=m_mode65;

  QString mcall=(m_myCall+"            ").mid(0,12);
  QString mgrid=(m_myGrid+"            ").mid(0,6);
  QString hcall=(ui->dxCallEntry->text()+"            ").mid(0,12);
  QString hgrid=(ui->dxGridEntry->text()+"      ").mid(0,6);

  strncpy(datcom_.mycall, mcall.toAscii(), 12);
  strncpy(datcom_.mygrid, mgrid.toAscii(), 6);
  strncpy(datcom_.hiscall, hcall.toAscii(), 12);
  strncpy(datcom_.hisgrid, hgrid.toAscii(), 6);
  strncpy(datcom_.datetime, m_dateTime.toAscii(), 20);

  //newdat=1  ==> this is new data, must do the big FFT
  //nagain=1  ==> decode only at fQSO +/- Tol

  char *to = (char*)mem_m65.data();
  char *from = (char*) datcom_.d4;
  int size=sizeof(datcom_);
  if(datcom_.newdat==0) {
    int noffset = 4*4*5760000 + 4*4*322*32768 + 4*4*32768;
    to += noffset;
    from += noffset;
    size -= noffset;
  }
  memcpy(to, from, qMin(mem_m65.size(), size));
  datcom_.nagain=0;
  datcom_.ndiskdat=0;
  m_call3Modified=false;

  QFile lockFile(m_appDir + "/.lock");       // Allow m65 to start
  lockFile.remove();

  decodeBusy(true);
  */
}

void MainWindow::m65_error()                                     //m65_error
{
  if(!m_killAll) {
    msgBox("Error starting or running\n" + m_appDir + "/m65 -s");
    exit(1);
  }
}

void MainWindow::readFromStderr()                             //readFromStderr
{
  QByteArray t=proc_m65.readAllStandardError();
  msgBox(t);
}


void MainWindow::readFromStdout()                             //readFromStdout
{
  while(proc_m65.canReadLine())
  {
    QByteArray t=proc_m65.readLine();
    if(t.indexOf("<m65aFinished>") >= 0) {
      if(m_widebandDecode) {
        m_widebandDecode=false;
      }
      QFile lockFile(m_appDir + "/.lock");
      lockFile.open(QIODevice::ReadWrite);
      ui->DecodeButton->setStyleSheet("");
      decodeBusy(false);
      m_jtms3RxLog=0;
      m_startAnother=m_loopall;
      return;
    }

    if(t.indexOf("!") >= 0) {
      int n=t.length();
      if(n>=30) ui->decodedTextBrowser->append(t.mid(1,n-3));
      if(n<30) ui->decodedTextBrowser->append(t.mid(1,n-3));
      n=ui->decodedTextBrowser->verticalScrollBar()->maximum();
      ui->decodedTextBrowser->verticalScrollBar()->setValue(n);
    }

    if(t.indexOf("@") >= 0) {
//      m_messagesText += t.mid(1);
      m_widebandDecode=true;
    }

    if(t.indexOf("&") >= 0) {
      QString q(t);
      QString callsign=q.mid(5);
      callsign=callsign.mid(0,callsign.indexOf(" "));
      if(callsign.length()>2) {
        if(m_worked[callsign]) {
          q=q.mid(1,4) + "  " + q.mid(5);
        } else {
          q=q.mid(1,4) + " *" + q.mid(5);
        }
//        m_bandmapText += q;
      }
    }
  }
}

void MainWindow::on_EraseButton_clicked()                          //Erase
{
  ui->decodedTextBrowser->clear();
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
  static int iptt=0;
  static bool btxok0=false;
  static int nc0=1;
  static int nc1=1;
  static char msgsent[23];
  static int nsendingsh=0;
  int khsym=0;
  double trperiod=30.0;

  double tx1=0.0;
  double tx2=trperiod;

  if(!m_txFirst) {
    tx1 += trperiod;
    tx2 += trperiod;
  }
  qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
  int nsec=ms/1000;
  double tsec=0.001*ms;
  double t2p=fmod(tsec,2*trperiod);
  bool bTxTime = t2p >= tx1 && t2p < tx2;

  if(m_auto) {
    if(bTxTime and iptt==0 and !m_txMute) {
      int itx=1;
      int ierr = ptt_(&m_pttPort,&itx,&iptt);       // Raise PTT
      if(ierr != 0) {
        on_stopTxButton_clicked();
        char s[18];
        sprintf(s,"Cannot open COM%d",m_pttPort);
        msgBox(s);
      }
      if(!soundOutThread.isRunning()) {
        soundOutThread.start(QThread::HighPriority);
      }
    }
    if(!bTxTime || m_txMute) {
      btxok=false;
    }
  }

// Calculate Tx waveform when needed
  if((iptt==1 && iptt0==0) || m_restart) {
    char message[23];
    QByteArray ba;
    if(m_ntx == 1) ba=ui->tx1->text().toLocal8Bit();
    if(m_ntx == 2) ba=ui->tx2->text().toLocal8Bit();
    if(m_ntx == 3) ba=ui->tx3->text().toLocal8Bit();
    if(m_ntx == 4) ba=ui->tx4->text().toLocal8Bit();
    if(m_ntx == 5) ba=ui->tx5->text().toLocal8Bit();
    if(m_ntx == 6) ba=ui->tx6->text().toLocal8Bit();

    ba2msg(ba,message);
    int len1=22;
    genjtms3_(message,msgsent,iwave,&nwave,len1,len1);
    msgsent[22]=0;

    if(m_restart) {
      QFile f("jtms3_tx.log");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
          << "  Tx message:  " << QString::fromAscii(msgsent) << endl;
      f.close();
    }

    m_restart=false;
  }

// If PTT was just raised, start a countdown for raising TxOK:
  if(iptt==1 && iptt0==0) nc1=-9;    // TxDelay = 0.8 s
  if(nc1 <= 0) nc1++;
  if(nc1 == 0) {
    ui->xThermo->setValue(0.0);   //Set the Thermos to zero
    m_monitoring=false;
    soundInThread.setMonitoring(false);
    btxok=true;
    m_transmitting=true;

    QFile f("jtms3_tx.log");
    f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
    QTextStream out(&f);
    out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
        << "  Tx message:  " << QString::fromAscii(msgsent) << endl;
    f.close();
  }

// If btxok was just lowered, start a countdown for lowering PTT
  if(!btxok && btxok0 && iptt==1) nc0=-11;  //RxDelay = 1.0 s
  if(nc0 <= 0) nc0++;
  if(nc0 == 0) {
    int itx=0;
    ptt_(&m_pttPort,&itx,&iptt);       // Lower PTT
    if(!m_txMute) soundOutThread.quitExecution=true;
    m_transmitting=false;
    if(m_auto) {
      m_monitoring=true;
      soundInThread.setMonitoring(m_monitoring);
    }
  }

  if(iptt == 0 && !btxok) {
    // sending=""
    // nsendingsh=0
  }

  if(m_monitoring) {
    ui->monitorButton->setStyleSheet(m_pbmonitor_style);
  } else {
    ui->monitorButton->setStyleSheet("");
  }

  lab3->setText("Freeze DF:  " + QString::number(g_pWideGraph->DF()));

  if(m_startAnother) {
    m_startAnother=false;
    on_actionOpen_next_in_directory_triggered();
  }

  if(nsec != m_sec0) {                                     //Once per second

    if(m_transmitting) {
      if(nsendingsh==1) {
        lab1->setStyleSheet("QLabel{background-color: #66ffff}");
      } else if(nsendingsh==-1) {
        lab1->setStyleSheet("QLabel{background-color: #ffccff}");
      } else {
        lab1->setStyleSheet("QLabel{background-color: #ffff33}");
      }
      char s[37];
      sprintf(s,"Tx: %s",msgsent);
      lab1->setText(s);
    } else if(m_monitoring) {
      lab1->setStyleSheet("QLabel{background-color: #00ff00}");
      khsym=soundInThread.mstep();
      QString t;
      if(m_network) {
        if(m_nrx==-1) t="F1";
        if(m_nrx==1) t="I1";
        if(m_nrx==-2) t="F2";
        if(m_nrx==+2) t="I2";
      } else {
        if(m_nrx==1) t="S1";
        if(m_nrx==2) t="S2";
      }
      if((abs(m_nrx)==1 and m_xpol) or (abs(m_nrx)==2 and !m_xpol))
        lab1->setStyleSheet("QLabel{background-color: #ff1493}");
      if(khsym==m_hsym0) {
        t="Nil";
        lab1->setStyleSheet("QLabel{background-color: #ffc0cb}");
      }
      lab1->setText("Receiving " + t);
    } else if (!m_diskData) {
      lab1->setStyleSheet("");
      lab1->setText("");
    }

    QDateTime t = QDateTime::currentDateTimeUtc();
    m_setftx=0;
    QString utc = " " + t.time().toString() + " ";
    ui->labUTC->setText(utc);
    if((!m_monitoring and !m_diskData) or (khsym==m_hsym0)) {
      ui->xThermo->setValue(0.0);                      // Set Rx level to 20
      lab2->setText(" Rx noise:    0.0 ");
    }
    m_hsym0=khsym;
    m_sec0=nsec;
  }
  iptt0=iptt;
  btxok0=btxok;
}

void MainWindow::ba2msg(QByteArray ba, char message[])             //ba2msg()
{
  bool eom;
  eom=false;
  for(int i=0;i<22; i++) {
    if((int)ba[i] == 0) eom=true;
    if(eom) {
      message[i]=32;
    } else {
      message[i]=ba[i];
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

void MainWindow::selectCall2(bool ctrl)                                //selectCall2
{
  QString t = ui->decodedTextBrowser->toPlainText();   //Full contents
  int i=ui->decodedTextBrowser->textCursor().position();
  int i0=t.lastIndexOf(" ",i);
  int i1=t.indexOf(" ",i);
  QString hiscall=t.mid(i0+1,i1-i0-1);
  if(hiscall!="") {
    if(hiscall.length() < 13) doubleClickOnCall(hiscall, ctrl);
  }
}
                                                          //doubleClickOnCall
void MainWindow::doubleClickOnCall(QString hiscall, bool ctrl)
{
  if(m_worked[hiscall]) {
    msgBox("Possible dupe: " + hiscall + " already in log.");
  }
  ui->dxCallEntry->setText(hiscall);
  QString t = ui->decodedTextBrowser->toPlainText();   //Full contents
  int i2=ui->decodedTextBrowser->textCursor().position();
  QString t1 = t.mid(0,i2);              //contents up to text cursor
  int i1=t1.lastIndexOf("\n") + 1;
  QString t2 = t1.mid(i1,i2-i1);         //selected line
  int n = 60*t2.mid(13,2).toInt() + t2.mid(15,2).toInt();
  m_txFirst = ((n%2) == 1);
  ui->txFirstCheckBox->setChecked(m_txFirst);
  QString rpt="";
  if(ctrl) rpt=t2.mid(23,3);
  lookup();
  rpt="-26";
  genStdMsgs(rpt);
  if(t2.indexOf(m_myCall)>0) {
    m_ntx=2;
    ui->txrb2->setChecked(true);
  } else {
    m_ntx=1;
    ui->txrb1->setChecked(true);
  }
}

void MainWindow::genStdMsgs(QString rpt)                       //genStdMsgs()
{
  QString hiscall=ui->dxCallEntry->text().toUpper().trimmed();
  ui->dxCallEntry->setText(hiscall);
  QString t0=hiscall + " " + m_myCall + " ";
  QString t=t0 + m_myGrid.mid(0,4);
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
    msgtype(t, ui->tx5);
  }
  t="CQ " + m_myCall + " " + m_myGrid.mid(0,4);
  msgtype(t, ui->tx6);
  m_ntx=1;
  ui->txrb1->setChecked(true);
}

void MainWindow::lookup()                                       //lookup()
{
  QString hiscall=ui->dxCallEntry->text().toUpper().trimmed();
  ui->dxCallEntry->setText(hiscall);
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
    if(t.indexOf(hiscall)==0) {
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
  QString hiscall=ui->dxCallEntry->text().toUpper().trimmed();
  QString hisgrid=ui->dxGridEntry->text().trimmed();
  QString newEntry=hiscall + "," + hisgrid;

  int ret = QMessageBox::warning(this, "Add",
       newEntry + "\n" + "Is this station known to be active on EME?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    newEntry += ",EME,,";
  } else {
    newEntry += ",,,";
  }
  QString call3File = m_appDir + "/CALL3.TXT";
  QFile f1(call3File);
  if(!f1.open(QIODevice::ReadOnly | QIODevice::Text)) {
    msgBox("Cannot open " + call3File);
    return;
  }
  QString tmpFile = m_appDir + "/CALL3.TMP";
  QFile f2(tmpFile);
  if(!f2.open(QIODevice::WriteOnly | QIODevice::Text)) {
    msgBox("Cannot open " + tmpFile);
    return;
  }
  QTextStream in(&f1);
  QTextStream out(&f2);
  QString hc=hiscall;
  QString hc1="";
  QString hc2="";
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
        out << s + "\n";
      }
    }
  } while(!s.isNull());

  f1.close();
  if(hc>hc1 && !m_call3Modified)
    out << newEntry + "\n";
  if(m_call3Modified) {
    QFile f0(m_appDir + "/CALL3.OLD");
    if(f0.exists()) f0.remove();
    QFile f1(m_appDir + "/CALL3.TXT");
    f1.rename(m_appDir + "/CALL3.OLD");
    f2.rename(m_appDir + "/CALL3.TXT");
    f2.close();
  }
}

void MainWindow::msgtype(QString t, QLineEdit* tx)                //msgtype()
{
//  if(t.length()<1) return 0;
  char message[23];
  char msgsent[23];
  int len1=22;
  int mode65=0;            //mode65 ==> check message but don't make wave()
  double samfac=1.0;
  int nsendingsh=0;
  int mwave;
  t=t.toUpper();
  int i1=t.indexOf(" OOO");
  QByteArray s=t.toUpper().toLocal8Bit();
  ba2msg(s,message);
  gen65_(message,&mode65,&samfac,&nsendingsh,msgsent,iwave,&mwave,len1,len1);

  QPalette p(tx->palette());
  if(nsendingsh==1) {
    p.setColor(QPalette::Base,"#66ffff");
  } else if(nsendingsh==-1) {
    p.setColor(QPalette::Base,"#ffccff");
  } else {
    p.setColor(QPalette::Base,Qt::white);
  }
  tx->setPalette(p);
  int len=t.length();
  if(nsendingsh==-1) {
    len=qMin(len,13);
    if(i1>10) {
      tx->setText(t.mid(0,len).toUpper() + " OOO");
    } else {
      tx->setText(t.mid(0,len).toUpper());
    }
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
}

void MainWindow::on_dxCallEntry_textChanged(const QString &t) //dxCall changed
{
  m_hisCall=t.toUpper().trimmed();
  ui->dxCallEntry->setText(m_hisCall);
}

void MainWindow::on_dxGridEntry_textChanged(const QString &t) //dxGrid changed
{
  int n=t.length();
  if(n!=4 and n!=6) return;
  if(!t[0].isLetter() or !t[1].isLetter()) return;
  if(!t[2].isDigit() or !t[3].isDigit()) return;
  if(n==4) m_hisGrid=t.mid(0,2).toUpper() + t.mid(2,2);
  if(n==6) m_hisGrid=t.mid(0,2).toUpper() + t.mid(2,2) +
      t.mid(4,2).toLower();
  ui->dxGridEntry->setText(m_hisGrid);
}

void MainWindow::on_genStdMsgsPushButton_clicked()         //genStdMsgs button
{
  genStdMsgs("");
}

void MainWindow::on_logQSOButton_clicked()                 //Log QSO button
{
  int nMHz=144;
  QDateTime t = QDateTime::currentDateTimeUtc();
  QString logEntry=t.date().toString("yyyy-MMM-dd,") +
      t.time().toString("hh:mm,") + m_hisCall + "," + m_hisGrid + "," +
      QString::number(nMHz) + ",JT65B\n";
  QFile f("wsjt.log");
  if(!f.open(QFile::Append)) {
    msgBox("Cannot open file \"wsjt.log\".");
    return;
  }
  QTextStream out(&f);
  out << logEntry;
  f.close();
  m_worked[m_hisCall]=true;
}

/*
void MainWindow::on_actionErase_jtms3_rx_log_triggered()     //Erase Rx log
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file jtms3_rx.log ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    m_jtms3RxLog |= 2;                      // Rewind jtms3_rx.log
  }
}
*/

void MainWindow::on_actionErase_jtms3_tx_log_triggered()     //Erase Tx log
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file jtms3_tx.log ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QFile f("jtms3_tx.log");
    f.remove();
  }
}
