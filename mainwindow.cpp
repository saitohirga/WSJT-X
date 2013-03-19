//-------------------------------------------------------------- MainWindow
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "devsetup.h"
#include "plotter.h"
#include "about.h"
#include "widegraph.h"
#include "sleep.h"
#include "getfile.h"
#include <portaudio.h>

int itone[85];                        //Tx audio tones for 85 symbols
int rc;
wchar_t buffer[256];
bool btxok;                           //True if OK to transmit
bool btxMute;
double outputLatency;                 //Latency in seconds
//float c0[2*1800*1500];

WideGraph* g_pWideGraph = NULL;
QSharedMemory mem_jt9("mem_jt9");

QString rev="$Rev$";
QString Program_Title_Version="  WSJT-X   v0.7, r" + rev.mid(6,4) +
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
  ui->actionJT9_1->setActionGroup(modeGroup);
  ui->actionJT9_2->setActionGroup(modeGroup);
  ui->actionJT9_5->setActionGroup(modeGroup);
  ui->actionJT9_10->setActionGroup(modeGroup);
  ui->actionJT9_30->setActionGroup(modeGroup);

  QActionGroup* saveGroup = new QActionGroup(this);
  ui->actionNone->setActionGroup(saveGroup);
  ui->actionSave_synced->setActionGroup(saveGroup);
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
  connect(ui->decodedTextBrowser,SIGNAL(selectCallsign(bool,bool)),this,
          SLOT(doubleClickOnCall(bool,bool)));

  setWindowTitle(Program_Title_Version);
  connect(&soundInThread, SIGNAL(readyForFFT(int)),
             this, SLOT(dataSink(int)));
  connect(&soundInThread, SIGNAL(error(QString)), this,
          SLOT(showSoundInError(QString)));
  connect(&soundInThread, SIGNAL(status(QString)), this,
          SLOT(showStatusMessage(QString)));
  createStatusBar();

  connect(&proc_jt9, SIGNAL(readyReadStandardOutput()),
                    this, SLOT(readFromStdout()));

  connect(&proc_jt9, SIGNAL(error(QProcess::ProcessError)),
          this, SLOT(jt9_error()));

  connect(&proc_jt9, SIGNAL(readyReadStandardError()),
          this, SLOT(readFromStderr()));

  ui->tx5->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(ui->tx5, SIGNAL(customContextMenuRequested(const QPoint&)),
      this, SLOT(showMacros(const QPoint&)));

  QTimer *guiTimer = new QTimer(this);
  connect(guiTimer, SIGNAL(timeout()), this, SLOT(guiUpdate()));
  guiTimer->start(100);                            //Don't change the 100 ms!
  m_auto=false;
  m_waterfallAvg = 1;
  m_txFirst=false;
  btxMute=false;
  btxok=false;
  m_restart=false;
  m_transmitting=false;
  m_killAll=false;
  m_widebandDecode=false;
  m_ntx=1;
  m_myCall="K1JT";
  m_myGrid="FN20qi";
  m_appDir = QApplication::applicationDirPath();
  m_saveDir="/users/joe/wsjtx/install/save";
  m_txFreq=1500;
  m_setftx=0;
  m_loopall=false;
  m_startAnother=false;
  m_saveSynced=false;
  m_saveDecoded=false;
  m_saveAll=false;
  m_sec0=-1;
  m_palette="CuteSDR";
  m_RxLog=1;                     //Write Date and Time to RxLog
  m_nutc0=9999;
  m_NB=false;
  m_mode="JT9-1";
  m_TRperiod=60;
  m_inGain=0;
  m_dataAvailable=false;
  decodeBusy(false);

  ui->xThermo->setFillBrush(Qt::green);

#ifdef WIN32
  while(true) {
      int iret=killbyname("jt9.exe");
      if(iret == 603) break;
      if(iret != 0) msgBox("KillByName return code: " +
                           QString::number(iret));
  }
