#include "devsetup.h"
#include "mainwindow.h"
#include <QDebug>
#include <portaudio.h>

#define MAXDEVICES 100

//----------------------------------------------------------- DevSetup()
DevSetup::DevSetup(QWidget *parent) :	QDialog(parent)
{
  ui.setupUi(this);	                              //setup the dialog form
  m_restartSoundIn=false;
  m_restartSoundOut=false;
  m_firstCall=true;
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

  k=0;
// Needs work to compile for Linux
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

  ui.myCallEntry->setText(m_myCall);
  ui.myGridEntry->setText(m_myGrid);
  ui.idIntSpinBox->setValue(m_idInt);
  ui.pttComboBox->setCurrentIndex(m_pttPort);
  ui.saveDirEntry->setText(m_saveDir);
  ui.comboBoxSndIn->setCurrentIndex(m_nDevIn);
  ui.comboBoxSndOut->setCurrentIndex(m_nDevOut);
  ui.cbPSKReporter->setChecked(m_pskReporter);
  m_paInDevice=m_inDevList[m_nDevIn];
  m_paOutDevice=m_outDevList[m_nDevOut];

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

  QDialog::accept();
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
