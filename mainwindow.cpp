//--------------------------------------------------------------- MainWindow
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "devsetup.h"
#include "plotter.h"
#include "about.h"
#include "widegraph.h"
#include "sleep.h"
#include <portaudio.h>

short int iwave[30*48000];            //Wave file for Tx audio
int nwave;                            //Length of Tx waveform
bool btxok;                           //True if OK to transmit
double outputLatency;                 //Latency in seconds
qint16 id[30*48000];

WideGraph* g_pWideGraph = NULL;

QString rev="$Rev$";
QString Program_Title_Version="  WSJT-X   v0.1, r" + rev.mid(6,4) +
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
  ui->actionJT8_1->setActionGroup(modeGroup);
  ui->actionJT8_2->setActionGroup(modeGroup);
  ui->actionJT8_5->setActionGroup(modeGroup);
  ui->actionJT8_10->setActionGroup(modeGroup);
  ui->actionJT8_30->setActionGroup(modeGroup);

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
  m_saveDir="/users/joe/wsjtx/install/save";
  m_txFreq=125;
  m_setftx=0;
  m_loopall=false;
  m_startAnother=false;
  m_saveAll=false;
  m_sec0=-1;
  m_palette="CuteSDR";
  m_RxLog=1;                     //Write Date and Time to RxLog
  m_nutc0=9999;
  m_NB=false;
  m_mode="JT8-1";
  m_TRperiod=60;

  ui->xThermo->setFillBrush(Qt::green);

  PaError paerr=Pa_Initialize();                    //Initialize Portaudio
  if(paerr!=paNoError) {
    msgBox("Unable to initialize PortAudio.");
  }
  readSettings();		             //Restore user's setup params
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
  if(m_mode=="JT8-1") on_actionJT8_1_triggered();
  if(m_mode=="JT8-2") on_actionJT8_2_triggered();
  if(m_mode=="JT8-5") on_actionJT8_5_triggered();
  if(m_mode=="JT8-10") on_actionJT8_10_triggered();
  if(m_mode=="JT8-30") on_actionJT8_30_triggered();

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

  m_monitoring=false;                           // Start with Monitoring OFF
  soundInThread.setMonitoring(m_monitoring);
  m_diskData=false;
  m_tol=500;
  g_pWideGraph->setTol(m_tol);

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
  }
  f.close();

  if(ui->actionLinrad->isChecked()) on_actionLinrad_triggered();
  if(ui->actionCuteSDR->isChecked()) on_actionCuteSDR_triggered();
  if(ui->actionAFMHot->isChecked()) on_actionAFMHot_triggered();
  if(ui->actionBlue->isChecked()) on_actionBlue_triggered();

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
  settings.setValue("DXCCpfx",m_dxccPfx);
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
  settings.setValue("SaveAll",ui->actionSave_all->isChecked());
  settings.setValue("NDepth",m_ndepth);
  settings.setValue("KB8RQ",m_kb8rq);
  settings.setValue("NB",m_NB);
  settings.setValue("NBslider",m_NBslider);
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
  m_dxccPfx=settings.value("DXCCpfx","").toString();
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
  m_mode=settings.value("Mode","JT8-1").toString();
  ui->actionNone->setChecked(settings.value("SaveNone",true).toBool());
  ui->actionSave_all->setChecked(settings.value("SaveAll",false).toBool());
  m_NB=settings.value("NB",false).toBool();
  ui->NBcheckBox->setChecked(m_NB);
  m_NBslider=settings.value("NBslider",40).toInt();
  ui->NBslider->setValue(m_NBslider);
  m_saveAll=ui->actionSave_all->isChecked();
  m_ndepth=settings.value("NDepth",0).toInt();
  ui->actionF4_sets_Tx6->setChecked(m_kb8rq);
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
  static float s[NSMAX],splot[NSMAX];
  static int n=0;
  static int ihsym=0;
  static int nzap=0;
  static int ntr0=0;
  static int nkhz;
  static int ndiskdat;
  static int nadj=0;
  static int nb;
  static float px=0.0;
  static uchar lstrong[1024];
  static float slimit;


  if(m_diskData) {
    ndiskdat=1;
    jt8com_.ndiskdat=1;
  } else {
    ndiskdat=0;
    jt8com_.ndiskdat=0;
  }
