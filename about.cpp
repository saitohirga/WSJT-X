#include "about.h"

#include "ui_about.h"

#include "moc_about.cpp"

CAboutDlg::CAboutDlg(QString const& program_title, QWidget *parent) :
  QDialog(parent),
  ui(new Ui::CAboutDlg)
{
  ui->setupUi(this);

  ui->labelTxt->setText ("<html><h2>" + program_title + "</h2>\n\n"
                         "WSJT-X implements digital modes JT9 and JT65 for <br>"
                         "Amateur Radio communication.  <br><br>"
                         "&copy; 2001-2014 by Joe Taylor, K1JT, with grateful <br>"
                         "acknowledgment for contributions from AC6SL, AE4JY, <br>"
                         "DJ0OT, G4KLA, G4WJS, K3WYC, KA6MAL, KA9Q, KB1ZMX, <br>"
                         "KK1D, PY2SDR, VK3ACF, VK4BDJ, W4TI, W4TV, and W9MDB.<br>");
}

CAboutDlg::~CAboutDlg()
{
}
