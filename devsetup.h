#ifndef DEVSETUP_H
#define DEVSETUP_H

#include <QDialog>
#include <QProcess>
#include <QMessageBox>
#include "ui_devsetup.h"
#include "rigclass.h"

class DevSetup : public QDialog
{
  Q_OBJECT
public:
  DevSetup(QWidget *parent=0);
  ~DevSetup();

  void initDlg();

  qint32  m_idInt;
  qint32  m_pttMethodIndex;
  qint32  m_pttPort;
  qint32  m_nDevIn;
  qint32  m_nDevOut;
  qint32  m_inDevList[100];
  qint32  m_outDevList[100];
  qint32  m_paInDevice;
  qint32  m_paOutDevice;
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
  qint32  m_test;
  qint32  m_poll;
  qint32  m_tmp;

  bool    m_restartSoundIn;
  bool    m_restartSoundOut;
  bool    m_pskReporter;
  bool    m_firstCall;
  bool    m_catEnabled;
  bool    m_After73;
  bool    m_bRigOpen;
  bool    m_bDTR;
  bool    m_bRTS;
  bool    m_pttData;
  bool    m_bSplit;
  bool    m_bXIT;

  QString m_myCall;
  QString m_myGrid;
  QString m_saveDir;
  QString m_azelDir;
  QString m_catPort;
  QString m_handshake;

  QStringList m_macro;
  QStringList m_dFreq;           // per band frequency in MHz as a string
  QStringList m_antDescription;  // per band antenna description
  QStringList m_bandDescription; // per band description

  QProcess p4;
  QMessageBox msgBox0;

public slots:
  void accept();
  void reject();
  void p4ReadFromStdout();
  void p4ReadFromStderr();
  void p4Error();

private slots:
  void on_myCallEntry_editingFinished();
  void on_myGridEntry_editingFinished();
  void on_cbPSKReporter_clicked(bool checked);
  void on_pttMethodComboBox_activated(int index);
  void on_catPortComboBox_activated(int index);
  void on_cbEnableCAT_toggled(bool checked);
  void on_serialRateComboBox_activated(int index);
  void on_handshakeComboBox_activated(int index);
  void on_handshakeComboBox_currentIndexChanged(int index);
  void on_dataBitsComboBox_activated(int index);
  void on_stopBitsComboBox_activated(int index);
  void on_rigComboBox_activated(int index);
  void on_cbID73_toggled(bool checked);
  void on_testCATButton_clicked();
  void on_testPTTButton_clicked();
  void on_DTRCheckBox_toggled(bool checked);
  void on_RTSCheckBox_toggled(bool checked);
  void on_rbData_toggled(bool checked);
  void on_pollSpinBox_valueChanged(int n);
  void on_pttComboBox_currentIndexChanged(int index);
  void on_pttMethodComboBox_currentIndexChanged(int index);

  void on_cbSplit_toggled(bool checked);

  void on_cbXIT_toggled(bool checked);

private:
  Rig* rig;
  void msgBox(QString t);
  void setEnableAntennaDescriptions(bool enable);
  void enableWidgets();
  void openRig();
  Ui::DialogSndCard ui;
};

extern int ptt(int nport, int ntx, int* iptt, int* nopen);

#ifdef WIN32
extern "C" {
  bool HRDInterfaceConnect(const wchar_t *host, const ushort);
  void HRDInterfaceDisconnect();
  bool HRDInterfaceIsConnected();
  wchar_t* HRDInterfaceSendMessage(const wchar_t *msg);
  void HRDInterfaceFreeString(const wchar_t *lstring);
}
#endif

#endif // DEVSETUP_H
