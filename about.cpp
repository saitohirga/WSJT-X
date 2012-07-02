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
  m_Str += "JTMS3 implements an experimental mode for Amateur Radio <br>";
  m_Str += "communication by Meteor Scatter.  <br><br>";
  m_Str += "Copyright 2001-2012 by Joe Taylor, K1JT.   Additional <br>";
  m_Str += "acknowledgments are contained in the source code. <br>";
  ui->labelTxt->setText(m_Str);
}

CAboutDlg::~CAboutDlg()
{
  delete ui;
}