// Get power, spectrum, nkhz, and ihsym
  nb=0;
  if(m_NB) nb=1;
  symspecx_(&k, & m_nsps, &ndiskdat, &nb, &m_NBslider, &px, s,
            &nkhz, &ihsym, &nzap, &slimit, lstrong);
  if(ihsym <=0) return;
  QString t;
  m_pctZap=nzap/178.3;
  t.sprintf(" Rx noise: %5.1f  %5.1f %% ",px,m_pctZap);
  lab4->setText(t);
  ui->xThermo->setValue((double)px);   //Update the thermometer
  if(m_monitoring || m_diskData) {
    g_pWideGraph->dataSink2(s,nkhz,ihsym,m_diskData,lstrong);
  }

  //Average over specified number of spectra
  if (n==0) {
    for (int i=0; i<NSMAX; i++)
      splot[i]=s[i];
  } else {
    for (int i=0; i<NSMAX; i++)
      splot[i] += s[i];
  }
  n++;

  if (n>=m_waterfallAvg) {
    for (int i=0; i<NSMAX; i++) {
        splot[i] /= n;                           //Normalize the average
    }

// Time according to this computer
    qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
    int ntr = (ms/1000) % m_TRperiod;
    if((m_diskData && ihsym <= m_waterfallAvg) || (!m_diskData && ntr<ntr0)) {
      for (int i=0; i<NSMAX; i++) {
        splot[i] = 1.e30;
      }
    }
    ntr0=ntr;
    n=0;
  }
  if(ihsym == 179) {
    jt8com_.newdat=1;
    jt8com_.nagain=0;
    QDateTime t = QDateTime::currentDateTimeUtc();
    m_dateTime=t.toString("yyyy-MMM-dd hh:mm");
    decode();                                           //Start the decoder
    if(m_saveAll and !m_diskData) {
      QString fname=m_saveDir + "/" + t.date().toString("yyMMdd") + "_" +
          t.time().toString("hhmm") + ".wav";
      *future2 = QtConcurrent::run(savewav, fname, m_TRperiod);
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
            SLOT(bumpDF(int)));
  }
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
    int dbDgrd=0;
    *future1 = QtConcurrent::run(getfile, fname, m_TRperiod);
    watcher1->setFuture(*future1);
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
      int dbDgrd=0;
      if(m_myCall=="K1JT" and m_idInt<0) dbDgrd=m_idInt;
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
  int kstep=m_nsps/2;
  m_diskData=true;

  for(int n=1; n<=184; n++) {              // Do the half-symbol FFTs
    int k=(n+1)*kstep;
    dataSink(k);
    if(n%10 == 0) qApp->processEvents();   //Keep the GUI responsive
  }
}

void MainWindow::diskWriteFinished()                       //diskWriteFinished
{
  qDebug() << "diskWriteFinished";
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
  m_RxLog |= 8;
  on_DecodeButton_clicked();
}

