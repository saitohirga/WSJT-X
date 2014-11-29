//-------------------------------------------------------- MainWindow

#include "mainwindow.h"

#include <cinttypes>
#include <cstdlib>

#include <QThread>
#include <QLineEdit>
#include <QRegExpValidator>
#include <QRegExp>
#include <QDesktopServices>
#include <QUrl>
#include <QDir>
#include <QDebug>
#include <QtConcurrent/QtConcurrentRun>

#include "revision_utils.hpp"
#include "soundout.h"
#include "plotter.h"
#include "about.h"
#include "astro.h"
#include "widegraph.h"
#include "sleep.h"
#include "getfile.h"
#include "logqso.h"
#include "Bands.hpp"
#include "TransceiverFactory.hpp"
#include "FrequencyList.hpp"
#include "StationList.hpp"
#include "LiveFrequencyValidator.hpp"
#include "FrequencyItemDelegate.hpp"

#include "ui_mainwindow.h"
#include "moc_mainwindow.cpp"

int volatile itone[NUM_JT65_SYMBOLS];	//Audio tones for all Tx symbols
int volatile icw[NUM_CW_SYMBOLS];	//Dits for CW ID

int outBufSize;
int rc;
qint32  g_iptt;
wchar_t buffer[256];


namespace
{
  Radio::Frequency constexpr default_frequency {14076000};
  QRegExp message_alphabet {"[- A-Za-z0-9+./?]*"};
}

class BandAndFrequencyItemDelegate final
  : public QStyledItemDelegate
{
public:
  explicit BandAndFrequencyItemDelegate (Bands const * bands, QObject * parent = nullptr)
    : QStyledItemDelegate {parent}
    , bands_ {bands}
  {
  }

  QString displayText (QVariant const& v, QLocale const&) const override
  {
    return Radio::pretty_frequency_MHz_string (Radio::frequency (v, 6))
      + QChar::Nbsp
      + '(' + (bands_->data (bands_->find (Radio::frequency (v, 6)))).toString () + ')';
  }

private:
  Bands const * bands_;
};

