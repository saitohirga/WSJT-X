#include "devsetup.h"

#include "ui_devsetup.h"

#include <iterator>
#include <algorithm>
#include <tr1/functional>

#include <QDebug>
#include <QSettings>
#include <QAudioDeviceInfo>
#include <QAudioInput>
#include <QMap>

extern double dFreq[16];
qint32  g2_iptt;
qint32  g2_COMportOpen;

//----------------------------------------------------------- DevSetup()
DevSetup::DevSetup(QWidget *parent)
  : QDialog(parent)
  , ui (new Ui::DevSetup)
  , m_audioInputDevices (QAudioDeviceInfo::availableDevices (QAudio::AudioInput))
  , m_audioOutputDevices (QAudioDeviceInfo::availableDevices (QAudio::AudioOutput))
{
  ui->setupUi(this);	                              //setup the dialog form
  m_restartSoundIn=false;
  m_restartSoundOut=false;
  m_firstCall=true;
  g2_iptt=0;
  m_test=0;
  m_bRigOpen=false;
  g2_COMportOpen=0;
}

DevSetup::~DevSetup()
{
}

void DevSetup::initDlg()
{
  QString m_appDir = QApplication::applicationDirPath();
  QString inifile = m_appDir + "/wsjtx.ini";
  QSettings settings(inifile, QSettings::IniFormat);
  settings.beginGroup("Common");
  QString catPortDriver = settings.value("CATdriver","None").toString();
  settings.endGroup();

  //
  // load combo boxes with audio setup choices
  //
  loadAudioDevices (m_audioInputDevices, ui->comboBoxSndIn);
  loadAudioDevices (m_audioOutputDevices, ui->comboBoxSndOut);

  {
    using namespace std::tr1;
    using namespace std::tr1::placeholders;

    function<void (int)> cb (bind (&DevSetup::updateAudioChannels, this, ui->comboBoxSndIn, _1, ui->audioInputChannel, false));
    connect (ui->comboBoxSndIn, static_cast<void (QComboBox::*)(int)> (&QComboBox::currentIndexChanged), cb);
    cb = bind (&DevSetup::updateAudioChannels, this, ui->comboBoxSndOut, _1, ui->audioOutputChannel, true);
    connect (ui->comboBoxSndOut, static_cast<void (QComboBox::*)(int)> (&QComboBox::currentIndexChanged), cb);

    updateAudioChannels (ui->comboBoxSndIn, ui->comboBoxSndIn->currentIndex (), ui->audioInputChannel, false);
    updateAudioChannels (ui->comboBoxSndOut, ui->comboBoxSndOut->currentIndex (), ui->audioOutputChannel, true);

    ui->audioInputChannel->setCurrentIndex (m_audioInputChannel);
    ui->audioOutputChannel->setCurrentIndex (m_audioOutputChannel);
  }

  enumerateRigs ();

  QPalette pal(ui->myCallEntry->palette());
  if(m_myCall=="") {
    pal.setColor(QPalette::Base,"#ffccff");
  } else {
    pal.setColor(QPalette::Base,Qt::white);
  }
  ui->myCallEntry->setPalette(pal);
  ui->myGridEntry->setPalette(pal);
  ui->myCallEntry->setText(m_myCall);
  ui->myGridEntry->setText(m_myGrid);

  ui->idIntSpinBox->setValue(m_idInt);
  ui->pttMethodComboBox->setCurrentIndex(m_pttMethodIndex);
  ui->saveDirEntry->setText(m_saveDir);
  ui->cbID73->setChecked(m_After73);
  ui->cbPSKReporter->setChecked(m_pskReporter);
  ui->cbSplit->setChecked(m_bSplit and m_catEnabled);
  ui->cbXIT->setChecked(m_bXIT);
  ui->cbXIT->setVisible(false);

  enableWidgets();

  ui->catPortComboBox->setCurrentIndex(m_catPortIndex);
  ui->serialRateComboBox->setCurrentIndex(m_serialRateIndex);
  ui->dataBitsComboBox->setCurrentIndex(m_dataBitsIndex);
  ui->stopBitsComboBox->setCurrentIndex(m_stopBitsIndex);
  ui->handshakeComboBox->setCurrentIndex(m_handshakeIndex);
  ui->rbData->setChecked(m_pttData);
  ui->pollSpinBox->setValue(m_poll);

  // PY2SDR -- Per OS serial port names
  m_tmp=m_pttPort;
  ui->pttComboBox->clear();
  ui->catPortComboBox->clear();
  ui->pttComboBox->addItem("None");
  ui->catPortComboBox->addItem("None");
#ifdef WIN32
  for ( int i = 1; i < 100; i++ ) {
    ui->pttComboBox->addItem("COM" + QString::number(i));
    ui->catPortComboBox->addItem("COM" + QString::number(i));
  }
  ui->pttComboBox->addItem("USB");
  ui->catPortComboBox->addItem("USB");
#else
  ui->catPortComboBox->addItem("/dev/ttyS0");
  ui->catPortComboBox->addItem("/dev/ttyS1");
  ui->catPortComboBox->addItem("/dev/ttyS2");
  ui->catPortComboBox->addItem("/dev/ttyS3");
  ui->catPortComboBox->addItem("/dev/ttyS4");
  ui->catPortComboBox->addItem("/dev/ttyS5");
  ui->catPortComboBox->addItem("/dev/ttyS6");
  ui->catPortComboBox->addItem("/dev/ttyS7");
  ui->catPortComboBox->addItem("/dev/ttyUSB0");
  ui->catPortComboBox->addItem("/dev/ttyUSB1");
  ui->catPortComboBox->addItem("/dev/ttyUSB2");
  ui->catPortComboBox->addItem("/dev/ttyUSB3");
  ui->catPortComboBox->addItem(catPortDriver);

  ui->pttComboBox->addItem("/dev/ttyS0");
  ui->pttComboBox->addItem("/dev/ttyS1");
  ui->pttComboBox->addItem("/dev/ttyS2");
  ui->pttComboBox->addItem("/dev/ttyS3");
  ui->pttComboBox->addItem("/dev/ttyS4");
  ui->pttComboBox->addItem("/dev/ttyS5");
  ui->pttComboBox->addItem("/dev/ttyS6");
  ui->pttComboBox->addItem("/dev/ttyS7");
  ui->pttComboBox->addItem("/dev/ttyUSB0");
  ui->pttComboBox->addItem("/dev/ttyUSB1");
  ui->pttComboBox->addItem("/dev/ttyUSB2");
  ui->pttComboBox->addItem("/dev/ttyUSB3");
#endif
  ui->pttComboBox->setCurrentIndex(m_tmp);
  ui->catPortComboBox->setCurrentIndex(m_catPortIndex);

  int n=m_macro.length();
  if(n>=1) ui->macro1->setText(m_macro[0].toUpper());
  if(n>=2) ui->macro2->setText(m_macro[1].toUpper());
  if(n>=3) ui->macro3->setText(m_macro[2].toUpper());
  if(n>=4) ui->macro4->setText(m_macro[3].toUpper());
  if(n>=5) ui->macro5->setText(m_macro[4].toUpper());
  if(n>=6) ui->macro6->setText(m_macro[5].toUpper());
  if(n>=7) ui->macro7->setText(m_macro[6].toUpper());
  if(n>=8) ui->macro8->setText(m_macro[7].toUpper());
  if(n>=8) ui->macro9->setText(m_macro[8].toUpper());
  if(n>=10) ui->macro10->setText(m_macro[9].toUpper());

  ui->f1->setText(m_dFreq[0]);
  ui->f2->setText(m_dFreq[1]);
  ui->f3->setText(m_dFreq[2]);
  ui->f4->setText(m_dFreq[3]);
  ui->f5->setText(m_dFreq[4]);
  ui->f6->setText(m_dFreq[5]);
  ui->f7->setText(m_dFreq[6]);
  ui->f8->setText(m_dFreq[7]);
  ui->f9->setText(m_dFreq[8]);
  ui->f10->setText(m_dFreq[9]);
  ui->f11->setText(m_dFreq[10]);
  ui->f12->setText(m_dFreq[11]);
  ui->f13->setText(m_dFreq[12]);
  ui->f14->setText(m_dFreq[13]);
  ui->f15->setText(m_dFreq[14]);
  ui->f16->setText(m_dFreq[15]);

  ui->AntDescription1->setText(m_antDescription[0]);
  ui->AntDescription2->setText(m_antDescription[1]);
  ui->AntDescription3->setText(m_antDescription[2]);
  ui->AntDescription4->setText(m_antDescription[3]);
  ui->AntDescription5->setText(m_antDescription[4]);
  ui->AntDescription6->setText(m_antDescription[5]);
  ui->AntDescription7->setText(m_antDescription[6]);
  ui->AntDescription8->setText(m_antDescription[7]);
  ui->AntDescription9->setText(m_antDescription[8]);
  ui->AntDescription10->setText(m_antDescription[9]);
  ui->AntDescription11->setText(m_antDescription[10]);
  ui->AntDescription12->setText(m_antDescription[11]);
  ui->AntDescription13->setText(m_antDescription[12]);
  ui->AntDescription14->setText(m_antDescription[13]);
  ui->AntDescription15->setText(m_antDescription[14]);
  ui->AntDescription16->setText(m_antDescription[15]);

  ui->Band1->setText(m_bandDescription[0]);
  ui->Band2->setText(m_bandDescription[1]);
  ui->Band3->setText(m_bandDescription[2]);
  ui->Band4->setText(m_bandDescription[3]);
  ui->Band5->setText(m_bandDescription[4]);
  ui->Band6->setText(m_bandDescription[5]);
  ui->Band7->setText(m_bandDescription[6]);
  ui->Band8->setText(m_bandDescription[7]);
  ui->Band9->setText(m_bandDescription[8]);
  ui->Band10->setText(m_bandDescription[9]);
  ui->Band11->setText(m_bandDescription[10]);
  ui->Band12->setText(m_bandDescription[11]);
  ui->Band13->setText(m_bandDescription[12]);
  ui->Band14->setText(m_bandDescription[13]);
  ui->Band15->setText(m_bandDescription[14]);
  ui->Band16->setText(m_bandDescription[15]);

}

