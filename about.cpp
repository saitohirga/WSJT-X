#include "about.h"
#include "ui_about.h"

#include "moc_about.cpp"

CAboutDlg::CAboutDlg(QWidget *parent, QString Revision) :
  QDialog(parent),
  m_Revision(Revision),
  ui(new Ui::CAboutDlg)
{
  ui->setupUi(this);
  ui->labelTxt->clear();
  m_Str  = "<html><h2>" + m_Revision + "</h2>\n\n";
  m_Str += "WSJT-X implements digital modes JT9 and JT65 for <br>";
  m_Str += "Amateur Radio communication.  <br><br>";
  m_Str += "Copyright 2001-2014 by Joe Taylor, K1JT, with grateful <br>";
  m_Str += "acknowledgment for contributions from AC6SL, AE4JY, <br>";
  m_Str += "DJ0OT, G4KLA, G4WJS, K3WYC, KA6MAL, KA9Q, KB1ZMX, <br>";
  m_Str += "KK1D, PY2SDR, VK3ACF, VK4BDJ, W4TI, and W4TV.<br>";
  ui->labelTxt->setText(m_Str);
}

CAboutDlg::~CAboutDlg()
{
  delete ui;
}