//--------------------------------------------------- MainWindow constructor
MainWindow::MainWindow(bool multiple, QSettings * settings, QSharedMemory *shdmem,
                       unsigned downSampleFactor, QWidget *parent) :
  QMainWindow(parent),
  m_revision {revision ("$Rev$")},
  m_multiple {multiple},
  m_settings (settings),
  ui(new Ui::MainWindow),
  m_config (settings, this),
  m_wideGraph (new WideGraph (settings)),
  m_logDlg (new LogQSO (program_title (), settings, &m_config, this)),
  m_dialFreq {0},
  m_detector (RX_SAMPLE_RATE, NTMAX / 2, 6912 / 2, downSampleFactor),
  m_modulator (TX_SAMPLE_RATE, NTMAX / 2),
  m_audioThread {new QThread},
  m_diskData {false},
  m_appDir {QApplication::applicationDirPath ()},
  mem_jt9 {shdmem},
  psk_Reporter (new PSK_Reporter (this)),
  m_msAudioOutputBuffered (0u),
  m_framesAudioInputBuffered (RX_SAMPLE_RATE / 10),
  m_downSampleFactor (downSampleFactor),
  m_audioThreadPriority (QThread::HighPriority),
  m_bandEdited {false},
  m_splitMode {false},
  m_monitoring {false},
  m_transmitting {false},
  m_tune {false},
  m_lastMonitoredFrequency {default_frequency},
  m_toneSpacing {0.}
{
  ui->setupUi(this);

  // Closedown.
  connect (ui->actionExit, &QAction::triggered, this, &QMainWindow::close);

  // parts of the rig error message box that are fixed
  m_rigErrorMessageBox.setInformativeText (tr ("Do you want to reconfigure the radio interface?"));
  m_rigErrorMessageBox.setStandardButtons (QMessageBox::Cancel | QMessageBox::Ok | QMessageBox::Retry);
  m_rigErrorMessageBox.setDefaultButton (QMessageBox::Ok);
  m_rigErrorMessageBox.setIcon (QMessageBox::Critical);

  // start audio thread and hook up slots & signals for shutdown management
  // these objects need to be in the audio thread so that invoking
  // their slots is done in a thread safe way
  m_soundOutput.moveToThread (m_audioThread);
  m_modulator.moveToThread (m_audioThread);
  m_soundInput.moveToThread (m_audioThread);
  m_detector.moveToThread (m_audioThread);

  connect (this, &MainWindow::finished, m_audioThread, &QThread::quit); // quit thread event loop
  connect (m_audioThread, &QThread::finished, m_audioThread, &QThread::deleteLater); // disposal

  // hook up sound output stream slots & signals
  connect (this, &MainWindow::initializeAudioOutputStream, &m_soundOutput, &SoundOutput::setFormat);
  connect (&m_soundOutput, &SoundOutput::error, this, &MainWindow::showSoundOutError);
  // connect (&m_soundOutput, &SoundOutput::status, this, &MainWindow::showStatusMessage);
  connect (this, &MainWindow::outAttenuationChanged, &m_soundOutput, &SoundOutput::setAttenuation);

  // hook up Modulator slots
  connect (this, &MainWindow::transmitFrequency, &m_modulator, &Modulator::setFrequency);
  connect (this, &MainWindow::endTransmitMessage, &m_modulator, &Modulator::stop);
  connect (this, &MainWindow::tune, &m_modulator, &Modulator::tune);
  connect (this, &MainWindow::sendMessage, &m_modulator, &Modulator::start);

  // hook up the audio input stream
  connect (this, &MainWindow::startAudioInputStream, &m_soundInput, &SoundInput::start);
  connect (this, &MainWindow::suspendAudioInputStream, &m_soundInput, &SoundInput::suspend);
  connect (this, &MainWindow::resumeAudioInputStream, &m_soundInput, &SoundInput::resume);
  connect (this, &MainWindow::finished, &m_soundInput, &SoundInput::stop);

  connect (this, &MainWindow::finished, this, &MainWindow::close);

  connect(&m_soundInput, &SoundInput::error, this, &MainWindow::showSoundInError);
  // connect(&m_soundInput, &SoundInput::status, this, &MainWindow::showStatusMessage);

  // hook up the detector
  connect(&m_detector, &Detector::framesWritten, this, &MainWindow::dataSink);

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
  connect (m_logDlg.data (), &LogQSO::acceptQSO, this, &MainWindow::acceptQSO2);
  connect (this, &MainWindow::finished, m_logDlg.data (), &LogQSO::close);


  on_EraseButton_clicked();

  QActionGroup* modeGroup = new QActionGroup(this);
  ui->actionJT9_1->setActionGroup(modeGroup);
  ui->actionJT9W_1->setActionGroup(modeGroup);
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

  // initialise decoded text font and hook up change signal
  setDecodedTextFont (m_config.decoded_text_font ());
  connect (&m_config, &Configuration::decoded_text_font_changed, [this] (QFont const& font) {
      setDecodedTextFont (font);
    });

  setWindowTitle (program_title ());
  createStatusBar();

  connect(&proc_jt9, SIGNAL(readyReadStandardOutput()),
          this, SLOT(readFromStdout()));

  connect(&proc_jt9, SIGNAL(error(QProcess::ProcessError)),
          this, SLOT(jt9_error(QProcess::ProcessError)));

  connect(&proc_jt9, SIGNAL(readyReadStandardError()),
          this, SLOT(readFromStderr()));

  // Hook up working frequencies.
  ui->bandComboBox->setModel (m_config.frequencies ());
  ui->bandComboBox->setModelColumn (1); // MHz

  // Add delegate to show bands alongside frequencies in combo box
  // popup list.
  ui->bandComboBox->view ()->setItemDelegateForColumn (1, new BandAndFrequencyItemDelegate {m_config.bands (), this});

  // combo box drop downs are limited to the drop down selector width,
  // this almost random increase improves the situation
  ui->bandComboBox->view ()->setMinimumWidth (ui->bandComboBox->view ()->sizeHintForColumn (1) + 40);

  // Enable live band combo box entry validation and action.
  auto band_validator = new LiveFrequencyValidator {ui->bandComboBox
                                                    , m_config.bands ()
                                                    , m_config.frequencies ()
                                                    , this};
  ui->bandComboBox->setValidator (band_validator);

  // Hook up signals.
  connect (band_validator, &LiveFrequencyValidator::valid, this, &MainWindow::band_changed);
  connect (ui->bandComboBox->lineEdit (), &QLineEdit::textEdited, [this] (QString const&) {m_bandEdited = true;});

  // hook up configuration signals
  connect (&m_config, &Configuration::transceiver_update, this, &MainWindow::handle_transceiver_update);
  connect (&m_config, &Configuration::transceiver_failure, this, &MainWindow::handle_transceiver_failure);

  // set up message text validators
  ui->tx1->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->tx2->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->tx3->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->tx4->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->tx5->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->tx6->setValidator (new QRegExpValidator {message_alphabet, this});
  ui->freeTextMsg->setValidator (new QRegExpValidator {message_alphabet, this});

  // Free text macros model to widget hook up.
  ui->tx5->setModel (m_config.macros ());
  connect (ui->tx5->lineEdit ()
           , &QLineEdit::editingFinished
           , [this] () {on_tx5_currentTextChanged (ui->tx5->lineEdit ()->text ());});
  ui->freeTextMsg->setModel (m_config.macros ());
  connect (ui->freeTextMsg->lineEdit ()
           , &QLineEdit::editingFinished
           , [this] () {on_freeTextMsg_currentTextChanged (ui->freeTextMsg->lineEdit ()->text ());});

  auto font = ui->readFreq->font();
  font.setFamily("helvetica");
  font.setPointSize(9);
  font.setWeight(75);
  ui->readFreq->setFont(font);

  connect(&m_guiTimer, &QTimer::timeout, this, &MainWindow::guiUpdate);
  m_guiTimer.start(100);                            //Don't change the 100 ms!

  ptt0Timer = new QTimer(this);
  ptt0Timer->setSingleShot(true);
  connect(ptt0Timer, &QTimer::timeout, this, &MainWindow::stopTx2);
  ptt1Timer = new QTimer(this);
  ptt1Timer->setSingleShot(true);
  connect(ptt1Timer, &QTimer::timeout, this, &MainWindow::startTx2);

  logQSOTimer = new QTimer(this);
  logQSOTimer->setSingleShot(true);
  connect(logQSOTimer, &QTimer::timeout, this, &MainWindow::on_logQSOButton_clicked);

  tuneButtonTimer= new QTimer(this);
  tuneButtonTimer->setSingleShot(true);
  connect(tuneButtonTimer, &QTimer::timeout, this, &MainWindow::on_stopTxButton_clicked);

  killFileTimer = new QTimer(this);
  killFileTimer->setSingleShot(true);
  connect(killFileTimer, &QTimer::timeout, this, &MainWindow::killFile);

  m_auto=false;
  m_waterfallAvg = 1;
  m_txFirst=false;
  m_btxok=false;
  m_restart=false;
  m_killAll=false;
  m_widebandDecode=false;
  m_ntx=1;
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
  m_secID=0;
  m_blankLine=false;
  m_decodedText2=false;
  m_freeText=false;
  m_msErase=0;
  m_sent73=false;
  m_watchdogLimit=7;
  m_repeatMsg=0;
  m_secBandChanged=0;
  m_lockTxFreq=false;
  ui->readFreq->setEnabled(false);
  m_QSOText.clear();
  decodeBusy(false);

  signalMeter = new SignalMeter(ui->meterFrame);
  signalMeter->resize(50, 160);

  ui->labAz->setStyleSheet("border: 0px;");
  ui->labDist->setStyleSheet("border: 0px;");

  readSettings();		         //Restore user's setup params

  // start the audio thread
  m_audioThread->start (m_audioThreadPriority);

#ifdef WIN32
  if (!m_multiple)
    {
      while(true)
        {
          int iret=killbyname("jt9.exe");
          if(iret == 603) break;
          if(iret != 0) msgBox("KillByName return code: " +
                               QString::number(iret));
        }
    }
#endif

  auto_tx_label->setText (m_config.quick_call () ? "Tx-Enable Armed" : "Tx-Enable Disarmed");

  {
    //delete any .quit file that might have been left lying around
    //since its presence will cause jt9 to exit a soon as we start it
    //and decodes will hang
    QFile quitFile (".quit");
    while (quitFile.exists ())
      {
        if (!quitFile.remove ())
          {
            msgBox ("Error removing \"" + quitFile.fileName () +
                    "\" - OK to retry.");
          }
      }
  }

  QFile lockFile(".lock");     //Create .lock so jt9 will wait
  lockFile.open(QIODevice::ReadWrite);

  QStringList jt9_args {
    "-s", QApplication::applicationName ()
      , "-w", "1"
      , "-e", QDir::toNativeSeparators (m_appDir)
      , "-a", QDir::toNativeSeparators (m_config.data_path ().absolutePath ())
      };
  proc_jt9.start(QDir::toNativeSeparators (m_appDir) + QDir::separator () +
          "jt9", jt9_args, QIODevice::ReadWrite | QIODevice::Unbuffered);

  QString fname(QDir::toNativeSeparators(m_config.data_path ().absoluteFilePath ("wsjtx_wisdom.dat")));
  QByteArray cfname=fname.toLocal8Bit();
  fftwf_import_wisdom_from_filename(cfname);

  getpfx();                               //Load the prefix/suffix dictionary
  genStdMsgs(m_rpt);
  m_ntx=6;
  ui->txrb6->setChecked(true);
  if(m_mode!="JT9" and m_mode!="JT9W-1" and m_mode!="JT65" and
     m_mode!="JT9+JT65") m_mode="JT9";
  on_actionWide_Waterfall_triggered();                   //###
  m_wideGraph->setLockTxFreq(m_lockTxFreq);
  m_wideGraph->setModeTx(m_mode);
  m_wideGraph->setModeTx(m_modeTx);

  connect(m_wideGraph.data (), SIGNAL(setFreq3(int,int)),this,
          SLOT(setFreq4(int,int)));

  if(m_mode=="JT9") on_actionJT9_1_triggered();
  if(m_mode=="JT9W-1") on_actionJT9W_1_triggered();
  if(m_mode=="JT65") on_actionJT65_triggered();
  if(m_mode=="JT9+JT65") on_actionJT9_JT65_triggered();

  future1 = new QFuture<void>;
  watcher1 = new QFutureWatcher<void>;
  connect(watcher1, SIGNAL(finished()),this,SLOT(diskDat()));

  future2 = new QFuture<void>;
  watcher2 = new QFutureWatcher<void>;
  connect(watcher2, SIGNAL(finished()),this,SLOT(diskWriteFinished()));

  Q_EMIT startAudioInputStream (m_config.audio_input_device (), m_framesAudioInputBuffered, &m_detector, m_downSampleFactor, m_config.audio_input_channel ());
  Q_EMIT initializeAudioOutputStream (m_config.audio_output_device (), AudioDevice::Mono == m_config.audio_output_channel () ? 1 : 2, m_msAudioOutputBuffered);

  Q_EMIT transmitFrequency (ui->TxFreqSpinBox->value () - m_XIT);

  auto t = "UTC   dB   DT Freq   Message";
  ui->decodedTextLabel->setText(t);
  ui->decodedTextLabel2->setText(t);

  enable_DXCC_entity (m_config.DXCC ());  // sets text window proportions and (re)inits the logbook

  ui->label_9->setStyleSheet("QLabel{background-color: #aabec8}");
  ui->label_10->setStyleSheet("QLabel{background-color: #aabec8}");
  ui->labUTC->setStyleSheet("QLabel { background-color : black; color : yellow; }");
  ui->labDialFreq->setStyleSheet("QLabel { background-color : black; color : yellow; }");

  m_config.transceiver_online (true);
  qsy (m_lastMonitoredFrequency);
  monitor (!m_config.monitor_off_at_startup ());

#if !WSJT_ENABLE_EXPERIMENTAL_FEATURES
  ui->actionJT9W_1->setEnabled (false);
#endif
}

