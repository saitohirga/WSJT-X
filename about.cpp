#include "about.h"
#include "ui_about.h"

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
  m_Str += "Copyright 2001-2013 by Joe Taylor, K1JT -- with grateful <br>";
  m_Str += "acknowledgment for contributions from AC6SL, AE4JY, <br>";
  m_Str += "G4KLA, G4WJS, K3WYC, KA6MAL, KA9Q, PY2SDR, VK3ACF, <br>";
  m_Str += "and VK4BDJ.<br>";
  ui->labelTxt->setText(m_Str);
}

CAboutDlg::~CAboutDlg()
{
  delete ui;
}
