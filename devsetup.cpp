#include "devsetup.h"
#include <QDebug>
#include <portaudio.h>

#define MAXDEVICES 100

extern double dFreq[16];

//----------------------------------------------------------- DevSetup()
DevSetup::DevSetup(QWidget *parent) :	QDialog(parent)
{
  ui.setupUi(this);	                              //setup the dialog form
  m_restartSoundIn=false;
  m_restartSoundOut=false;
  m_firstCall=true;
  m_iptt=0;
  m_test=0;
  m_bRigOpen=false;
  m_COMportOpen=0;
}

DevSetup::~DevSetup()
{
}

void DevSetup::initDlg()
{
  int k,id;
  int numDevices=Pa_GetDeviceCount();

  const PaDeviceInfo *pdi;
  int nchin;
  int nchout;
  char *p,*p1;
  char p2[50];
  char pa_device_name[128];
  char pa_device_hostapi[128];

  /*
  if(m_firstCall) {
    QString t;
    for(int i=14; i<100; i++) {
      t.sprintf("COM%d",i);
      ui.pttComboBox->addItem(t);
    }
    for(int i=0; i<10; i++) {
      m_macro.append("");
    }
    m_firstCall=false;
  }
*/
  k=0;
  for(id=0; id<numDevices; id++ )  {
    pdi=Pa_GetDeviceInfo(id);
    nchin=pdi->maxInputChannels;
    if(nchin>0) {
      m_inDevList[k]=id;
      k++;
      sprintf((char*)(pa_device_name),"%s",pdi->name);
      sprintf((char*)(pa_device_hostapi),"%s",
              Pa_GetHostApiInfo(pdi->hostApi)->name);

#ifdef WIN32
      p1=(char*)"";
      p=strstr(pa_device_hostapi,"MME");
      if(p!=NULL) p1=(char*)"MME";
      p=strstr(pa_device_hostapi,"Direct");
      if(p!=NULL) p1=(char*)"DirectX";
      p=strstr(pa_device_hostapi,"WASAPI");
      if(p!=NULL) p1=(char*)"WASAPI";
      p=strstr(pa_device_hostapi,"ASIO");
      if(p!=NULL) p1=(char*)"ASIO";
      p=strstr(pa_device_hostapi,"WDM-KS");
      if(p!=NULL) p1=(char*)"WDM-KS";

      sprintf(p2,"%2d   %d   %-8s  %-39s",id,nchin,p1,pa_device_name);
      QString t(p2);
#else
      QString t;
      t.sprintf("%2d   %d   %-8s  %-39s",id,nchin,p1,pdi->name);
#endif
      ui.comboBoxSndIn->addItem(t);
    }
  }

  k=0;
  for(id=0; id<numDevices; id++ )  {
    pdi=Pa_GetDeviceInfo(id);
    nchout=pdi->maxOutputChannels;
    if(nchout>0) {
      m_outDevList[k]=id;
      k++;
      sprintf((char*)(pa_device_name),"%s",pdi->name);
      sprintf((char*)(pa_device_hostapi),"%s",
              Pa_GetHostApiInfo(pdi->hostApi)->name);

#ifdef WIN32
// Needs work to compile for Linux
      p1=(char*)"";
      p=strstr(pa_device_hostapi,"MME");

      if(p!=NULL) p1=(char*)"MME";
      p=strstr(pa_device_hostapi,"Direct");
      if(p!=NULL) p1=(char*)"DirectX";
      p=strstr(pa_device_hostapi,"WASAPI");
      if(p!=NULL) p1=(char*)"WASAPI";
      p=strstr(pa_device_hostapi,"ASIO");
      if(p!=NULL) p1=(char*)"ASIO";
      p=strstr(pa_device_hostapi,"WDM-KS");
      if(p!=NULL) p1=(char*)"WDM-KS";
      sprintf(p2,"%2d   %d   %-8s  %-39s",id,nchout,p1,pa_device_name);
      QString t(p2);
#else
      QString t;
      t.sprintf("%2d   %d   %-8s  %-39s",id,nchin,p1,pdi->name);
#endif
      ui.comboBoxSndOut->addItem(t);
    }
  }

  connect(&p4, SIGNAL(readyReadStandardOutput()),
                    this, SLOT(p4ReadFromStdout()));
  connect(&p4, SIGNAL(readyReadStandardError()),
          this, SLOT(p4ReadFromStderr()));
  connect(&p4, SIGNAL(error(QProcess::ProcessError)),
          this, SLOT(p4Error()));
  p4.start("rigctl -l");
  p4.waitForFinished(1000);
  ui.rigComboBox->addItem("  9999 Ham Radio Deluxe");

  QPalette pal(ui.myCallEntry->palette());
  if(m_myCall=="") {
    pal.setColor(QPalette::Base,"#ffccff");
  } else {
    pal.setColor(QPalette::Base,Qt::white);
  }
  ui.myCallEntry->setPalette(pal);
  ui.myGridEntry->setPalette(pal);
  ui.myCallEntry->setText(m_myCall);
  ui.myGridEntry->setText(m_myGrid);

  ui.idIntSpinBox->setValue(m_idInt);
  ui.pttMethodComboBox->setCurrentIndex(m_pttMethodIndex);
  ui.saveDirEntry->setText(m_saveDir);
  ui.comboBoxSndIn->setCurrentIndex(m_nDevIn);
  ui.comboBoxSndOut->setCurrentIndex(m_nDevOut);
  ui.cbID73->setChecked(m_After73);
  ui.cbPSKReporter->setChecked(m_pskReporter);
  m_paInDevice=m_inDevList[m_nDevIn];
  m_paOutDevice=m_outDevList[m_nDevOut];
  ui.cbEnableCAT->setChecked(m_catEnabled);
  ui.cbDTRoff->setChecked(m_bDTRoff);
  ui.catPortComboBox->setEnabled(m_catEnabled);
  ui.rigComboBox->setEnabled(m_catEnabled);
  ui.serialRateComboBox->setEnabled(m_catEnabled);
  ui.dataBitsComboBox->setEnabled(m_catEnabled);
  ui.stopBitsComboBox->setEnabled(m_catEnabled);
  ui.handshakeComboBox->setEnabled(m_catEnabled);
  ui.testCATButton->setEnabled(m_catEnabled);
  ui.cbDTRoff->setEnabled(m_catEnabled);
  ui.rbData->setEnabled(m_catEnabled);
  ui.rbMic->setEnabled(m_catEnabled);
  ui.pollSpinBox->setEnabled(m_catEnabled);
  bool b=m_pttMethodIndex==1 or m_pttMethodIndex==2;
  ui.pttComboBox->setEnabled(b);
  b=b or m_catEnabled;
  ui.testPTTButton->setEnabled(b);
  ui.rigComboBox->setCurrentIndex(m_rigIndex);
  ui.catPortComboBox->setCurrentIndex(m_catPortIndex);
  ui.serialRateComboBox->setCurrentIndex(m_serialRateIndex);
  ui.dataBitsComboBox->setCurrentIndex(m_dataBitsIndex);
  ui.stopBitsComboBox->setCurrentIndex(m_stopBitsIndex);
  ui.handshakeComboBox->setCurrentIndex(m_handshakeIndex);
  ui.rbData->setChecked(m_pttData);
  ui.pollSpinBox->setValue(m_poll);

  // PY2SDR -- Per OS serial port names
  m_tmp=m_pttPort;
  ui.pttComboBox->clear();
  ui.catPortComboBox->clear();
  ui.pttComboBox->addItem("None");
  ui.catPortComboBox->addItem("None");
#ifdef WIN32
  for ( int i = 1; i < 100; i++ ) {
    ui.pttComboBox->addItem("COM" + QString::number(i));
    ui.catPortComboBox->addItem("COM" + QString::number(i));
  }
  ui.pttComboBox->addItem("USB");
  ui.catPortComboBox->addItem("USB");
#else
  ui.catPortComboBox->addItem("/dev/ttyS0");
  ui.catPortComboBox->addItem("/dev/ttyS1");
  ui.catPortComboBox->addItem("/dev/ttyS2");
  ui.catPortComboBox->addItem("/dev/ttyS3");
  ui.catPortComboBox->addItem("/dev/ttyUSB0");
  ui.catPortComboBox->addItem("/dev/ttyUSB1");
  ui.catPortComboBox->addItem("/dev/ttyUSB2");
  ui.catPortComboBox->addItem("/dev/ttyUSB3");

  ui.pttComboBox->addItem("/dev/ttyS0");
  ui.pttComboBox->addItem("/dev/ttyS1");
  ui.pttComboBox->addItem("/dev/ttyS2");
  ui.pttComboBox->addItem("/dev/ttyS3");
  ui.pttComboBox->addItem("/dev/ttyUSB0");
  ui.pttComboBox->addItem("/dev/ttyUSB1");
  ui.pttComboBox->addItem("/dev/ttyUSB2");
  ui.pttComboBox->addItem("/dev/ttyUSB3");
#endif
  ui.pttComboBox->setCurrentIndex(m_tmp);
  ui.catPortComboBox->setCurrentIndex(m_catPortIndex);

  ui.macro1->setText(m_macro[0].toUpper());
  ui.macro2->setText(m_macro[1].toUpper());
  ui.macro3->setText(m_macro[2].toUpper());
  ui.macro4->setText(m_macro[3].toUpper());
  ui.macro5->setText(m_macro[4].toUpper());
  ui.macro6->setText(m_macro[5].toUpper());
  ui.macro7->setText(m_macro[6].toUpper());
  ui.macro8->setText(m_macro[7].toUpper());
  ui.macro9->setText(m_macro[8].toUpper());
  ui.macro10->setText(m_macro[9].toUpper());

  ui.f1->setText(m_dFreq[0]);
  ui.f2->setText(m_dFreq[1]);
  ui.f3->setText(m_dFreq[2]);
  ui.f4->setText(m_dFreq[3]);
  ui.f5->setText(m_dFreq[4]);
  ui.f6->setText(m_dFreq[5]);
  ui.f7->setText(m_dFreq[6]);
  ui.f8->setText(m_dFreq[7]);
  ui.f9->setText(m_dFreq[8]);
  ui.f10->setText(m_dFreq[9]);
  ui.f11->setText(m_dFreq[10]);
  ui.f12->setText(m_dFreq[11]);
  ui.f13->setText(m_dFreq[12]);
  ui.f14->setText(m_dFreq[13]);
  ui.f15->setText(m_dFreq[14]);
  ui.f16->setText(m_dFreq[15]);
}