//------------------------------------------------------- accept()
void DevSetup::accept()
{
  // Called when OK button is clicked.
  // Check to see whether SoundInThread must be restarted,
  // and save user parameters.

  m_restartSoundIn = m_restartSoundOut = false;

  if (m_audioInputDevice != m_audioInputDevices[ui->comboBoxSndIn->currentIndex ()])
    {
      m_audioInputDevice = m_audioInputDevices[ui->comboBoxSndIn->currentIndex ()];
      m_restartSoundIn = true;
    }

  if (m_audioOutputDevice != m_audioOutputDevices[ui->comboBoxSndOut->currentIndex ()])
    {
      m_audioOutputDevice = m_audioOutputDevices[ui->comboBoxSndOut->currentIndex ()];
      m_restartSoundOut = true;
    }

  if (m_audioInputChannel != static_cast<AudioDevice::Channel> (ui->audioInputChannel->currentIndex ()))
    {
      m_audioInputChannel = static_cast<AudioDevice::Channel> (ui->audioInputChannel->currentIndex ());
      m_restartSoundIn = true;
    }
  Q_ASSERT (m_audioInputChannel <= AudioDevice::Right);

  if (m_audioOutputChannel != static_cast<AudioDevice::Channel> (ui->audioOutputChannel->currentIndex ()))
    {
      m_audioOutputChannel = static_cast<AudioDevice::Channel> (ui->audioOutputChannel->currentIndex ());
      m_restartSoundOut = true;
    }
  Q_ASSERT (m_audioOutputChannel <= AudioDevice::Both);

  m_myCall=ui->myCallEntry->text();
  m_myGrid=ui->myGridEntry->text();
  m_idInt=ui->idIntSpinBox->value();
  m_pttMethodIndex=ui->pttMethodComboBox->currentIndex();
  m_pttPort=ui->pttComboBox->currentIndex();
  m_saveDir=ui->saveDirEntry->text();

  m_macro.clear();
  m_macro.append(ui->macro1->text());
  m_macro.append(ui->macro2->text());
  m_macro.append(ui->macro3->text());
  m_macro.append(ui->macro4->text());
  m_macro.append(ui->macro5->text());
  m_macro.append(ui->macro6->text());
  m_macro.append(ui->macro7->text());
  m_macro.append(ui->macro8->text());
  m_macro.append(ui->macro9->text());
  m_macro.append(ui->macro10->text());

  m_dFreq.clear();
  m_dFreq.append(ui->f1->text());
  m_dFreq.append(ui->f2->text());
  m_dFreq.append(ui->f3->text());
  m_dFreq.append(ui->f4->text());
  m_dFreq.append(ui->f5->text());
  m_dFreq.append(ui->f6->text());
  m_dFreq.append(ui->f7->text());
  m_dFreq.append(ui->f8->text());
  m_dFreq.append(ui->f9->text());
  m_dFreq.append(ui->f10->text());
  m_dFreq.append(ui->f11->text());
  m_dFreq.append(ui->f12->text());
  m_dFreq.append(ui->f13->text());
  m_dFreq.append(ui->f14->text());
  m_dFreq.append(ui->f15->text());
  m_dFreq.append(ui->f16->text());

  m_antDescription.clear();
  m_antDescription.append(ui->AntDescription1->text());
  m_antDescription.append(ui->AntDescription2->text());
  m_antDescription.append(ui->AntDescription3->text());
  m_antDescription.append(ui->AntDescription4->text());
  m_antDescription.append(ui->AntDescription5->text());
  m_antDescription.append(ui->AntDescription6->text());
  m_antDescription.append(ui->AntDescription7->text());
  m_antDescription.append(ui->AntDescription8->text());
  m_antDescription.append(ui->AntDescription9->text());
  m_antDescription.append(ui->AntDescription10->text());
  m_antDescription.append(ui->AntDescription11->text());
  m_antDescription.append(ui->AntDescription12->text());
  m_antDescription.append(ui->AntDescription13->text());
  m_antDescription.append(ui->AntDescription14->text());
  m_antDescription.append(ui->AntDescription15->text());
  m_antDescription.append(ui->AntDescription16->text());

  m_bandDescription.clear();
  m_bandDescription.append(ui->Band1->text());
  m_bandDescription.append(ui->Band2->text());
  m_bandDescription.append(ui->Band3->text());
  m_bandDescription.append(ui->Band4->text());
  m_bandDescription.append(ui->Band5->text());
  m_bandDescription.append(ui->Band6->text());
  m_bandDescription.append(ui->Band7->text());
  m_bandDescription.append(ui->Band8->text());
  m_bandDescription.append(ui->Band9->text());
  m_bandDescription.append(ui->Band10->text());
  m_bandDescription.append(ui->Band11->text());
  m_bandDescription.append(ui->Band12->text());
  m_bandDescription.append(ui->Band13->text());
  m_bandDescription.append(ui->Band14->text());
  m_bandDescription.append(ui->Band15->text());
  m_bandDescription.append(ui->Band16->text());


  if(m_bRigOpen) {
    rig->close();
    if(m_rig<9900) delete rig;
    m_bRigOpen=false;
  }

  QDialog::accept();
}

