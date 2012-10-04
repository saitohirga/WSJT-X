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
  m_Str += "WSJT-X implements experimental mode JT9 for <br>";
  m_Str += "Amateur Radio communication at MF and LF.  <br><br>";
  m_Str += "Copyright 2001-2012 by Joe Taylor, K1JT.   Additional <br>";
  m_Str += "acknowledgments are contained in the source code. <br>";
  ui->labelTxt->setText(m_Str);
}

CAboutDlg::~CAboutDlg()
{
  delete ui;
}