void MainWindow::on_actionF4_sets_Tx6_triggered()                //F4 sets Tx6
{
  m_kb8rq = !m_kb8rq;
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

void MainWindow::on_actionSave_all_triggered()                //Save All
{
  m_saveAll=true;
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

}

void MainWindow::freezeDecode(int n)                          //freezeDecode()
{

}

void MainWindow::decode()                                       //decode()
{

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
  static char msgsent[29];
  static int nsendingsh=0;
  int khsym=0;

  double tx1=0.0;
  double tx2=m_TRperiod;

  if(!m_txFirst) {
    tx1 += m_TRperiod;
    tx2 += m_TRperiod;
  }
  qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
  int nsec=ms/1000;
  double tsec=0.001*ms;
  double t2p=fmod(tsec,2*m_TRperiod);
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
    char message[29];
    QByteArray ba;
    if(m_ntx == 1) ba=ui->tx1->text().toLocal8Bit();
    if(m_ntx == 2) ba=ui->tx2->text().toLocal8Bit();
    if(m_ntx == 3) ba=ui->tx3->text().toLocal8Bit();
    if(m_ntx == 4) ba=ui->tx4->text().toLocal8Bit();
    if(m_ntx == 5) ba=ui->tx5->text().toLocal8Bit();
    if(m_ntx == 6) ba=ui->tx6->text().toLocal8Bit();

    ba2msg(ba,message);
    ba2msg(ba,msgsent);
    int len1=28;
//    genjt8_(message,iwave,&nwave,len1);
    if(m_restart) {
      QFile f("wsjtx_tx.log");
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

    QFile f("wsjtx_tx.log");
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
      lab1->setText("Receiving ");
    } else if (!m_diskData) {
      lab1->setStyleSheet("");
      lab1->setText("");
    }

    QDateTime t = QDateTime::currentDateTimeUtc();
    m_setftx=0;
    QString utc = " " + t.time().toString() + " ";
    ui->labUTC->setText(utc);
    if(!m_monitoring and !m_diskData) {
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
  for(int i=0;i<28; i++) {
    if((int)ba[i] == 0) eom=true;
    if(eom) {
      message[i]=32;
    } else {
      message[i]=ba[i];
    }
  }
  message[28]=0;
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

void MainWindow::selectCall2(bool ctrl)                          //selectCall2
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
  rpt="-30";
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
//  gen65_(message,&mode65,&samfac,&nsendingsh,msgsent,iwave,&mwave,len1,len1);
  nsendingsh=0;
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
  genStdMsgs("-30");
}

void MainWindow::on_logQSOButton_clicked()                 //Log QSO button
{
  int nMHz=144;
  QDateTime t = QDateTime::currentDateTimeUtc();
  QString logEntry=t.date().toString("yyyy-MMM-dd,") +
      t.time().toString("hh:mm,") + m_hisCall + "," + m_hisGrid + "," +
      QString::number(nMHz) + ",JTMSK\n";
  QFile f("wsjt.log");
  if(!f.open(QFile::Append)) {
    msgBox("Cannot open file \"wsjt.log\".");
    return;
  }
  QTextStream out(&f);
  out << logEntry;
  f.close();
}

/*
void MainWindow::on_actionErase_wsjtx_rx_log_triggered()     //Erase Rx log
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file wsjtx_rx.log ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    m_RxLog |= 2;                      // Rewind wsjtx_rx.log
  }
}
*/

void MainWindow::on_actionErase_wsjtx_tx_log_triggered()     //Erase Tx log
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
      "Are you sure you want to erase file wsjtx_tx.log ?",
       QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QFile f("wsjtx_tx.log");
    f.remove();
  }
}

void MainWindow::on_actionJT8_1_triggered()
{
  m_mode="JT8-1";
  m_TRperiod=60;
  m_nsps=6912;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab5->setStyleSheet("QLabel{background-color: #ff6ec7}");
  lab5->setText(m_mode);
  ui->actionJT8_1->setChecked(true);
}

void MainWindow::on_actionJT8_2_triggered()
{
  m_mode="JT8-2";
  m_TRperiod=120;
  m_nsps=15360;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab5->setStyleSheet("QLabel{background-color: #ffff00}");
  lab5->setText(m_mode);
  ui->actionJT8_2->setChecked(true);
}

void MainWindow::on_actionJT8_5_triggered()
{
  m_mode="JT8-5";
  m_TRperiod=300;
  m_nsps=40960;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab5->setStyleSheet("QLabel{background-color: #ffa500}");
  lab5->setText(m_mode);
  ui->actionJT8_5->setChecked(true);
}

void MainWindow::on_actionJT8_10_triggered()
{
  m_mode="JT8-10";
  m_TRperiod=600;
  m_nsps=82944;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab5->setStyleSheet("QLabel{background-color: #7fff00}");
  lab5->setText(m_mode);
  ui->actionJT8_10->setChecked(true);
}

void MainWindow::on_actionJT8_30_triggered()
{
  m_mode="JT8-30";
  m_TRperiod=1800;
  m_nsps=250880;
  soundInThread.setPeriod(m_TRperiod,m_nsps);
  soundOutThread.setPeriod(m_TRperiod,m_nsps);
  g_pWideGraph->setPeriod(m_TRperiod,m_nsps);
  lab5->setStyleSheet("QLabel{background-color: #97ffff}");
  lab5->setText(m_mode);
  ui->actionJT8_30->setChecked(true);
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