//------------------------------------------------------- reject()
void DevSetup::reject()
{
  if(m_bRigOpen) rig->close();
  QDialog::reject();
}

void DevSetup::msgBox(QString t)                             //msgBox
{
  msgBox0.setText(t);
  msgBox0.exec();
}

void DevSetup::on_myCallEntry_editingFinished()
{
  QString t=ui->myCallEntry->text();
  ui->myCallEntry->setText(t.toUpper());
}

void DevSetup::on_myGridEntry_editingFinished()
{
  QString t=ui->myGridEntry->text();
  t=t.mid(0,4).toUpper()+t.mid(4,2).toLower();
  ui->myGridEntry->setText(t);
}

void DevSetup::setEnableAntennaDescriptions(bool enable)
{
    ui->AntDescription1->setEnabled(enable);
    ui->AntDescription2->setEnabled(enable);
    ui->AntDescription3->setEnabled(enable);
    ui->AntDescription4->setEnabled(enable);
    ui->AntDescription5->setEnabled(enable);
    ui->AntDescription6->setEnabled(enable);
    ui->AntDescription7->setEnabled(enable);
    ui->AntDescription8->setEnabled(enable);
    ui->AntDescription9->setEnabled(enable);
    ui->AntDescription10->setEnabled(enable);
    ui->AntDescription11->setEnabled(enable);
    ui->AntDescription12->setEnabled(enable);
    ui->AntDescription13->setEnabled(enable);
    ui->AntDescription14->setEnabled(enable);
    ui->AntDescription15->setEnabled(enable);
    ui->AntDescription16->setEnabled(enable);
    if (enable)
        ui->AntDescriptionColumnLabel->setText("Antenna description");
    else
        ui->AntDescriptionColumnLabel->setText("Antenna description (enable PSK Reporter)");
}

