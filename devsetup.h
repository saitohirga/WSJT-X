#ifndef DEVSETUP_H
#define DEVSETUP_H

#include <QDialog>
#include <QProcess>
#include <QMessageBox>
#include "ui_devsetup.h"

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

  bool    m_restartSoundIn;
  bool    m_restartSoundOut;
  bool    m_pskReporter;
  bool    m_firstCall;
  bool    m_catEnabled;

  QString m_myCall;
  QString m_myGrid;
  QString m_saveDir;
  QString m_azelDir;
  QString m_catPort;
  QString m_handshake;

  QStringList m_macro;

  QProcess p4;
  QMessageBox msgBox0;

public slots:
  void accept();
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

  void on_dataBitsComboBox_activated(int index);

  void on_stopBitsComboBox_activated(int index);

  void on_rigComboBox_activated(int index);

private:
  void msgBox(QString t);
  Ui::DialogSndCard ui;
};

#endif // DEVSETUP_H