#endif
  if(!mem_jt9.attach()) {
    if (!mem_jt9.create(sizeof(jt9com_))) {
      msgBox("Unable to create shared memory segment.");
    }
  }
  char *to = (char*)mem_jt9.data();
  int size=sizeof(jt9com_);
  if(jt9com_.newdat==0) {
//    int noffset = 4*4*5760000 + 4*4*322*32768 + 4*4*32768;
//    to += noffset;
//    size -= noffset;
  }
  memset(to,0,size);         //Zero all decoding params in shared memory

  PaError paerr=Pa_Initialize();                    //Initialize Portaudio
  if(paerr!=paNoError) {
    msgBox("Unable to initialize PortAudio.");
  }
  readSettings();		             //Restore user's setup params
  QFile lockFile(m_appDir + "/.lock");     //Create .lock so jt9 will wait
  lockFile.open(QIODevice::ReadWrite);
  QFile quitFile(m_appDir + "/.lock");
  quitFile.remove();
  proc_jt9.start(QDir::toNativeSeparators('"' + m_appDir + '"' + "/jt9 -s"));

  m_pbdecoding_style1="QPushButton{background-color: cyan; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbmonitor_style="QPushButton{background-color: #00ff00; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  m_pbAutoOn_style="QPushButton{background-color: red; \
      border-style: outset; border-width: 1px; border-radius: 5px; \
      border-color: black; min-width: 5em; padding: 3px;}";
  genStdMsgs("-30");
  on_actionWide_Waterfall_triggered();                   //###
  g_pWideGraph->setTxFreq(m_txFreq);
  m_dialFreq=g_pWideGraph->dialFreq();

  if(m_mode=="JT9-1") on_actionJT9_1_triggered();
  if(m_mode=="JT9-2") on_actionJT9_2_triggered();
  if(m_mode=="JT9-5") on_actionJT9_5_triggered();
  if(m_mode=="JT9-10") on_actionJT9_10_triggered();
  if(m_mode=="JT9-30") on_actionJT9_30_triggered();
  future1 = new QFuture<void>;
  watcher1 = new QFutureWatcher<void>;
  connect(watcher1, SIGNAL(finished()),this,SLOT(diskDat()));

  future2 = new QFuture<void>;
  watcher2 = new QFutureWatcher<void>;
  connect(watcher2, SIGNAL(finished()),this,SLOT(diskWriteFinished()));

  soundInThread.setInputDevice(m_paInDevice);
  soundInThread.start(QThread::HighestPriority);
  soundOutThread.setOutputDevice(m_paOutDevice);
  soundOutThread.setTxFreq(m_txFreq);
  m_monitoring=!m_monitorStartOFF;           // Start with Monitoring ON/OFF
  soundInThread.setMonitoring(m_monitoring);
  m_diskData=false;
  g_pWideGraph->setTol(m_tol);
  static int ntol[] = {1,2,5,10,20,50,100,200,500};
  for (int i=0; i<10; i++) {
    if(ntol[i]==m_tol) ui->tolSpinBox->setValue(i);
  }

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

  if(ui->actionLinrad->isChecked()) on_actionLinrad_triggered();
  if(ui->actionCuteSDR->isChecked()) on_actionCuteSDR_triggered();
  if(ui->actionAFMHot->isChecked()) on_actionAFMHot_triggered();
  if(ui->actionBlue->isChecked()) on_actionBlue_triggered();

  if(m_pskReporter) {
    rc=ReporterInitialize(NULL,NULL);
    if(rc==0) {
      m_pskReporterInit=true;
    } else {
      m_pskReporterInit=false;
      rc=ReporterGetInformation(buffer,256);
      msgBox(QString::fromStdWString(buffer));
    }
  }
}                                          // End of MainWindow constructor

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
  QString inifile = m_appDir + "/wsjtx.ini";
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
  settings.setValue("SaveDir",m_saveDir);
  settings.setValue("SoundInIndex",m_nDevIn);
  settings.setValue("paInDevice",m_paInDevice);
  settings.setValue("SoundOutIndex",m_nDevOut);
  settings.setValue("paOutDevice",m_paOutDevice);
  settings.setValue("PaletteCuteSDR",ui->actionCuteSDR->isChecked());
  settings.setValue("PaletteLinrad",ui->actionLinrad->isChecked());
  settings.setValue("PaletteAFMHot",ui->actionAFMHot->isChecked());
  settings.setValue("PaletteBlue",ui->actionBlue->isChecked());
  settings.setValue("Mode",m_mode);
  settings.setValue("SaveNone",ui->actionNone->isChecked());
  settings.setValue("SaveSynced",ui->actionSave_synced->isChecked());
  settings.setValue("SaveDecoded",ui->actionSave_decoded->isChecked());
  settings.setValue("SaveAll",ui->actionSave_all->isChecked());
  settings.setValue("NDepth",m_ndepth);
  settings.setValue("KB8RQ",m_kb8rq);
  settings.setValue("MonitorOFF",m_monitorStartOFF);
  settings.setValue("NB",m_NB);
  settings.setValue("NBslider",m_NBslider);
  settings.setValue("TxFreq",m_txFreq);
  settings.setValue("Tol",m_tol);
  settings.setValue("InGain",m_inGain);
  settings.setValue("PSKReporter",m_pskReporter);
  settings.endGroup();
}