void DevSetup::on_cbPSKReporter_clicked(bool b)
{
  m_pskReporter=b;
  setEnableAntennaDescriptions(m_pskReporter);
}

void DevSetup::on_pttMethodComboBox_activated(int index)
{
  m_pttMethodIndex=index;
  enableWidgets();
}

void DevSetup::on_catPortComboBox_activated(int index)
{
  m_catPortIndex=index;
  m_catPort=ui->catPortComboBox->itemText(index);
}

void DevSetup::on_cbEnableCAT_toggled(bool b)
{
  m_catEnabled=b;
  enableWidgets();
  ui->cbSplit->setChecked(m_bSplit and m_catEnabled);
}

void DevSetup::on_serialRateComboBox_activated(int index)
{
  m_serialRateIndex=index;
  m_serialRate=ui->serialRateComboBox->itemText(index).toInt();
}

void DevSetup::on_handshakeComboBox_activated(int index)
{
  m_handshakeIndex=index;
  m_handshake=ui->handshakeComboBox->itemText(index);
}

void DevSetup::on_handshakeComboBox_currentIndexChanged(int index)
{
  ui->RTSCheckBox->setEnabled(index != 2);
}

void DevSetup::on_dataBitsComboBox_activated(int index)
{
  m_dataBitsIndex=index;
  m_dataBits=ui->dataBitsComboBox->itemText(index).toInt();
}