//--------------------------------------------------- MainWindow destructor
MainWindow::~MainWindow()
{
  QString fname(QDir::toNativeSeparators(m_config.data_path ().absoluteFilePath ("wsjtx_wisdom.dat")));
  QByteArray cfname=fname.toLocal8Bit();
  fftwf_export_wisdom_to_filename(cfname);
  m_audioThread->wait ();
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
  m_settings->setValue ("AstroDisplayed", m_astroWidget && m_astroWidget->isVisible());
  m_settings->setValue ("FreeText", ui->freeTextMsg->currentText ());
  m_settings->endGroup();

  m_settings->beginGroup("Common");
  m_settings->setValue("Mode",m_mode);
  m_settings->setValue("ModeTx",m_modeTx);
  m_settings->setValue("SaveNone",ui->actionNone->isChecked());
  m_settings->setValue("SaveDecoded",ui->actionSave_decoded->isChecked());
  m_settings->setValue("SaveAll",ui->actionSave_all->isChecked());
  m_settings->setValue("NDepth",m_ndepth);
  m_settings->setValue("RxFreq",ui->RxFreqSpinBox->value ());
  m_settings->setValue("TxFreq",ui->TxFreqSpinBox->value ());
  m_settings->setValue ("DialFreq", QVariant::fromValue(m_lastMonitoredFrequency));
  m_settings->setValue("InGain",m_inGain);
  m_settings->setValue("OutAttenuation", ui->outAttenuation->value ());
  m_settings->setValue("NoSuffix",m_noSuffix);
  m_settings->setValue("GUItab",ui->tabWidget->currentIndex());
  m_settings->setValue("OutBufSize",outBufSize);
  m_settings->setValue("LockTxFreq",m_lockTxFreq);
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
  m_path = m_settings->value("MRUdir", m_config.save_directory ().absolutePath ()).toString ();
  m_txFirst = m_settings->value("TxFirst",false).toBool();
  ui->txFirstCheckBox->setChecked(m_txFirst);
  auto displayAstro = m_settings->value ("AstroDisplayed", false).toBool ();

  if (m_settings->contains ("FreeText"))
  {
    ui->freeTextMsg->setCurrentText (m_settings->value ("FreeText").toString ());
  }

  m_settings->endGroup();

  // do this outside of settings group because it uses groups internally
  if (displayAstro)
    {
      on_actionAstronomical_data_triggered ();
    }

  m_settings->beginGroup("Common");
  morse_(const_cast<char *> (m_config.my_callsign ().toLatin1().constData())
         , const_cast<int *> (icw)
         , &m_ncw
         , m_config.my_callsign ().length());
  m_mode=m_settings->value("Mode","JT9").toString();
  m_modeTx=m_settings->value("ModeTx","JT9").toString();
  if(m_modeTx.mid(0,3)=="JT9") ui->pbTxMode->setText("Tx JT9  @");
  if(m_modeTx=="JT65") ui->pbTxMode->setText("Tx JT65  #");
  ui->actionNone->setChecked(m_settings->value("SaveNone",true).toBool());
  ui->actionSave_decoded->setChecked(m_settings->value(
                                                       "SaveDecoded",false).toBool());
  ui->actionSave_all->setChecked(m_settings->value("SaveAll",false).toBool());
  ui->RxFreqSpinBox->setValue(m_settings->value("RxFreq",1500).toInt());
  m_lastMonitoredFrequency = m_settings->value ("DialFreq", QVariant::fromValue<Frequency> (default_frequency)).value<Frequency> ();
  ui->TxFreqSpinBox->setValue(m_settings->value("TxFreq",1500).toInt());
  Q_EMIT transmitFrequency (ui->TxFreqSpinBox->value () - m_XIT);
  m_saveDecoded=ui->actionSave_decoded->isChecked();
  m_saveAll=ui->actionSave_all->isChecked();
  m_ndepth=m_settings->value("NDepth",3).toInt();
  m_inGain=m_settings->value("InGain",0).toInt();
  ui->inGain->setValue(m_inGain);

  // setup initial value of tx attenuator
  ui->outAttenuation->setValue (m_settings->value ("OutAttenuation", 0).toInt ());
  on_outAttenuation_valueChanged (ui->outAttenuation->value ());

  m_noSuffix=m_settings->value("NoSuffix",false).toBool();
  int n=m_settings->value("GUItab",0).toInt();
  ui->tabWidget->setCurrentIndex(n);
  outBufSize=m_settings->value("OutBufSize",4096).toInt();
  m_lockTxFreq=m_settings->value("LockTxFreq",false).toBool();
  ui->cbTxLock->setChecked(m_lockTxFreq);
  m_plus2kHz=m_settings->value("Plus2kHz",false).toBool();
  ui->cbPlus2kHz->setChecked(m_plus2kHz);
  m_settings->endGroup();

  // use these initialisation settings to tune the audio o/p buffer
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

void MainWindow::setDecodedTextFont (QFont const& font)
{
  ui->decodedTextBrowser->setFont (font);
  ui->decodedTextBrowser2->setFont (font);
  ui->decodedTextLabel->setFont (font);
  ui->decodedTextLabel2->setFont (font);
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
      m_fname=m_config.save_directory ().absoluteFilePath (t.date().toString("yyMMdd") + "_" + t2 + ".wav");
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

void MainWindow::on_actionSettings_triggered()               //Setup Dialog
{
  ui->readFreq->setStyleSheet("");
  ui->readFreq->setEnabled(false);

  if (QDialog::Accepted == m_config.exec ())
    {
      on_dxGridEntry_textChanged (m_hisGrid); // recalculate distances in case of units change
      enable_DXCC_entity (m_config.DXCC ());  // sets text window proportions and (re)inits the logbook

      if(m_config.spot_to_psk_reporter ())
        {
          pskSetLocal ();
        }

      if(m_mode=="JT9W-1") m_toneSpacing=pow(2,m_config.jt9w_bw_mult ())*12000.0/6912.0;

      if(m_config.restart_audio_input ()) {
        Q_EMIT startAudioInputStream (m_config.audio_input_device (), m_framesAudioInputBuffered, &m_detector, m_downSampleFactor, m_config.audio_input_channel ());
      }
      if(m_config.restart_audio_output ()) {
        Q_EMIT initializeAudioOutputStream (m_config.audio_output_device (), AudioDevice::Mono == m_config.audio_output_channel () ? 1 : 2, m_msAudioOutputBuffered);
      }

      auto_tx_label->setText (m_config.quick_call () ? "Tx-Enable Armed" : "Tx-Enable Disarmed");

      displayDialFrequency ();
    }

  setXIT (ui->TxFreqSpinBox->value ());
  if (m_config.transceiver_online ())
    {
      Q_EMIT m_config.transceiver_frequency (m_dialFreq);
    }
}

void MainWindow::on_monitorButton_clicked (bool checked)
{
  if (!m_transmitting)
    {
      auto prior = m_monitoring;
      monitor (checked);

      if (!prior)
        {
          m_diskData = false;	// no longer reading WAV files

          // put rig back where it was when last in control
          Q_EMIT m_config.transceiver_frequency (m_lastMonitoredFrequency);
          setXIT (ui->TxFreqSpinBox->value ());
        }

      Q_EMIT m_config.sync_transceiver (true, checked); // gets
                                                        // Configuration
                                                        // in/out of
                                                        // strict
                                                        // split and
                                                        // mode
                                                        // checking

    }
  else
    {
      ui->monitorButton->setChecked (false); // disallow
    }
}

void MainWindow::monitor (bool state)
{
  ui->monitorButton->setChecked (state);
  if (state)
    {
      if (!m_monitoring)
        {
          Q_EMIT resumeAudioInputStream ();
        }
    }
  else
    {
      Q_EMIT suspendAudioInputStream ();
    }
  m_monitoring = state;
}

void MainWindow::on_actionAbout_triggered()                  //Display "About"
{
  CAboutDlg {program_title (m_revision), this}.exec ();
}

void MainWindow::on_autoButton_clicked (bool checked)
{
  m_auto = checked;
  if (!m_auto)
    {
      m_btxok = false;
      monitor (true);
      m_repeatMsg = 0;
    }
}

void MainWindow::auto_tx_mode (bool state)
{
  ui->autoButton->setChecked (state);
  on_autoButton_clicked (state);
}

void MainWindow::keyPressEvent( QKeyEvent *e )                //keyPressEvent
{
  int n;
  switch(e->key())
    {
    case Qt::Key_1:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb1_clicked();
        e->ignore ();
        return;
      }
      break;
    case Qt::Key_2:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb2_clicked();
        return;
      }
      break;
    case Qt::Key_3:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb3_clicked();
        return;
      }
      break;
    case Qt::Key_4:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb4_clicked();
        return;
      }
      break;
    case Qt::Key_5:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb5_clicked();
        return;
      }
      break;
    case Qt::Key_6:
      if(e->modifiers() & Qt::AltModifier) {
        on_txb6_clicked();
        return;
      }
      break;
    case Qt::Key_D:
      if(e->modifiers() & Qt::ShiftModifier) {
        if(!m_decoderBusy) {
          jt9com_.newdat=0;
          jt9com_.nagain=0;
          decode();
          return;
        }
      }
      break;
    case Qt::Key_F4:
      ui->dxCallEntry->setText("");
      ui->dxGridEntry->setText("");
      genStdMsgs("");
      if (1 == ui->tabWidget->currentIndex())
        {
          ui->genMsg->setText(ui->tx6->text());
          m_ntx=7;
          ui->rbGenMsg->setChecked(true);
        }
      else
        {
          m_ntx=6;
          ui->txrb6->setChecked(true);
        }
      return;
    case Qt::Key_F6:
      if(e->modifiers() & Qt::ShiftModifier) {
        on_actionDecode_remaining_files_in_directory_triggered();
        return;
      }
      break;
    case Qt::Key_F11:
      n=11;
      if(e->modifiers() & Qt::ControlModifier) n+=100;
      bumpFqso(n);
      return;
    case Qt::Key_F12:
      n=12;
      if(e->modifiers() & Qt::ControlModifier) n+=100;
      bumpFqso(n);
      return;
    case Qt::Key_F:
      if(e->modifiers() & Qt::ControlModifier) {
        if(ui->tabWidget->currentIndex()==0) {
          ui->tx5->clearEditText();
          ui->tx5->setFocus();
        } else {
          ui->freeTextMsg->clearEditText();
          ui->freeTextMsg->setFocus();
        }
        return;
      }
      break;
    case Qt::Key_G:
      if(e->modifiers() & Qt::AltModifier) {
        genStdMsgs(m_rpt);
        return;
      }
      break;
    case Qt::Key_H:
      if(e->modifiers() & Qt::AltModifier) {
        on_stopTxButton_clicked();
        return;
      }
      break;
    case Qt::Key_L:
      if(e->modifiers() & Qt::ControlModifier) {
        lookup();
        genStdMsgs(m_rpt);
        return;
      }
      break;
    case Qt::Key_V:
      if(e->modifiers() & Qt::AltModifier) {
        m_fileToSave=m_fname;
        return;
      }
      break;
    }

  QMainWindow::keyPressEvent (e);
}