//---------------------------------------------------------- readSettings()
void MainWindow::readSettings()
{
  QString inifile = m_appDir + "/wsjtx.ini";
  QSettings settings(inifile, QSettings::IniFormat);
  settings.beginGroup("MainWindow");
  restoreGeometry(settings.value("geometry").toByteArray());
  ui->dxCallEntry->setText(settings.value("DXcall","").toString());
  ui->dxGridEntry->setText(settings.value("DXgrid","").toString());
  m_wideGraphGeom = settings.value("WideGraphGeom", \
                                   QRect(45,30,726,301)).toRect();
  m_path = settings.value("MRUdir", m_appDir + "/save").toString();
  m_txFirst = settings.value("TxFirst",false).toBool();
  ui->txFirstCheckBox->setChecked(m_txFirst);
  settings.endGroup();

  settings.beginGroup("Common");
  m_myCall=settings.value("MyCall","").toString();
  m_myGrid=settings.value("MyGrid","").toString();
  m_idInt=settings.value("IDint",0).toInt();
  m_pttPort=settings.value("PTTport",0).toInt();
  m_saveDir=settings.value("SaveDir",m_appDir + "/save").toString();
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
  m_mode=settings.value("Mode","JT9-1").toString();
  ui->actionNone->setChecked(settings.value("SaveNone",true).toBool());
  ui->actionSave_synced->setChecked(settings.value(
                                        "SaveSynced",false).toBool());
  ui->actionSave_decoded->setChecked(settings.value(
                                         "SaveDecoded",false).toBool());
  ui->actionSave_all->setChecked(settings.value("SaveAll",false).toBool());
  m_NB=settings.value("NB",false).toBool();
  ui->NBcheckBox->setChecked(m_NB);
  m_NBslider=settings.value("NBslider",40).toInt();
  ui->NBslider->setValue(m_NBslider);
  m_txFreq=settings.value("TxFreq",1500).toInt();
  ui->TxFreqSpinBox->setValue(m_txFreq);
  soundOutThread.setTxFreq(m_txFreq);
  m_saveSynced=ui->actionSave_synced->isChecked();
  m_saveDecoded=ui->actionSave_decoded->isChecked();
  m_saveAll=ui->actionSave_all->isChecked();
  m_ndepth=settings.value("NDepth",0).toInt();
  m_tol=settings.value("Tol",5).toInt();
  m_inGain=settings.value("InGain",0).toInt();
  ui->inGain->setValue(m_inGain);
  m_kb8rq=settings.value("KB8RQ",false).toBool();
  ui->actionF4_sets_Tx6->setChecked(m_kb8rq);
  m_monitorStartOFF=settings.value("MonitorOFF",false).toBool();
  ui->actionMonitor_OFF_at_startup->setChecked(m_monitorStartOFF);
  m_pskReporter=settings.value("PSKReporter",false).toBool();
  settings.endGroup();

  if(!ui->actionLinrad->isChecked() && !ui->actionCuteSDR->isChecked() &&
    !ui->actionAFMHot->isChecked() && !ui->actionBlue->isChecked()) {
    on_actionLinrad_triggered();
    ui->actionLinrad->setChecked(true);
  }
  if(m_ndepth==1) ui->actionQuickDecode->setChecked(true);
  if(m_ndepth==2) ui->actionMediumDecode->setChecked(true);
  if(m_ndepth==3) ui->actionDeepestDecode->setChecked(true);
  statusChanged();
}

//-------------------------------------------------------------- dataSink()
void MainWindow::dataSink(int k)
{
  static float s[NSMAX],red[NSMAX];
  static int ihsym=0;
  static int nzap=0;
  static int nb;
  static int trmin;
  static int npts8;
  static float px=0.0;
  static float df3;
  static uchar lstrong[1024];
  static float slimit;

  if(m_diskData) {
    jt9com_.ndiskdat=1;
  } else {
    jt9com_.ndiskdat=0;
  }

// Get power, spectrum, and ihsym
  nb=0;
  if(m_NB) nb=1;
  trmin=m_TRperiod/60;
  symspec_(&k, &trmin, &m_nsps, &m_inGain, &nb, &m_NBslider, &px, s, red,
           &df3, &ihsym, &nzap, &slimit, lstrong, &npts8);
  if(ihsym <=0) return;
  QString t;
  m_pctZap=nzap*100.0/m_nsps;
  t.sprintf(" Rx noise: %5.1f  %5.1f %% ",px,m_pctZap);
  lab3->setText(t);
  ui->xThermo->setValue((double)px);                    //Update thermometer
  if(m_monitoring || m_diskData) {
    g_pWideGraph->dataSink2(s,red,df3,ihsym,m_diskData,lstrong);
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
  dlg.m_nDevIn=m_nDevIn;
  dlg.m_nDevOut=m_nDevOut;
  dlg.m_pskReporter=m_pskReporter;

  dlg.initDlg();
  if(dlg.exec() == QDialog::Accepted) {
    m_myCall=dlg.m_myCall;
    m_myGrid=dlg.m_myGrid;
    m_idInt=dlg.m_idInt;
    m_pttPort=dlg.m_pttPort;
    m_saveDir=dlg.m_saveDir;
    m_nDevIn=dlg.m_nDevIn;
    m_paInDevice=dlg.m_paInDevice;
    m_nDevOut=dlg.m_nDevOut;
    m_paOutDevice=dlg.m_paOutDevice;
    if(dlg.m_pskReporter!=m_pskReporter) {
      if(dlg.m_pskReporter) {
        int rc=ReporterInitialize(NULL,NULL);
        if(rc==0) {
          m_pskReporterInit=true;
        } else {
          m_pskReporterInit=false;
          rc=ReporterGetInformation(buffer,256);
          msgBox(QString::fromStdWString(buffer));
        }
      } else {
        rc=ReporterUninitialize();
        m_pskReporterInit=false;
      }
    }
    m_pskReporter=dlg.m_pskReporter;

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
  int n;
  switch(e->key())
  {
  case Qt::Key_F3:
    btxMute=!btxMute;
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
    n=11;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    bumpFqso(n);
    break;
  case Qt::Key_F12:
    n=12;
    if(e->modifiers() & Qt::ControlModifier) n+=100;
    bumpFqso(n);
    break;
  case Qt::Key_G:
    if(e->modifiers() & Qt::AltModifier) {
      genStdMsgs("-30");
      break;
    }
  case Qt::Key_L:
    if(e->modifiers() & Qt::ControlModifier) {
      lookup();
      genStdMsgs("-30");
      break;
    }
  }
}

void MainWindow::bumpFqso(int n)                                 //bumpFqso()
{
  int i;
  bool ctrl = (n>=100);
  n=n%100;
  i=g_pWideGraph->QSOfreq();
  if(n==11) i--;
  if(n==12) i++;
  g_pWideGraph->setQSOfreq(i);
  if(!ctrl) {
    ui->TxFreqSpinBox->setValue(i);
    g_pWideGraph->setTxFreq(i);
  }
}

void MainWindow::dialFreqChanged2(double f)
{
  m_dialFreq=f;
  statusChanged();
}

void MainWindow::statusChanged()
{
  QFile f("wsjtx_status.txt");
  if(!f.open(QFile::WriteOnly | QIODevice::Text)) {
    msgBox("Cannot open file \"wsjtx_status.txt\".");
    return;
  }
  QTextStream out(&f);
  out << m_dialFreq << ";" << m_mode << ";" << m_hisCall << endl;
  f.close();
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
  lab2->setMinimumSize(QSize(90,18));
  lab2->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab2);

  lab3 = new QLabel("");
  lab3->setAlignment(Qt::AlignHCenter);
  lab3->setMinimumSize(QSize(80,18));
  lab3->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab3);

  lab4 = new QLabel("");
  lab4->setAlignment(Qt::AlignHCenter);
  lab4->setMinimumSize(QSize(50,18));
  lab4->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab4);

  lab5 = new QLabel("");
  lab5->setAlignment(Qt::AlignHCenter);
  lab5->setMinimumSize(QSize(100,18));
  lab5->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(lab5);
}

