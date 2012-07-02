#include "devsetup.h"
#include "mainwindow.h"
#include <QDebug>
#include <portaudio.h>

#define MAXDEVICES 100

//----------------------------------------------------------- DevSetup()
DevSetup::DevSetup(QWidget *parent) :	QDialog(parent)
{
  ui.setupUi(this);	//setup the dialog form
  m_restartSoundIn=false;
  m_restartSoundOut=false;
}

DevSetup::~DevSetup()
{
}

void DevSetup::initDlg()
{
  int k,id;
  int valid_devices=0;
  int minChan[MAXDEVICES];
  int maxChan[MAXDEVICES];
  int minSpeed[MAXDEVICES];
  int maxSpeed[MAXDEVICES];
  char hostAPI_DeviceName[MAXDEVICES][50];
  char s[60];
  int numDevices=Pa_GetDeviceCount();

  const PaDeviceInfo *pdi;
  int nchin;
  int nchout;
  char *p,*p1;
  char p2[50];
  char pa_device_name[128];
  char pa_device_hostapi[128];

/*
  getDev(&numDevices,hostAPI_DeviceName,minChan,maxChan,minSpeed,maxSpeed);
  k=0;
  for(id=0; id<numDevices; id++)  {
    if(48000 >= minSpeed[id] && 48000 <= maxSpeed[id]) {
      m_inDevList[k]=id;
      k++;
      sprintf(s,"%2d   %d  %-49s",id,maxChan[id],hostAPI_DeviceName[id]);
      QString t(s);
      ui.comboBoxSndIn->addItem(t);
      valid_devices++;
    }
  }
*/

  k=0;
  for(id=0; id<numDevices; id++ )  {
    pdi=Pa_GetDeviceInfo(id);
    nchin=pdi->maxInputChannels;
    if(nchin>=2) {
      m_inDevList[k]=id;
      k++;
      sprintf((char*)(pa_device_name),"%s",pdi->name);
      sprintf((char*)(pa_device_hostapi),"%s",
              Pa_GetHostApiInfo(pdi->hostApi)->name);

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

      sprintf(p2,"%2d   %-8s  %-39s",id,p1,pa_device_name);
      QString t(p2);
      ui.comboBoxSndIn->addItem(t);
    }
    nchout=pdi->maxOutputChannels;
    if(nchout>=2) {
      m_outDevList[k]=id;
      k++;
      sprintf((char*)(pa_device_name),"%s",pdi->name);
      sprintf((char*)(pa_device_hostapi),"%s",
              Pa_GetHostApiInfo(pdi->hostApi)->name);

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

      sprintf(p2,"%2d   %-8s  %-39s",id,p1,pa_device_name);
      QString t(p2);
      ui.comboBoxSndOut->addItem(t);
    }
  }

  ui.myCallEntry->setText(m_myCall);
  ui.myGridEntry->setText(m_myGrid);
  ui.idIntSpinBox->setValue(m_idInt);
  ui.pttComboBox->setCurrentIndex(m_pttPort);
  ui.saveDirEntry->setText(m_saveDir);
  ui.dxccEntry->setText(m_dxccPfx);
  ui.comboBoxSndIn->setCurrentIndex(m_nDevIn);
  ui.comboBoxSndOut->setCurrentIndex(m_nDevOut);
  m_paInDevice=m_inDevList[m_nDevIn];
  m_paOutDevice=m_outDevList[m_nDevOut];
  qDebug() << "A" << m_nDevIn << m_paInDevice << m_nDevOut << m_paOutDevice;


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
  m_dxccPfx=ui.dxccEntry->text();
  m_nDevIn=ui.comboBoxSndIn->currentIndex();
  m_paInDevice=m_inDevList[m_nDevIn];
  m_nDevOut=ui.comboBoxSndOut->currentIndex();
  m_paOutDevice=m_outDevList[m_nDevOut];
  QDialog::accept();
  qDebug() << "B" << m_nDevIn << m_paInDevice << m_nDevOut << m_paOutDevice;

}