void MainWindow::bumpFqso(int n)                                 //bumpFqso()
{
  int i;
  bool ctrl = (n>=100);
  n=n%100;
  i=ui->RxFreqSpinBox->value ();
  if(n==11) i--;
  if(n==12) i++;
  if (ui->RxFreqSpinBox->isEnabled ())
    {
      ui->RxFreqSpinBox->setValue (i);
    }
  if(ctrl && ui->TxFreqSpinBox->isEnabled ())
    {
      ui->TxFreqSpinBox->setValue (i);
    }
}

void MainWindow::qsy (Frequency f)
{
  if (!m_transmitting)
    {
      if (m_monitoring)
        {
          m_lastMonitoredFrequency = f;
        }

      if (m_dialFreq != f)
        {
          m_dialFreq = f;

          m_repeatMsg=0;
          m_secBandChanged=QDateTime::currentMSecsSinceEpoch()/1000;

          QFile f2(m_config.data_path ().absoluteFilePath ("ALL.TXT"));
          f2.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
          QTextStream out(&f2);
          out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
              << "  " << (m_dialFreq / 1.e6) << " MHz  " << m_mode << endl;
          f2.close();
          if (m_config.spot_to_psk_reporter ())
            {
              pskSetLocal ();
            }

          displayDialFrequency ();
          statusChanged();
          m_wideGraph->setDialFreq(m_dialFreq / 1.e6);
        }
    }
}

void MainWindow::displayDialFrequency ()
{
  // lookup band
  auto bands_model = m_config.bands ();
  ui->bandComboBox->setCurrentText (bands_model->data (bands_model->find (m_dialFreq)).toString ());

  // search working frequencies for one we are within 10kHz of
  auto frequencies = m_config.frequencies ();
  bool valid {false};
  for (int row = 0; row < frequencies->rowCount (); ++row)
    {
      auto working_frequency = frequencies->data (frequencies->index (row, 0)).value<Frequency> ();
      if (std::llabs (working_frequency - m_dialFreq) < 10000)
        {
          valid = true;
        }
    }
  if (valid)
    {
      ui->labDialFreq->setStyleSheet("QLabel { background-color : black; color : yellow; }");
    }
  else
    {
      ui->labDialFreq->setStyleSheet("QLabel { background-color : red; color : yellow; }");
    }

  ui->labDialFreq->setText (Radio::pretty_frequency_MHz_string (m_dialFreq));
}

void MainWindow::statusChanged()
{
  QFile f("wsjtx_status.txt");
  if(f.open(QFile::WriteOnly | QIODevice::Text)) {
    QTextStream out(&f);
    out << (m_dialFreq / 1.e6) << ";" << m_mode << ";" << m_hisCall << ";"
        << ui->rptSpinBox->value() << ";" << m_modeTx << endl;
    f.close();
  } else {
    msgBox("Cannot open file \"" + f.fileName () + "\".");
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
  tx_status_label = new QLabel("Receiving");
  tx_status_label->setAlignment(Qt::AlignHCenter);
  tx_status_label->setMinimumSize(QSize(80,18));
  tx_status_label->setStyleSheet("QLabel{background-color: #00ff00}");
  tx_status_label->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(tx_status_label);


  mode_label = new QLabel("");
  mode_label->setAlignment(Qt::AlignHCenter);
  mode_label->setMinimumSize(QSize(80,18));
  mode_label->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(mode_label);

  last_tx_label = new QLabel("");
  last_tx_label->setAlignment(Qt::AlignHCenter);
  last_tx_label->setMinimumSize(QSize(150,18));
  last_tx_label->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(last_tx_label);

  auto_tx_label = new QLabel("");
  auto_tx_label->setAlignment(Qt::AlignHCenter);
  auto_tx_label->setMinimumSize(QSize(150,18));
  auto_tx_label->setFrameStyle(QFrame::Panel | QFrame::Sunken);
  statusBar()->addWidget(auto_tx_label);
}

void MainWindow::closeEvent(QCloseEvent * e)
{
  m_config.transceiver_offline ();
  writeSettings ();
  m_guiTimer.stop ();
  m_prefixes.reset ();
  m_shortcuts.reset ();
  m_mouseCmnds.reset ();

  if(m_fname != "") killFile();
  m_killAll=true;
  mem_jt9->detach();
  QFile quitFile(".quit");
  quitFile.open(QIODevice::ReadWrite);
  QFile lockFile(".lock");
  lockFile.remove();                      // Allow jt9 to terminate
  bool b=proc_jt9.waitForFinished(1000);
  if(!b) proc_jt9.kill();
  quitFile.remove();

  Q_EMIT finished ();

  QMainWindow::closeEvent (e);
}

void MainWindow::on_stopButton_clicked()                       //stopButton
{
  monitor (false);
  m_loopall=false;  
}

void MainWindow::msgBox(QString t)                             //msgBox
{
  msgBox0.setText(t);
  msgBox0.exec();
}

void MainWindow::on_actionOnline_User_Guide_triggered()      //Display manual
{
#if defined (CMAKE_BUILD)
  QDesktopServices::openUrl (QUrl (PROJECT_MANUAL_DIRECTORY_URL "/" PROJECT_MANUAL));
#endif
}

//Display local copy of manual
void MainWindow::on_actionLocal_User_Guide_triggered()
{
#if defined (CMAKE_BUILD)
  auto file = m_config.doc_path ().absoluteFilePath (PROJECT_MANUAL);
  QDesktopServices::openUrl (QUrl {"file:///" + file});
#endif
}

void MainWindow::on_actionWide_Waterfall_triggered()      //Display Waterfalls
{
  m_wideGraph->show();
}

void MainWindow::on_actionAstronomical_data_triggered()
{
  if (!m_astroWidget)
    {
      m_astroWidget.reset (new Astro {m_settings, m_config.data_path ()});

      // hook up termination signal
      connect (this, &MainWindow::finished, m_astroWidget.data (), &Astro::close);
    }
  m_astroWidget->showNormal();
}

void MainWindow::on_actionOpen_triggered()                     //Open File
{
  monitor (false);

  QString fname;
  fname=QFileDialog::getOpenFileName(this, "Open File", m_path,
                                     "WSJT Files (*.wav)");
  if(fname != "") {
    m_path=fname;
    int i;
    i=fname.indexOf(".wav") - 11;
    if(i>=0) {
      tx_status_label->setStyleSheet("QLabel{background-color: #66ff66}");
      tx_status_label->setText(" " + fname.mid(i,15) + " ");
      //      lab1->setText(" " + fname + " ");
    }
    on_stopButton_clicked();
    m_diskData=true;
    *future1 = QtConcurrent::run(getfile, fname, m_TRperiod);
    watcher1->setFuture(*future1);         // call diskDat() when done
  }
}

void MainWindow::on_actionOpen_next_in_directory_triggered()   //Open Next
{
  monitor (false);

  int i,len;
  QFileInfo fi(m_path);
  QStringList list;
  list= fi.dir().entryList().filter(".wav",Qt::CaseInsensitive);
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
        tx_status_label->setStyleSheet("QLabel{background-color: #66ff66}");
        tx_status_label->setText(" " + fname.mid(i,len) + " ");
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
                                 QDir::toNativeSeparators(m_config.save_directory ().absolutePath ()) + " ?",
                                 QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QDir dir(m_config.save_directory ());
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
  if (!m_shortcuts)
    {
      QFile f(":/shortcuts.txt");
      if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        msgBox("Cannot open \"" + f.fileName () + "\".");
        return;
      }
      m_shortcuts.reset (new QTextEdit);
      m_shortcuts->setReadOnly(true);
      m_shortcuts->setFontPointSize(10);
      m_shortcuts->setWindowTitle(QApplication::applicationName () + " - " + tr ("Keyboard Shortcuts"));
      m_shortcuts->setGeometry(QRect(45,50,430,460));
      Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
        Qt::WindowMinimizeButtonHint;
      m_shortcuts->setWindowFlags(flags);
      QTextStream s(&f);
      QString t;
      for(int i=0; i<100; i++) {
        t=s.readLine();
        m_shortcuts->append(t);
        if(s.atEnd()) break;
      }
    }
  m_shortcuts->showNormal();
}

void MainWindow::on_actionSpecial_mouse_commands_triggered()
{
  if (!m_mouseCmnds)
    {
      QFile f(":/mouse_commands.txt");
      if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        msgBox("Cannot open \"" + f.fileName () + "\".");
        return;
      }
      m_mouseCmnds.reset (new QTextEdit);
      m_mouseCmnds->setReadOnly(true);
      m_mouseCmnds->setFontPointSize(10);
      m_mouseCmnds->setWindowTitle(QApplication::applicationName () + " - " + tr ("Special Mouse Commands"));
      m_mouseCmnds->setGeometry(QRect(45,50,440,300));
      Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
        Qt::WindowMinimizeButtonHint;
      m_mouseCmnds->setWindowFlags(flags);
      QTextStream s(&f);
      QString t;
      for(int i=0; i<100; i++) {
        t=s.readLine();
        m_mouseCmnds->append(t);
        if(s.atEnd()) break;
      }
    }
  m_mouseCmnds->showNormal();
}