void MainWindow::on_tolSpinBox_valueChanged(int i)             //tolSpinBox
{
  static int ntol[] = {1,2,5,10,20,50,100,200,500};
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
  mem_jt9.detach();
  QFile quitFile(m_appDir + "/.quit");
  quitFile.open(QIODevice::ReadWrite);
  QFile lockFile(m_appDir + "/.lock");
  lockFile.remove();                      // Allow jt9 to terminate
  bool b=proc_jt9.waitForFinished(1000);
  if(!b) proc_jt9.kill();
  quitFile.remove();
  qApp->exit(0);                                      // Exit the event loop
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
  "http://www.physics.princeton.edu/pulsar/K1JT/WSJT-X_Users_Guide.pdf",
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
            SLOT(bumpFqso(int)));
    connect(g_pWideGraph, SIGNAL(dialFreqChanged(double)),this,
            SLOT(dialFreqChanged2(double)));  }
  g_pWideGraph->show();
}

void MainWindow::on_actionOpen_triggered()                     //Open File
{
  m_monitoring=false;
  soundInThread.setMonitoring(m_monitoring);
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
    dataSink(k);
    if(n%10 == 1 or n == m_hsymStop)
        qApp->processEvents();                   //Keep GUI responsive
  }
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

void MainWindow::on_actionF4_sets_Tx6_triggered()                //F4 sets Tx6
{
  m_kb8rq = !m_kb8rq;
}

void MainWindow::on_actionNo_shorthands_if_Tx1_triggered()
{
  stub();
}

void MainWindow::on_actionNone_triggered()                    //Save None
{
  m_saveSynced=false;
  m_saveDecoded=false;
  m_saveAll=false;
  ui->actionNone->setChecked(true);
}

void MainWindow::on_actionSave_synced_triggered()
{
  m_saveSynced=true;
  m_saveDecoded=false;
  m_saveAll=false;
  ui->actionSave_synced->setChecked(true);
}

void MainWindow::on_actionSave_decoded_triggered()
{
  m_saveSynced=false;
  m_saveDecoded=true;
  m_saveAll=false;
  ui->actionSave_decoded->setChecked(true);
}

void MainWindow::on_actionSave_all_triggered()                //Save All
{
  m_saveSynced=false;
  m_saveDecoded=false;
  m_saveAll=true;
  ui->actionSave_all->setChecked(true);
}

void MainWindow::on_actionKeyboard_shortcuts_triggered()
{
  stub();                                 //Display list of keyboard shortcuts
}

void MainWindow::on_actionSpecial_mouse_commands_triggered()
{
  stub();                                    //Display list of mouse commands
}
void MainWindow::on_actionAvailable_suffixes_and_add_on_prefixes_triggered()
{
  stub();                                    //Display list of Add-On pfx/sfx
}

void MainWindow::on_DecodeButton_clicked()                    //Decode request
{
  if(!m_decoderBusy) {
    jt9com_.newdat=0;
    jt9com_.nagain=1;
    decode();
  }
}