void DevSetup::on_stopBitsComboBox_activated(int index)
{
  m_stopBitsIndex=index;
  m_stopBits=ui->stopBitsComboBox->itemText(index).toInt();
}

void DevSetup::on_rigComboBox_activated(int index)
{
  m_rig = ui->rigComboBox->itemData (index).toInt ();
  enableWidgets();
}

void DevSetup::on_cbID73_toggled(bool checked)
{
  m_After73=checked;
}

void DevSetup::on_testCATButton_clicked()
{
  openRig();
  if(!m_catEnabled) return;
  QString t;
  double fMHz=rig->getFreq(RIG_VFO_CURR)/1000000.0;
  if(fMHz>0.0) {
    t.sprintf("Rig control appears to be working.\nDial Frequency:  %.6f MHz",
              fMHz);
  } else {
    t.sprintf("Rig control error %d\nFailed to read frequency.",
              int(1000000.0*fMHz));
    if(m_poll>0) {
      m_catEnabled=false;
      ui->cbEnableCAT->setChecked(false);
    }
  }
  msgBox(t);
}

void DevSetup::openRig()
{
  QString t;
  int ret;

  if(!m_catEnabled) return;
  if(m_bRigOpen) {
    rig->close();
    if(m_rig<9900) delete rig;
    m_bRigOpen=false;
  }

  rig = new Rig();

  if(m_rig<9900) {
    if (!rig->init(m_rig)) {
      msgBox("Rig init failure");
      m_catEnabled=false;
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
    rig->setConf("dtr_state",m_bDTR ? "ON" : "OFF");
    if(ui->RTSCheckBox->isEnabled()) {
      rig->setConf("rts_state",m_bRTS ? "ON" : "OFF");
    }
  }

  ret=rig->open(m_rig);
  if(ret==RIG_OK) {
    m_bRigOpen=true;
  } else {
    t="Open rig failed";
    msgBox(t);
    m_catEnabled=false;
    ui->cbEnableCAT->setChecked(false);
    return;
  }
}

void DevSetup::on_testPTTButton_clicked()
{
  m_test=1-m_test;
  if(m_pttMethodIndex==1 or m_pttMethodIndex==2) {
    ptt(m_pttPort,m_test,&g2_iptt,&g2_COMportOpen);
  }
  if(m_pttMethodIndex==0 and !m_bRigOpen) {
//    on_testCATButton_clicked();
    openRig();
  }
  if(m_pttMethodIndex==0 and m_bRigOpen) {
    if(m_test==0) rig->setPTT(RIG_PTT_OFF, RIG_VFO_CURR);
    if(m_test==1) {
      if(m_pttData) rig->setPTT(RIG_PTT_ON_DATA, RIG_VFO_CURR);
      if(!m_pttData) rig->setPTT(RIG_PTT_ON_MIC, RIG_VFO_CURR);
    }
  }
}

void DevSetup::on_DTRCheckBox_toggled(bool checked)
{
  m_bDTR=checked;
}

void DevSetup::on_RTSCheckBox_toggled(bool checked)
{
  m_bRTS=checked;
}

void DevSetup::on_rbData_toggled(bool checked)
{
  m_pttData=checked;
}

void DevSetup::on_pollSpinBox_valueChanged(int n)
{
  m_poll=n;
}

void DevSetup::on_pttComboBox_currentIndexChanged(int index)
{
  m_pttPort=index;
  enableWidgets();
}

void DevSetup::on_pttMethodComboBox_currentIndexChanged(int index)
{
  m_pttMethodIndex=index;
  bool b=m_pttMethodIndex==1 or m_pttMethodIndex==2;
  ui->pttComboBox->setEnabled(b);
}

void DevSetup::enableWidgets()
{
  ui->cbEnableCAT->setChecked(m_catEnabled);
  ui->rigComboBox->setEnabled(m_catEnabled);
  ui->testCATButton->setEnabled(m_catEnabled);
  ui->label_4->setEnabled(m_catEnabled);
  ui->label_47->setEnabled(m_catEnabled);
  ui->cbSplit->setEnabled(m_catEnabled);
  if(m_rig==9999) {                    //No Split Tx with HRD
    ui->cbSplit->setChecked(false);
    ui->cbSplit->setEnabled(false);
  }
  ui->cbXIT->setEnabled(m_catEnabled);

  bool bSerial=m_catEnabled and (m_rig<9900);
  ui->catPortComboBox->setEnabled(bSerial);
  ui->serialRateComboBox->setEnabled(bSerial);
  ui->dataBitsComboBox->setEnabled(bSerial);
  ui->stopBitsComboBox->setEnabled(bSerial);
  ui->handshakeComboBox->setEnabled(bSerial);
  ui->DTRCheckBox->setEnabled(bSerial);
  ui->DTRCheckBox->setChecked(m_bDTR);
  ui->RTSCheckBox->setEnabled(bSerial && m_handshakeIndex != 2);
  ui->RTSCheckBox->setChecked(m_bRTS);
  ui->rbData->setEnabled(bSerial);
  ui->rbMic->setEnabled(bSerial);
  ui->label_21->setEnabled(bSerial);
  ui->label_22->setEnabled(bSerial);
  ui->label_23->setEnabled(bSerial);
  ui->label_24->setEnabled(bSerial);
  ui->label_25->setEnabled(bSerial);

  ui->pollSpinBox->setEnabled(m_catEnabled);
  bool b1=(m_pttMethodIndex==1 or m_pttMethodIndex==2);
  ui->pttComboBox->setEnabled(b1);
  b1=b1 and (m_pttPort!=0);
  bool b2 = (m_catEnabled and m_pttMethodIndex==1 and m_rig<9900) or
            (m_catEnabled and m_pttMethodIndex==2 and m_rig<9900);
  bool b3 = (m_catEnabled and m_pttMethodIndex==0);
  ui->testPTTButton->setEnabled(b1 or b2 or b3);  //Include PTT via HRD or Commander
  setEnableAntennaDescriptions(m_pskReporter);
}

void DevSetup::on_cbSplit_toggled(bool checked)
{
  m_bSplit=checked;
  if(m_bSplit and m_bXIT) ui->cbXIT->setChecked(false);
}

void DevSetup::on_cbXIT_toggled(bool checked)
{
  m_bXIT=checked;
  if(m_bSplit and m_bXIT) ui->cbSplit->setChecked(false);
}

void DevSetup::loadAudioDevices (AudioDevices const& d, QComboBox * cb)
{
  using std::copy;
  using std::back_inserter;

  int currentIndex = -1;
  int defaultIndex = 0;
  for (AudioDevices::const_iterator p = d.cbegin (); p != d.cend (); ++p)
    {
      // convert supported channel counts into something we can store in the item model
      QList<QVariant> channelCounts;
      QList<int> scc (p->supportedChannelCounts ());
      copy (scc.cbegin (), scc.cend (), back_inserter (channelCounts));

      cb->addItem (p->deviceName (), channelCounts);
      if (*p == m_audioInputDevice)
	{
	  currentIndex = p - d.cbegin ();
	}
      else if (*p == QAudioDeviceInfo::defaultInputDevice ())
	{
	  defaultIndex = p - d.cbegin ();
	}
    }
  cb->setCurrentIndex (currentIndex != -1 ? currentIndex : defaultIndex);
}

void DevSetup::updateAudioChannels (QComboBox const * srcCb, int index, QComboBox * cb, bool allowBoth)
{
  // disable all items
  for (int i (0); i < cb->count (); ++i)
    {
      cb->setItemData (i, 0, Qt::UserRole - 1); // undocumented model internals allows disable
    }

  Q_FOREACH (QVariant const& v, srcCb->itemData (index).toList ())
    {
      // enable valid options
      int n (v.toInt ());
      if (2 == n)
	{
	  cb->setItemData (AudioDevice::Left, 32 | 1, Qt::UserRole - 1); // undocumented model internals allows enable
	  cb->setItemData (AudioDevice::Right, 32 | 1, Qt::UserRole - 1);
	  if (allowBoth)
	    {
	      cb->setItemData (AudioDevice::Both, 32 | 1, Qt::UserRole - 1);
	    }
	}
      else if (1 == n)
	{
	  cb->setItemData (AudioDevice::Mono, 32 | 1, Qt::UserRole - 1);
	}
    }
}

typedef QMap<QString, int> RigList;

int rigCallback (rig_caps const * caps, void * cbData)
{
  RigList * rigs = reinterpret_cast<RigList *> (cbData);

  QString key (QString::fromLatin1 (caps->mfg_name).trimmed ()
	       + ' '+ QString::fromLatin1 (caps->model_name).trimmed ()
	       // + ' '+ QString::fromLatin1 (caps->version).trimmed ()
	       // + " (" + QString::fromLatin1 (rig_strstatus (caps->status)).trimmed () + ')'
	       );

  (*rigs)[key] = caps->rig_model;

  return 1;			// keep them coming
}

void DevSetup::enumerateRigs ()
{
  RigList rigs;
  rig_load_all_backends ();
  rig_list_foreach (rigCallback, &rigs);

  for (RigList::const_iterator r = rigs.cbegin (); r != rigs.cend (); ++r)
    {
      ui->rigComboBox->addItem (r.key (), r.value ());
    }

  ui->rigComboBox->addItem ("DX Lab Suite Commander", 9998);
  ui->rigComboBox->addItem ("Ham Radio Deluxe", 9999);
  ui->rigComboBox->setCurrentIndex (ui->rigComboBox->findData (m_rig));
}