void MainWindow::on_DecodeButton_clicked (bool /* checked */)	//Decode request
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
  if((n%100)==2) on_DecodeButton_clicked (true);
}

void MainWindow::decode()                                       //decode()
{
  if(!m_dataAvailable) return;
  ui->DecodeButton->setChecked (true);
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
  if(m_mode=="JT9W-1") jt9com_.nmode=91;
  if(m_mode=="JT65") jt9com_.nmode=65;
  if(m_mode=="JT9+JT65") jt9com_.nmode=9+65;  // = 74
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

  QFile lockFile(".lock"); // Allow jt9 to start
  lockFile.remove();
  decodeBusy(true);
}

void MainWindow::jt9_error (QProcess::ProcessError e)
{
  if(!m_killAll) {
    msgBox("Error starting or running\n" + m_appDir + "/jt9 -s");
    qDebug() << e;                           // silence compiler warning
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
          QFile lockFile(".lock");
          lockFile.open(QIODevice::ReadWrite);
          ui->DecodeButton->setChecked (false);
          decodeBusy(false);
          m_RxLog=0;
          m_startAnother=m_loopall;
          m_blankLine=true;
          return;
        } else {
        QFile f(m_config.data_path().absoluteFilePath ("ALL.TXT"));
        f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
        QTextStream out(&f);
        if(m_RxLog==1) {
          out << QDateTime::currentDateTimeUtc().toString("yyyy-MMM-dd hh:mm")
              << "  " << (m_dialFreq / 1.e6) << " MHz  " << m_mode << endl;
          m_RxLog=0;
        }
        int n=t.length();
        out << t.mid(0,n-2) << endl;
        f.close();

        if(m_config.insert_blank () && m_blankLine)
          {
            ui->decodedTextBrowser->insertLineSpacer();
            m_blankLine=false;
          }

        DecodedText decodedtext;
        decodedtext = t.replace("\n",""); //t.replace("\n","").mid(0,t.length()-4);

        // the left band display
        ui->decodedTextBrowser->displayDecodedText (decodedtext
                                                    , m_config.my_callsign ()
                                                    , m_config.DXCC ()
                                                    , m_logBook);

        if (abs(decodedtext.frequencyOffset() - m_wideGraph->rxFreq()) <= 10) // this msg is within 10 hertz of our tuned frequency
          {
            // the right QSO window
            ui->decodedTextBrowser2->displayDecodedText(decodedtext,m_config.my_callsign (),false,m_logBook);

            bool b65=decodedtext.isJT65();
            if(b65 and m_modeTx!="JT65") on_pbTxMode_clicked();
            if(!b65 and m_modeTx=="JT65") on_pbTxMode_clicked();
            m_QSOText=decodedtext;
          }

        // find and extract any report for myCall
        bool stdMsg = decodedtext.report(m_config.my_callsign (),/*mod*/m_rptRcvd);

        // extract details and send to PSKreporter
        int nsec=QDateTime::currentMSecsSinceEpoch()/1000-m_secBandChanged;
        bool okToPost=(nsec>50);
        if(m_config.spot_to_psk_reporter () and stdMsg and !m_diskData and okToPost)
          {
            QString msgmode="JT9";
            if (decodedtext.isJT65())
              msgmode="JT65";

            QString deCall;
            QString grid;
            decodedtext.deCallAndGrid(/*out*/deCall,grid);
            int audioFrequency = decodedtext.frequencyOffset();
            int snr = decodedtext.snr();
            Frequency frequency = m_dialFreq + audioFrequency;

            pskSetLocal ();
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
    QFile f("decoded.txt");
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
  static double onAirFreq0=0.0;
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

    QFile f("/tmp/txboth");
    if(f.exists() and fmod(tsec,m_TRperiod) < (1.0 + 85.0*m_nsps/12000.0)) {
      bTxTime=true;
    }

    Frequency onAirFreq = m_dialFreq + ui->TxFreqSpinBox->value ();
    if (onAirFreq > 10139900 && onAirFreq < 10140320)
      {
        bTxTime=false;
        if (m_tune)
          {
            stop_tuning ();
          }
	
        if (m_auto)
          {
            auto_tx_mode (false);
          }

        if(onAirFreq!=onAirFreq0)
          {
            onAirFreq0=onAirFreq;
            QString t="Please choose another Tx frequency.\n";
            t+="WSJT-X will not knowingly transmit\n";
            t+="in the WSPR sub-band on 30 m.";
            msgBox(t);
          }
      }

    float fTR=float((nsec%m_TRperiod))/m_TRperiod;
    if(g_iptt==0 and ((bTxTime and fTR<0.4) or m_tune )) {
      icw[0]=m_ncw;
      g_iptt = 1;
      Q_EMIT m_config.transceiver_ptt (true);
      ptt1Timer->start(200);                       //Sequencer delay
    }
    if(!bTxTime) {
      m_btxok=false;
    }
  }

  // Calculate Tx tones when needed
  if((g_iptt==1 && iptt0==0) || m_restart) {
    QByteArray ba;
    if(m_ntx == 1) ba=ui->tx1->text().toLocal8Bit();
    if(m_ntx == 2) ba=ui->tx2->text().toLocal8Bit();
    if(m_ntx == 3) ba=ui->tx3->text().toLocal8Bit();
    if(m_ntx == 4) ba=ui->tx4->text().toLocal8Bit();
    if(m_ntx == 5) ba=ui->tx5->currentText().toLocal8Bit();
    if(m_ntx == 6) ba=ui->tx6->text().toLocal8Bit();
    if(m_ntx == 7) ba=ui->genMsg->text().toLocal8Bit();
    if(m_ntx == 8) ba=ui->freeTextMsg->currentText().toLocal8Bit();

    ba2msg(ba,message);
    //    ba2msg(ba,msgsent);
    int len1=22;
    int ichk=0,itype=0;
    if(m_modeTx=="JT9") genjt9_(message
                                , &ichk
                                , msgsent
                                , const_cast<int *> (itone)
                                , &itype
                                , len1
                                , len1);
    if(m_modeTx=="JT65") gen65_(message
                                , &ichk
                                , msgsent
                                , const_cast<int *> (itone)
                                , &itype
                                , len1
                                , len1);
    msgsent[22]=0;
    QString t=QString::fromLatin1(msgsent);
    if(m_tune) t="TUNE";
    last_tx_label->setText("Last Tx:  " + t);
    if(m_restart) {
      QFile f(m_config.data_path ().absoluteFilePath ("ALL.TXT"));
      f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
      QTextStream out(&f);
      out << QDateTime::currentDateTimeUtc().toString("hhmm")
          << "  Transmitting " << (m_dialFreq / 1.e6) << " MHz  " << m_modeTx
          << ":  " << t << endl;
      f.close();
      if (m_config.TX_messages ())
        {
          ui->decodedTextBrowser2->displayTransmittedText(t,m_modeTx,ui->TxFreqSpinBox->value ());
        }
    }

    QStringList w=t.split(" ",QString::SkipEmptyParts);
    t="";
    if(w.length()==3) t=w[2];
    icw[0]=0;
    m_sent73=(t=="73" or itype==6);
    if(m_sent73)  {
      if(m_config.id_after_73 ())  icw[0]=m_ncw;
      if(m_config.prompt_to_log () && !m_tune) logQSOTimer->start(200);
    }

    if(m_config.id_interval () >0) {
      int nmin=(m_sec0-m_secID)/60;
      if(nmin >= m_config.id_interval ()) {
        icw[0]=m_ncw;
        m_secID=m_sec0;
      }
    }

    QString t2=QDateTime::currentDateTimeUtc().toString("hhmm");
    if(itype<6 and w.length()>=3 and w[1]==m_config.my_callsign ()) {
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
    if(itype==6 or (w.length()==3 and w[2]=="73")) m_qsoStop=t2;
    m_restart=false;
  }

  if (g_iptt == 1 && iptt0 == 0)
    {
      QString t=QString::fromLatin1(msgsent);
      if(t==m_msgSent0)
        {
          m_repeatMsg++;
        }
      else
        {
          m_repeatMsg=0;
          m_msgSent0=t;
        }

      if(!m_tune)
        {
          QFile f(m_config.data_path ().absoluteFilePath ("ALL.TXT"));
          f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append);
          QTextStream out(&f);
          out << QDateTime::currentDateTimeUtc().toString("hhmm")
              << "  Transmitting " << (m_dialFreq / 1.e6) << " MHz  " << m_modeTx
              << ":  " << t << endl;
          f.close();
        }

      if (m_config.TX_messages () && !m_tune)
        {
          ui->decodedTextBrowser2->displayTransmittedText(t,m_modeTx,ui->TxFreqSpinBox->value ());
        }

      m_transmitting = true;
      transmitDisplay (true);
    }

  if(!m_btxok && btxok0 && g_iptt==1) stopTx();

  /*
  // If m_btxok was just lowered, start a countdown for lowering PTT
  if(!m_btxok && btxok0 && g_iptt==1) nc0=-11;  //RxDelay = 1.0 s
  if(nc0 <= 0) {
  nc0++;
  }
  */

  if(m_startAnother) {
    m_startAnother=false;
    on_actionOpen_next_in_directory_triggered();
  }

  if(nsec != m_sec0) {                                     //Once per second
    QDateTime t = QDateTime::currentDateTimeUtc();
    int fQSO=125;
    if(m_astroWidget) m_astroWidget->astroUpdate(t, m_config.my_grid (), m_hisGrid, fQSO,
                                                 m_setftx, ui->TxFreqSpinBox->value ());

    if(m_transmitting) {
      if(nsendingsh==1) {
        tx_status_label->setStyleSheet("QLabel{background-color: #66ffff}");
      } else if(nsendingsh==-1) {
        tx_status_label->setStyleSheet("QLabel{background-color: #ffccff}");
      } else {
        tx_status_label->setStyleSheet("QLabel{background-color: #ffff33}");
      }
      if(m_tune) {
        tx_status_label->setText("Tx: TUNE");
      } else {
        char s[37];
        sprintf(s,"Tx: %s",msgsent);
        tx_status_label->setText(s);
      }
    } else if(m_monitoring) {
      tx_status_label->setStyleSheet("QLabel{background-color: #00ff00}");
      tx_status_label->setText("Receiving ");
    } else if (!m_diskData) {
      tx_status_label->setStyleSheet("");
      tx_status_label->setText("");
    }

    m_setftx=0;
    QString utc = t.date().toString("yyyy MMM dd") + "\n " +
      t.time().toString() + " ";
    ui->labUTC->setText(utc);
    if(!m_monitoring and !m_diskData) {
      signalMeter->setValue(0);
    }

    m_sec0=nsec;
  }

  iptt0=g_iptt;
  btxok0=m_btxok;
}               //End of GUIupdate


void MainWindow::startTx2()
{
  if (!m_modulator.isActive ()) {
    double fSpread=0.0;
    double snr=99.0;
    QString t=ui->tx5->currentText();
    if(t.mid(0,1)=="#") fSpread=t.mid(1,5).toDouble();
    m_modulator.setSpread(fSpread);
    t=ui->tx6->text();
    if(t.mid(0,1)=="#") snr=t.mid(1,5).toDouble();
    if(snr>0.0 or snr < -50.0) snr=99.0;
    transmit (snr);
    signalMeter->setValue(0);
  }
}

void MainWindow::stopTx()
{
  Q_EMIT endTransmitMessage ();
  m_btxok = false;
  m_transmitting = false;
  g_iptt=0;
  tx_status_label->setStyleSheet("");
  tx_status_label->setText("");
  ptt0Timer->start(200);                       //Sequencer delay
  monitor (true);
}

void MainWindow::stopTx2()
{
  QString rt;

  //Lower PTT
  Q_EMIT m_config.transceiver_ptt (false);

  if (m_config.disable_TX_on_73 () && m_sent73)
    {
      on_stopTxButton_clicked();
    }

  if (m_config.watchdog () && m_repeatMsg>=m_watchdogLimit-1)
    {
      on_stopTxButton_clicked();
      msgBox("Runaway Tx watchdog");
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

  // only allow automatic mode changes when not transmitting
  if (!m_transmitting)
    {
      if (decodedtext.isJT9())
        {
          m_modeTx="JT9";
          ui->pbTxMode->setText("Tx JT9  @");
          m_wideGraph->setModeTx(m_modeTx);
        }
      else if (decodedtext.isJT65())
        {
          m_modeTx="JT65";
          ui->pbTxMode->setText("Tx JT65  #");
          m_wideGraph->setModeTx(m_modeTx);
        }
    }
  else if ((decodedtext.isJT9 () && m_modeTx != "JT9") || (decodedtext.isJT65 () && m_modeTx != "JT65"))
    {
      // if we are not allowing mode change then don't process decode
      return;
    }

  int frequency = decodedtext.frequencyOffset();
  QString firstcall = decodedtext.call();
  // Don't change Tx freq if a station is calling me, unless m_lockTxFreq
  // is true or CTRL is held down
  if ((firstcall!=m_config.my_callsign ()) or m_lockTxFreq or ctrl)
    {
      if (ui->TxFreqSpinBox->isEnabled ())
        {
          ui->TxFreqSpinBox->setValue(frequency);
        }
      else
        {
          return;
        }
    }

  int i9=m_QSOText.indexOf(decodedtext.string());
  if (i9<0 and !decodedtext.isTX())
    {
      ui->decodedTextBrowser2->displayDecodedText(decodedtext,m_config.my_callsign (),false,m_logBook);
      m_QSOText=decodedtext;
    }

  if (ui->RxFreqSpinBox->isEnabled ())
    {
      ui->RxFreqSpinBox->setValue (frequency); //Set Rx freq
    }
  if (decodedtext.isTX())
    {
      if (ctrl && ui->TxFreqSpinBox->isEnabled ())
        {
          ui->TxFreqSpinBox->setValue(frequency); //Set Tx freq
        }
      return;
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
  if(decodedtext.indexOf(m_config.my_callsign ())>=0)
    {
      if (t4.length()>=7   // enough fields for a normal msg
          and !gridOK(t4.at(7))) // but no grid on end of msg
        {
          QString r=t4.at(7);
          if(r.mid(0,3)=="RRR") {
            m_ntx=5;
            ui->txrb5->setChecked(true);
            if(ui->tabWidget->currentIndex()==1) {
              ui->genMsg->setText(ui->tx5->currentText());
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
              ui->genMsg->setText(ui->tx5->currentText());
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
  if(m_transmitting) m_restart=true;
  if(m_config.quick_call ())
    {
      auto_tx_mode (true);
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
    ui->tx5->setCurrentText("");
    ui->tx6->setText("");
    if(m_config.my_callsign () !="" and m_config.my_grid () !="") {
      t="CQ " + m_config.my_callsign () + " " + m_config.my_grid ().mid(0,4);
      msgtype(t, ui->tx6);
    }
    ui->genMsg->setText("");
    return;
  }
  QString hisBase=baseCall(hisCall);
  QString myBase=baseCall(m_config.my_callsign ());

  QString t0=hisBase + " " + myBase + " ";
  t=t0 + m_config.my_grid ().mid(0,4);
  //  if(myBase!=m_config.my_callsign ()) t="DE " + m_config.my_callsign () + " " + m_config.my_grid ().mid(0,4);  //###
  msgtype(t, ui->tx1);
  if(rpt == "") {
    t=t+" OOO";
    msgtype(t, ui->tx2);
    msgtype("RO", ui->tx3);
    msgtype("RRR", ui->tx4);
    msgtype("73", ui->tx5->lineEdit ());
  } else {
    t=t0 + rpt;
    msgtype(t, ui->tx2);
    t=t0 + "R" + rpt;
    msgtype(t, ui->tx3);
    t=t0 + "RRR";
    msgtype(t, ui->tx4);
    t=t0 + "73";
    //    if(myBase!=m_config.my_callsign ()) t="DE " + m_config.my_callsign () + " 73";                  //###
    msgtype(t, ui->tx5->lineEdit ());
  }

  t="CQ " + m_config.my_callsign () + " " + m_config.my_grid ().mid(0,4);
  msgtype(t, ui->tx6);
  if(m_config.my_callsign ()!=myBase) {
    if(shortList(m_config.my_callsign ())) {
      t=hisCall + " " + m_config.my_callsign ();
      msgtype(t, ui->tx1);
      t="CQ " + m_config.my_callsign ();
      msgtype(t, ui->tx6);
    } else {
      t="DE " + m_config.my_callsign () + " " + m_config.my_grid ().mid(0,4);
      msgtype(t, ui->tx2);
      t="DE " + m_config.my_callsign () + " 73";
      msgtype(t, ui->tx5->lineEdit ());
      t="CQ " + m_config.my_callsign () + " " + m_config.my_grid ().mid(0,4);
      msgtype(t, ui->tx6);
    }
  } else {
    if(hisCall!=hisBase) {
      if(shortList(hisCall)) {
        t=hisCall + " " + m_config.my_callsign ();
        msgtype(t, ui->tx1);
      } else {
        t=hisCall + " 73";
        msgtype(t, ui->tx5->lineEdit());
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
  QFile f(m_config.data_path ().absoluteFilePath ("CALL3.TXT"));
  if (f.open (QIODevice::ReadOnly | QIODevice::Text))
    {
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
  
  QFile f1(m_config.data_path ().absoluteFilePath ("CALL3.TXT"));
  if(!f1.open(QIODevice::ReadWrite | QIODevice::Text)) {
    msgBox("Cannot open \"" + f1.fileName () + "\".");
    return;
  }
  if(f1.size()==0) {
    QTextStream out(&f1);
    out << "ZZZZZZ" << endl;
    f1.close();
    f1.open(QIODevice::ReadOnly | QIODevice::Text);
  }
  QFile f2(m_config.data_path ().absoluteFilePath ("CALL3.TMP"));
  if(!f2.open(QIODevice::WriteOnly | QIODevice::Text)) {
    msgBox("Cannot open \"" + f2.fileName () + "\".");
    return;
  }
  QTextStream in(&f1);          //Read from CALL3.TXT
  QTextStream out(&f2);         //Copy into CALL3.TMP
  QString hc=hisCall;
  QString hc1="";
  QString hc2="000000";
  QString s;
  do {
    s=in.readLine();
    hc1=hc2;
    if(s.mid(0,2)=="//") {
      out << s + "\n";          //Copy all comment lines
    } else {
      int i1=s.indexOf(",");
      hc2=s.mid(0,i1);
      if(hc>hc1 && hc<hc2) {
        out << newEntry + "\n";
        out << s + "\n";
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
  if(hc>hc1 && !m_call3Modified) out << newEntry + "\n";
  if(m_call3Modified) {
    QDir data_path {m_config.data_path ()};
    QFile f0(data_path.absoluteFilePath ("CALL3.OLD"));
    if(f0.exists()) f0.remove();
    QFile f1(data_path.absoluteFilePath ("CALL3.TXT"));
    f1.rename(data_path.absoluteFilePath ("CALL3.OLD"));
    f2.rename(data_path.absoluteFilePath ("CALL3.TXT"));
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
  int ichk=1,itype=0;
  genjt9_(message
          , &ichk
          , msgsent
          , const_cast<int *> (itone)
          , &itype
          , len1
          , len1);
  msgsent[22]=0;
  bool text=false;
  if(itype==6) text=true;
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
  auto pos  = tx->cursorPosition ();
  if(text) {
    len=qMin(len,13);
    tx->setText(t.mid(0,len).toUpper());
  } else {
    tx->setText(t);
  }
  tx->setCursorPosition (pos);
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

void MainWindow::on_tx5_currentTextChanged (QString const& text) //tx5 edited
{
  msgtype(text, ui->tx5->lineEdit ());
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

    azdist_(const_cast <char *> (m_config.my_grid ().toLatin1().constData()),const_cast<char *> (m_hisGrid.toLatin1().constData()),&utch,
            &nAz,&nEl,&nDmiles,&nDkm,&nHotAz,&nHotABetter,6,6);
    QString t;
    t.sprintf("Az: %d",nAz);
    ui->labAz->setText(t);
    if (m_config.miles ())
      {
        t.sprintf ("%d mi", int (0.621371 * nDkm));
      }
    else
      {
        t.sprintf ("%d km", nDkm);
      }
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

  m_logDlg->initLogQSO (m_hisCall
                        , m_hisGrid
                        , m_modeTx
                        , m_rptSent
                        , m_rptRcvd
                        , m_dateTimeQSO
                        , (m_dialFreq + ui->TxFreqSpinBox->value ()) / 1.e6
                        , m_config.my_callsign ()
                        , m_config.my_grid ()
                        , m_noSuffix
                        , m_config.log_as_RTTY ()
                        , m_config.report_in_comments ()
                        );
}

void MainWindow::acceptQSO2(bool accepted)
{
  if(accepted)
    {
      QString band = ADIF::bandFromFrequency ((m_dialFreq + ui->TxFreqSpinBox->value ()) / 1.e6);
      QString date = m_dateTimeQSO.toString("yyyy-MM-dd");
      date=date.mid(0,4) + date.mid(5,2) + date.mid(8,2);
      m_logBook.addAsWorked(m_hisCall,band,m_modeTx,date);

      if (m_config.clear_DX ())
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
  mode_label->setStyleSheet("QLabel{background-color: #ff6ec7}");
  mode_label->setText(m_mode);
  m_toneSpacing=0.0;
  ui->actionJT9_1->setChecked(true);
  m_wideGraph->setPeriod(m_TRperiod,m_nsps);
  m_wideGraph->setMode(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  ui->pbTxMode->setEnabled(false);
}

void MainWindow::on_actionJT9W_1_triggered()
{
  m_mode="JT9W-1";
  if(m_modeTx!="JT9") on_pbTxMode_clicked();
  statusChanged();
  m_TRperiod=60;
  m_nsps=6912;
  m_hsymStop=173;
  m_toneSpacing=pow(2,m_config.jt9w_bw_mult ())*12000.0/6912.0;
  mode_label->setStyleSheet("QLabel{background-color: #ff6ec7}");
  mode_label->setText(m_mode);
  ui->actionJT9W_1->setChecked(true);
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
  m_toneSpacing=0.0;
  mode_label->setStyleSheet("QLabel{background-color: #ffff00}");
  mode_label->setText(m_mode);
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
  m_toneSpacing=0.0;
  mode_label->setStyleSheet("QLabel{background-color: #ffa500}");
  mode_label->setText(m_mode);
  ui->actionJT9_JT65->setChecked(true);
  m_wideGraph->setPeriod(m_TRperiod,m_nsps);
  m_wideGraph->setMode(m_mode);
  m_wideGraph->setModeTx(m_modeTx);
  ui->pbTxMode->setEnabled(true);
}

void MainWindow::on_TxFreqSpinBox_valueChanged(int n)
{
  m_wideGraph->setTxFreq(n);
  if(m_lockTxFreq) ui->RxFreqSpinBox->setValue(n);
  Q_EMIT transmitFrequency (n - m_XIT);
}

void MainWindow::on_RxFreqSpinBox_valueChanged(int n)
{
  m_wideGraph->setRxFreq(n);

  if (m_lockTxFreq && ui->TxFreqSpinBox->isEnabled ())
    {
      ui->TxFreqSpinBox->setValue (n);
    }
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

void MainWindow::on_actionErase_ALL_TXT_triggered()          //Erase ALL.TXT
{
  int ret = QMessageBox::warning(this, "Confirm Erase",
                                 "Are you sure you want to erase file ALL.TXT ?",
                                 QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes);
  if(ret==QMessageBox::Yes) {
    QFile f(m_config.data_path ().absoluteFilePath ("ALL.TXT"));
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
    QFile f(m_config.data_path ().absoluteFilePath ("wsjtx_log.adi"));
    f.remove();
  }
}

void MainWindow::on_actionOpen_log_directory_triggered ()
{
  QDesktopServices::openUrl (QUrl::fromLocalFile (m_config.data_path ().absolutePath ()));
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

void MainWindow::on_bandComboBox_activated (int index)
{
  auto frequencies = m_config.frequencies ();
  auto frequency = frequencies->data (frequencies->index (index, 0));

  // Lookup band
  auto bands = m_config.bands ();
  auto band_index = bands->find (frequency);
  if (band_index.isValid ())
    {
      ui->bandComboBox->lineEdit ()->setStyleSheet ({});
      ui->bandComboBox->setCurrentText (band_index.data ().toString ());
    }
  else
    {
      ui->bandComboBox->lineEdit ()->setStyleSheet ("QLineEdit {color: yellow; background-color : red;}");
      ui->bandComboBox->setCurrentText (bands->data (QModelIndex {}).toString ());
    }

  auto f = frequency.value<Frequency> ();
  if (m_plus2kHz)
    {
      f += 2000;
    }

  m_bandEdited = true;
  band_changed (f);
}

void MainWindow::band_changed (Frequency f)
{
  if (m_bandEdited)
    {
      m_bandEdited = false;

      // Upload any queued spots before changing band
      psk_Reporter->sendReport();

      if (!m_transmitting)
        {
          monitor (true);
        }

      Q_EMIT m_config.transceiver_frequency (f);
      qsy (f);
      setXIT (ui->TxFreqSpinBox->value ());
    }
}

void MainWindow::enable_DXCC_entity (bool on)
{
  if (on)
    {
      // re-read the log and cty.dat files
      m_logBook.init(m_config.data_path ());
    }

  if (on)  // adjust the proportions between the two text displays
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
  QString t=ui->tx3->text();
  int i0=t.indexOf(" R-");
  if(i0<0) i0=t.indexOf(" R+");
  t=t.mid(0,i0+1)+t.mid(i0+2,3);
  ui->genMsg->setText(t);
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
  QString t=ui->tx2->text();
  int i0=t.indexOf("/");
  int i1=t.indexOf(" ");
  if(i0>0 and i0<i1) ui->genMsg->setText(t);
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
  ui->genMsg->setText(ui->tx5->currentText());
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

void MainWindow::on_freeTextMsg_currentTextChanged (QString const& text)
{
  msgtype(text, ui->freeTextMsg->lineEdit ());
}

void MainWindow::on_rptSpinBox_valueChanged(int n)
{
  m_rpt=QString::number(n);
  int ntx0=m_ntx;
  QString t=ui->tx5->currentText();
  genStdMsgs(m_rpt);
  ui->tx5->setCurrentText(t);
  m_ntx=ntx0;
  if(m_ntx==1) ui->txrb1->setChecked(true);
  if(m_ntx==2) ui->txrb2->setChecked(true);
  if(m_ntx==3) ui->txrb3->setChecked(true);
  if(m_ntx==4) ui->txrb4->setChecked(true);
  if(m_ntx==5) ui->txrb5->setChecked(true);
  if(m_ntx==6) ui->txrb6->setChecked(true);
  statusChanged();
}

void MainWindow::on_tuneButton_clicked (bool checked)
{
  if (m_tune)
    {
      tuneButtonTimer->start(250);
    } 
  else
    {
      m_sent73=false;
      m_repeatMsg=0;
      on_monitorButton_clicked (true);
    }
  m_tune = checked;
  Q_EMIT tune (checked);
}

void MainWindow::stop_tuning ()
{
  ui->tuneButton->setChecked (false);
  on_tuneButton_clicked (false);
}

void MainWindow::on_stopTxButton_clicked()                    //Stop Tx
{
  if (m_tune)
    {
      stop_tuning ();
    }

  if (m_auto)
    {
      auto_tx_mode (false);
    }

  m_btxok=false;
  m_repeatMsg=0;
}

void MainWindow::rigOpen ()
{
  ui->readFreq->setStyleSheet ("");
  ui->readFreq->setText ("");
  m_config.transceiver_online (true);
  Q_EMIT m_config.sync_transceiver (true);
  ui->readFreq->setStyleSheet("QPushButton{background-color: orange;"
                              "border-width: 0px; border-radius: 5px;}");
}

void MainWindow::on_pbR2T_clicked()
{
  if (ui->TxFreqSpinBox->isEnabled ())
    {
      ui->TxFreqSpinBox->setValue(ui->RxFreqSpinBox->value ());
    }
}

void MainWindow::on_pbT2R_clicked()
{
  if (ui->RxFreqSpinBox->isEnabled ())
    {
      ui->RxFreqSpinBox->setValue (ui->TxFreqSpinBox->value ());
    }
}


void MainWindow::on_readFreq_clicked()
{
  if (m_transmitting) return;

  if (m_config.transceiver_online (true))
    {
      Q_EMIT m_config.sync_transceiver (true);
    }
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
  m_XIT = 0;
  if (m_config.split_mode ())
    {
      m_XIT=(n/500)*500 - 1500;
    }

  if (m_monitoring || m_transmitting)
    {
      if (m_config.transceiver_online ())
        {
          if (m_config.split_mode ())
            {
              Q_EMIT m_config.transceiver_tx_frequency (m_dialFreq + m_XIT);
            }
        }
    }

  Q_EMIT transmitFrequency (ui->TxFreqSpinBox->value () - m_XIT);
}

void MainWindow::setFreq4(int rxFreq, int txFreq)
{
  if (ui->RxFreqSpinBox->isEnabled ())
    {
      ui->RxFreqSpinBox->setValue(rxFreq);
    }

  if (ui->TxFreqSpinBox->isEnabled ())
    {
      ui->TxFreqSpinBox->setValue(txFreq);
    }
}

void MainWindow::on_cbTxLock_clicked(bool checked)
{
  m_lockTxFreq=checked;
  m_wideGraph->setLockTxFreq(m_lockTxFreq);
  if(m_lockTxFreq) on_pbR2T_clicked();
}

void MainWindow::on_cbPlus2kHz_toggled(bool checked)
{
  // Upload any queued spots before changing band
  psk_Reporter->sendReport();

  m_plus2kHz = checked;

  auto f = m_dialFreq;

  if (m_plus2kHz)
    {
      f += 2000;
    }
  else
    {
      f -= 2000;
    }

  m_bandEdited = true;
  band_changed (f);
}

void MainWindow::handle_transceiver_update (Transceiver::TransceiverState s)
{

  transmitDisplay (false);

  if ((s.frequency () - m_dialFreq) || s.split () != m_splitMode)
    {
      m_splitMode = s.split ();
      qsy (s.frequency ());
    }

  ui->readFreq->setStyleSheet("QPushButton{background-color: #00ff00;"
                              "border-width: 0px; border-radius: 5px;}");
  ui->readFreq->setText (s.split () ? "S" : "");
}

void MainWindow::handle_transceiver_failure (QString reason)
{
  ui->readFreq->setStyleSheet("QPushButton{background-color: red;"
                              "border-width: 0px; border-radius: 5px;}");

  m_btxok=false;
  m_repeatMsg=0;

  rigFailure ("Rig Control Error", reason);
}

void MainWindow::rigFailure (QString const& reason, QString const& detail)
{
  static bool first_error {true};
  if (first_error)
    {
      // one automatic retry
      QTimer::singleShot (0, this, SLOT (rigOpen ()));
      first_error = false;
    }
  else
    {
      m_rigErrorMessageBox.setText (reason);
      m_rigErrorMessageBox.setDetailedText (detail);

      // don't call slot functions directly to avoid recursion
      switch (m_rigErrorMessageBox.exec ())
        {
        case QMessageBox::Ok:
          QTimer::singleShot (0, this, SLOT (on_actionSettings_triggered ()));
          break;

        case QMessageBox::Retry:
          QTimer::singleShot (0, this, SLOT (rigOpen ()));
          break;

        case QMessageBox::Cancel:
          QTimer::singleShot (0, this, SLOT (close ()));
          break;
        }
      first_error = true;       // reset
    }
}

void MainWindow::transmit (double snr)
{
  if (m_modeTx == "JT65")
    {
      Q_EMIT sendMessage (NUM_JT65_SYMBOLS, 4096.0 * 12000.0 / 11025.0, ui->TxFreqSpinBox->value () - m_XIT, m_toneSpacing, &m_soundOutput, m_config.audio_output_channel (), true, snr);
    }
  else
    {
      Q_EMIT sendMessage (NUM_JT9_SYMBOLS, m_nsps, ui->TxFreqSpinBox->value () - m_XIT, m_toneSpacing, &m_soundOutput, m_config.audio_output_channel (), true, snr);
    }
}

void MainWindow::on_outAttenuation_valueChanged (int a)
{
  qreal dBAttn (a / 10.);      // slider interpreted as hundredths of a dB
  ui->outAttenuation->setToolTip (tr ("Transmit digital gain ") + (a ? QString::number (-dBAttn, 'f', 1) : "0") + "dB");
  Q_EMIT outAttenuationChanged (dBAttn);
}

void MainWindow::on_actionShort_list_of_add_on_prefixes_and_suffixes_triggered()
{
  if (!m_prefixes)
    {
      QFile f(":/prefixes.txt");
      if(!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        msgBox("Cannot open \"" + f.fileName () + "\".");
        return;
      }
      m_prefixes.reset (new QTextEdit);
      m_prefixes->setReadOnly(true);
      m_prefixes->setFontPointSize(10);
      m_prefixes->setWindowTitle(QApplication::applicationName () + " - " + tr ("Prefixes"));
      m_prefixes->setGeometry(QRect(45,50,565,450));
      Qt::WindowFlags flags = Qt::WindowCloseButtonHint |
        Qt::WindowMinimizeButtonHint;
      m_prefixes->setWindowFlags(flags);
      QTextStream s(&f);
      QString t;
      for(int i=0; i<100; i++) {
        t=s.readLine();
        m_prefixes->append(t);
        if(s.atEnd()) break;
      }
    }
  m_prefixes->showNormal();
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

void MainWindow::pskSetLocal ()
{
  // find the station row, if any, that matches the band we are on
  auto stations = m_config.stations ();
  auto matches = stations->match (stations->index (0, 0)
                                  , Qt::DisplayRole
                                  , ui->bandComboBox->currentText ()
                                  , 1
                                  , Qt::MatchExactly);
  QString antenna_description;
  if (!matches.isEmpty ())
    {
      antenna_description = stations->index (matches.first ().row (), 2).data ().toString ();
    }
  psk_Reporter->setLocalStation(
                                m_config.my_callsign ()
                                , m_config.my_grid ()
                                , antenna_description, "WSJT-X " + m_revision);
}

void MainWindow::transmitDisplay (bool transmitting)
{

  if (transmitting == m_transmitting)
    {
      if (transmitting)
        {
          signalMeter->setValue(0);

          if (m_monitoring)
            {
              monitor (false);
            }

          m_btxok=true;
        }

      auto QSY_allowed = !transmitting || m_config.tx_QSY_allowed () || !m_config.split_mode ();
      if (ui->cbTxLock->isChecked ())
        {
          ui->RxFreqSpinBox->setEnabled (QSY_allowed);
          ui->pbT2R->setEnabled (QSY_allowed);
        }
      ui->TxFreqSpinBox->setEnabled (QSY_allowed);
      ui->pbR2T->setEnabled (QSY_allowed);
      ui->cbTxLock->setEnabled (QSY_allowed);

      // only allow +2kHz when not transmitting or if TX QSYs are allowed
      ui->cbPlus2kHz->setEnabled (!transmitting || m_config.tx_QSY_allowed ());

      // the following are always disallowed in transmit
      ui->menuMode->setEnabled (!transmitting);
      ui->bandComboBox->setEnabled (!transmitting);
      if (!transmitting)
        {
          if ("JT9+JT65" == m_mode)
            {
              // allow mode switch in Rx when in dual mode
              ui->pbTxMode->setEnabled (true);
            }
        }
      else
        {
          ui->pbTxMode->setEnabled (false);
        }
    }
}