void MainWindow::freezeDecode(int n)                          //freezeDecode()
{
  if(n==1) {
    bumpFqso(0);
  } else {
    static int ntol[] = {1,2,5,10,20,50,100,200,500};
    if(!m_decoderBusy) {
      jt9com_.newdat=0;
      jt9com_.nagain=1;
      int i;
      if(m_mode=="JT9-1") i=4;
      if(m_mode=="JT9-2") i=4;
      if(m_mode=="JT9-5") i=3;
      if(m_mode=="JT9-10") i=2;
      if(m_mode=="JT9-30") i=1;
      m_tol=ntol[i];
      g_pWideGraph->setTol(m_tol);
      ui->tolSpinBox->setValue(i);
      decode();
    }
  }
}

void MainWindow::decode()                                       //decode()
{
  ui->DecodeButton->setStyleSheet(m_pbdecoding_style1);
  if(jt9com_.nagain==0 && (!m_diskData)) {
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int imin=ms/60000;
    int ihr=imin/60;
    imin=imin % 60;
    imin=imin - (imin % (m_TRperiod/60));
    jt9com_.nutc=100*ihr + imin;
  }

  jt9com_.nfqso=g_pWideGraph->QSOfreq();
  jt9com_.ndepth=m_ndepth;
  jt9com_.ndiskdat=0;
  if(m_diskData) jt9com_.ndiskdat=1;
  jt9com_.nfa=1000;                         //### temporary ###
  jt9com_.nfb=2000;

  jt9com_.ntol=m_tol;
  if(jt9com_.nutc < m_nutc0) m_RxLog |= 1;  //Date and Time to all65.txt
  m_nutc0=jt9com_.nutc;
  jt9com_.nrxlog=m_RxLog;
  jt9com_.nfsample=12000;
  jt9com_.ntrperiod=m_TRperiod;
  m_nsave=0;
  if(m_saveSynced) m_nsave=1;
  if(m_saveDecoded) m_nsave=2;
  jt9com_.nsave=m_nsave;
  strncpy(jt9com_.datetime, m_dateTime.toAscii(), 20);

  //newdat=1  ==> this is new data, must do the big FFT
  //nagain=1  ==> decode only at fQSO +/- Tol

  char *to = (char*)mem_jt9.data();
  char *from = (char*) jt9com_.ss;
  int size=sizeof(jt9com_);
  if(jt9com_.newdat==0) {
    int noffset = 4*184*22000 + 4*22000 + 4*2*1800*1500 + 2*1800*12000;
    to += noffset;
    from += noffset;
    size -= noffset;
  }
  memcpy(to, from, qMin(mem_jt9.size(), size));

  QFile lockFile(m_appDir + "/.lock");       // Allow jt9 to start
  lockFile.remove();
  decodeBusy(true);
}