//------------------------------------------------------- accept()
void DevSetup::accept()
{
  // Called when OK button is clicked.
  // Check to see whether SoundInThread must be restarted,
  // and save user parameters.

  if(m_nDevIn!=ui.comboBoxSndIn->currentIndex() or
     m_paInDevice!=m_inDevList[m_nDevIn]) m_restartSoundIn=true;

  if(m_nDevOut!=ui.comboBoxSndOut->currentIndex() or
     m_paOutDevice!=m_outDevList[m_nDevOut]) m_restartSoundOut=true;

  m_myCall=ui.myCallEntry->text();
  m_myGrid=ui.myGridEntry->text();
  m_idInt=ui.idIntSpinBox->value();
  m_pttMethodIndex=ui.pttMethodComboBox->currentIndex();
  m_pttPort=ui.pttComboBox->currentIndex();
  m_saveDir=ui.saveDirEntry->text();
  m_nDevIn=ui.comboBoxSndIn->currentIndex();
  m_paInDevice=m_inDevList[m_nDevIn];
  m_nDevOut=ui.comboBoxSndOut->currentIndex();
  m_paOutDevice=m_outDevList[m_nDevOut];

  m_macro.clear();
  m_macro.append(ui.macro1->text());
  m_macro.append(ui.macro2->text());
  m_macro.append(ui.macro3->text());
  m_macro.append(ui.macro4->text());
  m_macro.append(ui.macro5->text());
  m_macro.append(ui.macro6->text());
  m_macro.append(ui.macro7->text());
  m_macro.append(ui.macro8->text());
  m_macro.append(ui.macro9->text());
  m_macro.append(ui.macro10->text());

  m_dFreq.clear();
  m_dFreq.append(ui.f1->text());
  m_dFreq.append(ui.f2->text());
  m_dFreq.append(ui.f3->text());
  m_dFreq.append(ui.f4->text());
  m_dFreq.append(ui.f5->text());
  m_dFreq.append(ui.f6->text());
  m_dFreq.append(ui.f7->text());
  m_dFreq.append(ui.f8->text());
  m_dFreq.append(ui.f9->text());
  m_dFreq.append(ui.f10->text());
  m_dFreq.append(ui.f11->text());
  m_dFreq.append(ui.f12->text());
  m_dFreq.append(ui.f13->text());
  m_dFreq.append(ui.f14->text());
  m_dFreq.append(ui.f15->text());
  m_dFreq.append(ui.f16->text());

  if(m_bRigOpen) {
    rig->close();
    if(m_rig!=9999) delete rig;
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

void DevSetup::p4ReadFromStdout()                        //p4readFromStdout
{
  while(p4.canReadLine()) {
    QString t(p4.readLine());
    QString t1,t2,t3;
    if(t.mid(0,6)!=" Rig #") {
      t1=t.mid(0,6);
      t2=t.mid(8,22).trimmed();
      t3=t.mid(31,23).trimmed();
      t=t1 + "  " + t2 + "  " + t3;
      ui.rigComboBox->addItem(t);
    }
  }
}

void DevSetup::p4ReadFromStderr()                        //p4readFromStderr
{
  QByteArray t=p4.readAllStandardError();
  if(t.length()>0) {
    msgBox(t);
  }
}

void DevSetup::p4Error()                                     //p4rror
{
  msgBox("Error running 'rigctl -l'.");
}

void DevSetup::msgBox(QString t)                             //msgBox
{
  msgBox0.setText(t);
  msgBox0.exec();
}

void DevSetup::on_myCallEntry_editingFinished()
{
  QString t=ui.myCallEntry->text();
  ui.myCallEntry->setText(t.toUpper());
}

void DevSetup::on_myGridEntry_editingFinished()
{
  QString t=ui.myGridEntry->text();
  t=t.mid(0,4).toUpper()+t.mid(4,2).toLower();
  ui.myGridEntry->setText(t);
}

void DevSetup::on_cbPSKReporter_clicked(bool b)
{
  m_pskReporter=b;
}

void DevSetup::on_pttMethodComboBox_activated(int index)
{
  m_pttMethodIndex=index;
  bool b=m_pttMethodIndex==1 or m_pttMethodIndex==2 or
      (m_catEnabled and m_pttMethodIndex==0);
  ui.testPTTButton->setEnabled(b);
}

void DevSetup::on_catPortComboBox_activated(int index)
{
  m_catPortIndex=index;
  m_catPort=ui.catPortComboBox->itemText(index);
}

void DevSetup::on_cbEnableCAT_toggled(bool b)
{
  m_catEnabled=b;
  ui.catPortComboBox->setEnabled(b);
  ui.rigComboBox->setEnabled(b);
  ui.serialRateComboBox->setEnabled(b);
  ui.dataBitsComboBox->setEnabled(b);
  ui.stopBitsComboBox->setEnabled(b);
  ui.handshakeComboBox->setEnabled(b);
  ui.testCATButton->setEnabled(b);
  ui.cbDTRoff->setEnabled(b);
  ui.rbData->setEnabled(b);
  ui.rbMic->setEnabled(b);
  ui.pollSpinBox->setEnabled(m_catEnabled);
  bool b2=(m_pttMethodIndex==1 or m_pttMethodIndex==2 or m_catEnabled) and
      !(m_pttMethodIndex==3);
  ui.testPTTButton->setEnabled(b2);
}

void DevSetup::on_serialRateComboBox_activated(int index)
{
  m_serialRateIndex=index;
  m_serialRate=ui.serialRateComboBox->itemText(index).toInt();
}

void DevSetup::on_handshakeComboBox_activated(int index)
{
  m_handshakeIndex=index;
  m_handshake=ui.handshakeComboBox->itemText(index);
}

void DevSetup::on_dataBitsComboBox_activated(int index)
{
  m_dataBitsIndex=index;
  m_dataBits=ui.dataBitsComboBox->itemText(index).toInt();
}

void DevSetup::on_stopBitsComboBox_activated(int index)
{
  m_stopBitsIndex=index;
  m_stopBits=ui.stopBitsComboBox->itemText(index).toInt();
}

void DevSetup::on_rigComboBox_activated(int index)
{
  m_rigIndex=index;
  QString t=ui.rigComboBox->itemText(index);
  m_rig=t.mid(0,7).toInt();
}

void DevSetup::on_cbID73_toggled(bool checked)
{
  m_After73=checked;
}

void DevSetup::on_testCATButton_clicked()
{
  QString t;
  int ret;

  if(!m_catEnabled) return;
  if(m_bRigOpen) {
    rig->close();
    if(m_rig!=9999) delete rig;
    m_bRigOpen=false;
  }

  rig = new Rig();

  if(m_rig != 9999) {
    if (!rig->init(m_rig)) {
      msgBox("Rig init failure");
      return;
    }
    rig->setConf("rig_pathname", m_catPort.toAscii().data());
    char buf[80];
    sprintf(buf,"%d",m_serialRate);
    rig->setConf("serial_speed",buf);
    sprintf(buf,"%d",m_dataBits);
    rig->setConf("data_bits",buf);
    sprintf(buf,"%d",m_stopBits);
    rig->setConf("stop_bits",buf);
    rig->setConf("serial_handshake",m_handshake.toAscii().data());
    if(m_bDTRoff) {
      rig->setConf("rts_state","OFF");
      rig->setConf("dtr_state","OFF");
    }
  }

  ret=rig->open(m_rig);
  if(ret==RIG_OK) {
    m_bRigOpen=true;
  } else {
    t="Open rig failed";
    msgBox(t);
    m_catEnabled=false;
    ui.cbEnableCAT->setChecked(false);
    return;
  }

  double fMHz=rig->getFreq(RIG_VFO_CURR)/1000000.0;
  if(fMHz>0.0) {
    t.sprintf("Rig control appears to be working.\nDial Frequency:  %.6f MHz",
              fMHz);
  } else {
    t.sprintf("Rig control error %d\nFailed to read frequency.",
              int(1000000.0*fMHz));
    if(m_poll>0) {
      m_catEnabled=false;
      ui.cbEnableCAT->setChecked(false);
    }
  }
  msgBox(t);
}

void DevSetup::on_testPTTButton_clicked()
{
  m_test=1-m_test;
  if(m_pttMethodIndex==1 or m_pttMethodIndex==2) {
    ptt(m_pttPort,m_test,&m_iptt,&m_COMportOpen);
  }
  if(m_pttMethodIndex==0 and !m_bRigOpen) {
    on_testCATButton_clicked();
  }
  if(m_pttMethodIndex==0 and m_bRigOpen) {
    if(m_test==0) rig->setPTT(RIG_PTT_OFF, RIG_VFO_CURR);
    if(m_test==1) {
      if(m_pttData) rig->setPTT(RIG_PTT_ON_DATA, RIG_VFO_CURR);
      if(!m_pttData) rig->setPTT(RIG_PTT_ON_MIC, RIG_VFO_CURR);
    }
  }
}

void DevSetup::on_cbDTRoff_toggled(bool checked)
{
  m_bDTRoff=checked;
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
}

void DevSetup::on_pttMethodComboBox_currentIndexChanged(int index)
{
  m_pttMethodIndex=index;
  bool b=m_pttMethodIndex==1 or m_pttMethodIndex==2;
  ui.pttComboBox->setEnabled(b);
}

/*
void DevSetup::on_pbHRD_clicked()
{

  bool bConnect=false;
  bConnect = HRDInterfaceConnect(L"localhost",7809);
  if(bConnect) {
    QString t2;

    const wchar_t* context=HRDInterfaceSendMessage(L"Get Context");
    QString qc="[" + QString::fromWCharArray (context,-1) + "] ";

    const wchar_t* cmnd = (const wchar_t*) (qc+"Get Frequency").utf16();
    const wchar_t* freqString=HRDInterfaceSendMessage(cmnd);
    t2=QString::fromWCharArray (freqString,-1);
    qDebug() << "Freq1:" << t2;

    cmnd = (const wchar_t*) (qc+"Set Frequency-Hz 14070000").utf16();
    const wchar_t* result=HRDInterfaceSendMessage(cmnd);
    t2=QString::fromWCharArray (result,-1);
    qDebug() << "Freq2:" << t2;

    cmnd = (const wchar_t*) (qc+"Get Frequency").utf16();
    freqString=HRDInterfaceSendMessage(cmnd);
    t2=QString::fromWCharArray (freqString,-1);
    qDebug() << "Freq3:" << t2;


    HRDInterfaceDisconnect();
    bConnect = HRDInterfaceIsConnected();
    HRDInterfaceFreeString(context);
    HRDInterfaceFreeString(freqString);
    HRDInterfaceFreeString(cmnd);
  } else {
    qDebug() << "Connection to HRD failed.";
  }
}
*/