void MainWindow::jt9_error()                                     //jt9_error
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
  while(proc_jt9.canReadLine()) {
    QByteArray t=proc_jt9.readLine();
    if(t.indexOf("<DecodeFinished>") >= 0) {
      m_bsynced = (t.mid(19,1).toInt()==1);
      m_bdecoded = (t.mid(23,1).toInt()==1);
      bool keepFile=m_saveAll or (m_saveSynced and m_bsynced) or
          (m_saveDecoded and m_bdecoded);
      if(!keepFile) {
        QFile savedFile(m_fname);
        savedFile.remove();
      }
      jt9com_.nagain=0;
      jt9com_.ndiskdat=0;
      QFile lockFile(m_appDir + "/.lock");
      lockFile.open(QIODevice::ReadWrite);
      ui->DecodeButton->setStyleSheet("");
      decodeBusy(false);
      m_RxLog=0;
      m_startAnother=m_loopall;
      return;
    } else {

      QFile f("ALL.TXT");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      if(m_RxLog & 1) {
        out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
            << endl;
        m_RxLog=0;
      }
      int n=t.length();
      out << t.mid(0,n-2) << endl;
      f.close();

      QString bg="white";
      if(t.indexOf(" CQ ")>0) bg="#66ff66";                //Light green
      if(t.indexOf(" "+m_myCall+" ")>0) bg="#ff6666";      //Light red
      ui->decodedTextBrowser->setTextBackgroundColor(bg);
      t=t.mid(0,n-2) + "                                                  ";
      ui->decodedTextBrowser->append(t);
      QString msg=t.mid(34,22);
      bool b=stdmsg_(msg.toAscii().constData());
      QStringList w=msg.split(" ",QString::SkipEmptyParts);
      if(b and w[0]==m_myCall) {
        QString tt=w[2];
        int i1;
        bool ok;
        i1=tt.toInt(&ok);
        if(ok and i1>=-50 and i1<50) {
          m_rptRcvd=tt;
        } else {
          if(tt.mid(0,1)=="R") {
            i1=tt.mid(1).toInt(&ok);
            if(ok and i1>=-50 and i1<50) {
              m_rptRcvd=tt.mid(1);
            }
          }
        }
      }

      if(m_pskReporterInit and b and !m_diskData) {
//      if(m_pskReporterInit and b) {
        int i1=msg.indexOf(" ");
        QString c2=msg.mid(i1+1);
        int i2=c2.indexOf(" ");
        QString g2=c2.mid(i2+1,4);
        c2=c2.mid(0,i2);
        QString remote="call," + c2 + ",";
        if(gridOK(g2)) remote += "gridsquare," + g2 + ",";
        int nHz=t.mid(22,4).toInt();
        uint nfreq=1000000.0*g_pWideGraph->dialFreq() + nHz + 0.5;
        remote += "freq," + QString::number(nfreq);
        int nsnr=t.mid(10,3).toInt();
        remote += ",mode,JT9,snr," + QString::number(nsnr) + ",,";

        wchar_t tremote[256];
        remote.toWCharArray(tremote);

        QString local="station_callsign," + m_myCall + "," +
            "my_gridsquare," + m_myGrid + "," +
            "programid,WSJT-X,programversion," + rev.mid(6,4) + ",,";

        wchar_t tlocal[256];
        local.toWCharArray(tlocal);

        int flags=REPORTER_SOURCE_AUTOMATIC;
        rc=ReporterSeenCallsign(tremote,tlocal,flags);
        if(rc!=0) {
          ReporterGetInformation(buffer,256);
          qDebug() << "C:" << rc << QString::fromStdWString(buffer);
        }
        rc=ReporterTickle();
        if(rc!=0) {
          rc=ReporterGetInformation(buffer,256);
          qDebug() << "D:" << QString::fromStdWString(buffer);
        }
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
  static char message[29];
  static char msgsent[29];
  static int nsendingsh=0;
  int khsym=0;

  double tx1=0.0;
//  double tx2=m_TRperiod;
  double tx2=1.0 + 85.0*m_nsps/12000.0;

  if(!m_txFirst) {
    tx1 += m_TRperiod;
    tx2 += m_TRperiod;
  }
  qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
  int nsec=ms/1000;
  double tsec=0.001*ms;
  double t2p=fmod(tsec,2*m_TRperiod);
  bool bTxTime = (t2p >= tx1) && (t2p < tx2);

  if(m_auto) {

    QFile f("txboth");
    if(f.exists() and fmod(tsec,m_TRperiod)<1.0 + 85.0*m_nsps/12000.0)
      bTxTime=true;

    if(bTxTime and iptt==0 and !btxMute) {
      int itx=1;
      int ierr = ptt(m_pttPort,itx,&iptt);       // Raise PTT
      /*
      if(ierr<0) {
        on_stopTxButton_clicked();
        char s[18];
        sprintf(s,"PTT Error %d",ierr);
        msgBox(s);
      }
      */
      if(!soundOutThread.isRunning()) {
        QString t=ui->tx6->text();
        double snr=t.mid(1,5).toDouble();
        if(snr>0.0 or snr < -50.0) snr=99.0;
        soundOutThread.setTxSNR(snr);
        soundOutThread.start(QThread::HighPriority);
      }
    }
    if(!bTxTime || btxMute) {
      btxok=false;
    }
  }

// Calculate Tx tones when needed
  if((iptt==1 && iptt0==0) || m_restart) {
    QByteArray ba;
    if(m_ntx == 1) ba=ui->tx1->text().toLocal8Bit();
    if(m_ntx == 2) ba=ui->tx2->text().toLocal8Bit();
    if(m_ntx == 3) ba=ui->tx3->text().toLocal8Bit();
    if(m_ntx == 4) ba=ui->tx4->text().toLocal8Bit();
    if(m_ntx == 5) ba=ui->tx5->text().toLocal8Bit();
    if(m_ntx == 6) ba=ui->tx6->text().toLocal8Bit();

    ba2msg(ba,message);
//    ba2msg(ba,msgsent);
    int len1=22;
    int ichk=0,itext=0;
    genjt9_(message,&ichk,msgsent,itone,&itext,len1,len1);
    msgsent[22]=0;
    lab5->setText("Last Tx:  " + QString::fromAscii(msgsent));
    QString t=QString::fromAscii(msgsent);
    if(m_restart) {
      QFile f("ALL.TXT");
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      out << QDateTime::currentDateTimeUtc().toString("hhmm")
          << "  Transmitted:  " << t << endl;
      f.close();
    }
    QStringList w=t.split(" ",QString::SkipEmptyParts);
    QString t2=QDateTime::currentDateTimeUtc().toString("hhmm");
    if(itext==0 and w[1]==m_myCall) {
      t=w[2];
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
    if(itext==1 or w[2]=="73") m_qsoStop=t2;
    m_restart=false;
  }

// If PTT was just raised, start a countdown for raising TxOK:
  if(iptt==1 && iptt0==0) nc1=-9;    // TxDelay = 0.8 s
  if(nc1 <= 0) nc1++;
  if(nc1 == 0) {
    ui->xThermo->setValue(0.0);   //Set Thermo to zero
    m_monitoring=false;
    soundInThread.setMonitoring(false);
    btxok=true;
    m_transmitting=true;

    QFile f("ALL.TXT");
    f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
    QTextStream out(&f);
    out << QDateTime::currentDateTimeUtc().toString("hhmm")
        << "  Transmitting:  " << QString::fromAscii(msgsent) << endl;
    f.close();
  }

// If btxok was just lowered, start a countdown for lowering PTT
  if(!btxok && btxok0 && iptt==1) nc0=-11;  //RxDelay = 1.0 s
  if(nc0 <= 0) {
    nc0++;
  }
  if(nc0 == 0) {
    int itx=0;
    int ierr=ptt(m_pttPort,itx,&iptt);       // Lower PTT
    /*
    if(ierr<0) {
      char s[18];
      sprintf(s,"PTT Error %d",ierr);
      msgBox(s);
    }
    */
    if(!btxMute) soundOutThread.quitExecution=true;
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

  lab2->setText("QSO Freq:  " + QString::number(g_pWideGraph->QSOfreq()));

  if(m_startAnother) {
    m_startAnother=false;
    on_actionOpen_next_in_directory_triggered();
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
      char s[37];
      sprintf(s,"Tx: %s",msgsent);
      lab1->setText(s);
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
      ui->xThermo->setValue(0.0);
    }
    m_hsym0=khsym;
    m_sec0=nsec;

/*
    if(m_myCall=="K1JT") {
      char s[20];
      double t1=1.0;
//Better: use signals from sound threads?
      if(soundInThread.isRunning()) t1=soundInThread.samFacIn();
      double t2=1.0;
      if(soundOutThread.isRunning()) t2=soundOutThread.samFacOut();
      sprintf(s,"%6.4f  %6.4f",t1,t2);
      lab5->setText(s);
    }
*/

  }
  iptt0=iptt;
  btxok0=btxok;
}

void MainWindow::ba2msg(QByteArray ba, char message[])             //ba2msg()
{
  bool eom;
  eom=false;
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

void MainWindow::doubleClickOnCall(bool shift, bool ctrl)
{
  QTextCursor cursor=ui->decodedTextBrowser->textCursor();
  cursor.select(QTextCursor::LineUnderCursor);
  int i2=cursor.position();
  QString t = ui->decodedTextBrowser->toPlainText();   //Full contents
  QString t1 = t.mid(0,i2);              //contents up to \n on selected line
  int i1=t1.lastIndexOf("\n") + 1;       //points to first char of line
  QString t2 = t1.mid(i1,i2-i1);         //selected line
  int i4=t.mid(i1).length();
  if(i4>60) i4=60;
  QString t3=t.mid(i1,i4);
  QStringList t4=t3.split(" ",QString::SkipEmptyParts);
  if(t4.length() <7) return;           //Skip the rest if no decoded text
  QString firstcall=t4.at(6);
  //Don't change freqs if Shift key down or a station is calling me.
  if(!shift and firstcall!=m_myCall) {
    int nfreq=int(t4.at(4).toFloat());
    ui->TxFreqSpinBox->setValue(nfreq);
    g_pWideGraph->setQSOfreq(nfreq);
  }
  QString hiscall=t4.at(7);
  QString hisgrid="";
  if(t4.length()>=9) hisgrid=t4.at(8);
  ui->dxCallEntry->setText(hiscall);
  lookup();
  if(ui->dxGridEntry->text()=="" and gridOK(hisgrid)) ui->dxGridEntry->setText(hisgrid);
  int n = 60*t2.mid(0,2).toInt() + t2.mid(2,2).toInt();
  int nmod=n%(m_TRperiod/30);
  m_txFirst=(nmod!=0);
  ui->txFirstCheckBox->setChecked(m_txFirst);
  QString rpt=t4.at(2);
  if(rpt.indexOf("  ")==0) rpt="+" + rpt.mid(2,2);
  if(rpt.indexOf(" -")==0) rpt=rpt.mid(1,2);
  if(rpt.indexOf(" ")==0) rpt="+" + rpt.mid(1,2);
  if(rpt.toInt()<-50) rpt="-50";
  if(rpt.toInt()>49) rpt="+49";
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
  QString hc=hiscall;
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
  int jtone[85];

  t=t.toUpper();
  QByteArray s=t.toUpper().toLocal8Bit();
  ba2msg(s,message);
  int ichk=1,itext=0;
  genjt9_(message,&ichk,msgsent,itone,&itext,len1,len1);
  msgsent[22]=0;
  bool text=false;
  if(itext!=0) text=true;
  QString t1;
  t1.fromAscii(msgsent);
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
  double snr=t.mid(1,5).toDouble();
  if(snr>0.0 or snr < -50.0) snr=99.0;
  soundOutThread.setTxSNR(snr);
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
  genStdMsgs("-30");
}

void MainWindow::on_logQSOButton_clicked()                 //Log QSO button
{
  double dialFreq=g_pWideGraph->dialFreq();
  QDateTime t = QDateTime::currentDateTimeUtc();
  QString date=t.toString("yyyyMMdd");
  QFile f("wsjtx.log");
  if(!f.open(QIODevice::Text | QIODevice::Append)) {
    msgBox("Cannot open file \"wsjtx.log\".");
  } else {
    QString logEntry=t.date().toString("yyyy-MMM-dd,") +
        t.time().toString("hh:mm,") + m_hisCall + "," + m_hisGrid + "," +
        QString::number(dialFreq) + "," + m_mode + "," +
        m_rptSent + "," + m_rptRcvd;
    QTextStream out(&f);
//  out << logEntry << "\r\n";
    out << logEntry << endl;
    f.close();
  }

  QFile f2("wsjtx_log.adi");
  if(!f2.open(QIODevice::Text | QIODevice::Append)) {
    msgBox("Cannot open file \"wsjtx_log.adi\".");
  } else {

    QTextStream out(&f2);
    if(f2.size()==0) out << "WSJT-X ADIF Export<eoh>" << endl;

    if(m_qsoStop=="") m_qsoStop=m_qsoStart;
    if(m_qsoStart=="") m_qsoStart=m_qsoStop;

    QString t;
    t="<call:" + QString::number(m_hisCall.length()) + ">" + m_hisCall;
    t+=" <gridsquare:" + QString::number(m_hisGrid.length()) + ">" + m_hisGrid;
    t+=" <mode:" + QString::number(m_mode.length()) + ">" + m_mode;
    t+=" <rst_sent:" + QString::number(m_rptSent.length()) + ">" + m_rptSent;
    t+=" <rst_rcvd:" + QString::number(m_rptRcvd.length()) + ">" + m_rptRcvd;
    t+=" <qso_date:8>" + date;
    t+=" <time_on:4>" + m_qsoStart;
    t+=" <time_off:4>" + m_qsoStop;
    t+=" <station_callsign:" + QString::number(m_myCall.length()) + ">" + m_myCall;
    t+=" <my_gridsquare:" + QString::number(m_myGrid.length()) + ">" + m_myGrid;
    t+=" <eor>";
    out << t << endl;
    f2.close();
  }

  m_rptSent="";
  m_rptRcvd="";
}

void MainWindow::on_actionJT9_1_triggered()
{
  m_mode="JT9-1";
  statusChanged();
  m_TRperiod=60;
  m_nsps=6912;
  m_hsymStop=181;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab4->setStyleSheet("QLabel{background-color: #ff6ec7}");
  lab4->setText(m_mode);
  ui->actionJT9_1->setChecked(true);
}

void MainWindow::on_actionJT9_2_triggered()
{
  m_mode="JT9-2";
  statusChanged();
  m_TRperiod=120;
  m_nsps=15360;
  m_hsymStop=178;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab4->setStyleSheet("QLabel{background-color: #ffff00}");
  lab4->setText(m_mode);
  ui->actionJT9_2->setChecked(true);
}

void MainWindow::on_actionJT9_5_triggered()
{
  m_mode="JT9-5";
  statusChanged();
  m_TRperiod=300;
  m_nsps=40960;
  m_hsymStop=172;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab4->setStyleSheet("QLabel{background-color: #ffa500}");
  lab4->setText(m_mode);
  ui->actionJT9_5->setChecked(true);
}

void MainWindow::on_actionJT9_10_triggered()
{
  m_mode="JT9-10";
  statusChanged();
  m_TRperiod=600;
  m_nsps=82944;
  m_hsymStop=171;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab4->setStyleSheet("QLabel{background-color: #7fff00}");
  lab4->setText(m_mode);
  ui->actionJT9_10->setChecked(true);
}

void MainWindow::on_actionJT9_30_triggered()
{
  m_mode="JT9-30";
  statusChanged();
  m_TRperiod=1800;
  m_nsps=252000;
  m_hsymStop=167;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab4->setStyleSheet("QLabel{background-color: #97ffff}");
  lab4->setText(m_mode);
  ui->actionJT9_30->setChecked(true);
}

void MainWindow::on_NBcheckBox_toggled(bool checked)
{
  m_NB=checked;
  ui->NBslider->setEnabled(m_NB);
}

void MainWindow::on_NBslider_valueChanged(int n)
{
  m_NBslider=n;
}

void MainWindow::on_TxFreqSpinBox_valueChanged(int n)
{
  m_txFreq=n;
  if(g_pWideGraph!=NULL) g_pWideGraph->setTxFreq(n);
  soundOutThread.setTxFreq(n);
}

void MainWindow::on_pbTxFreq_clicked()
{
  int ntx=g_pWideGraph->QSOfreq();
  m_txFreq=ntx;
  ui->TxFreqSpinBox->setValue(ntx);
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
  QPoint globalPos = ui->tx5->mapToGlobal(pos);
  QMenu popupMenu;
  QAction* popup1 = new QAction("5W DIP 73 GL",ui->tx5);
  QAction* popup2 = new QAction("TNX 73 GL",ui->tx5);
  popupMenu.addAction(popup1);
  popupMenu.addAction(popup2);
  connect(popup1,SIGNAL(triggered()), this, SLOT(onPopup1()));
  connect(popup2,SIGNAL(triggered()), this, SLOT(onPopup2()));
  popupMenu.exec(globalPos);
}

void MainWindow::onPopup1()
{
  ui->tx5->setText("5W DIP 73 GL");
}

void MainWindow::onPopup2()
{
  ui->tx5->setText("TNX 73 GL");
}

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
