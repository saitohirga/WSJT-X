#include "foxcalls.h"
#include "qt_helpers.hpp"
#include <QSettings>
#include <QApplication>
#include <QMap>
#include "ui_foxcalls.h"
#include "moc_foxcalls.cpp"

FoxCalls::FoxCalls(QSettings * settings, QWidget *parent) :
  QWidget {parent, Qt::Window | Qt::WindowTitleHint | Qt::WindowCloseButtonHint | Qt::WindowMinimizeButtonHint},
  m_settings (settings),
  ui(new Ui::FoxCalls)
{
  ui->setupUi(this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("Fox Callers"));
  installEventFilter(parent);                   //Installing the filter

//Restore user's settings
  m_settings->beginGroup("FoxCalls");
  restoreGeometry (m_settings->value("geometry").toByteArray());
  ui->cbReverse->setVisible(false);
  ui->foxPlainTextEdit->setReadOnly (true);
  ui->foxPlainTextEdit->viewport()->installEventFilter(this);
  m_nToBeCalled=0;
}

FoxCalls::~FoxCalls()
{
  saveSettings();
}

void FoxCalls::closeEvent (QCloseEvent * e)
{
  saveSettings ();
  QWidget::closeEvent (e);
}

void FoxCalls::saveSettings()
{
//Save user's settings
  m_settings->beginGroup("FoxCalls");
  m_settings->setValue("geometry", saveGeometry());
  m_settings->endGroup();
}

void FoxCalls::insertText(QString t)
{
  QMap<QString,QString> map;
  QStringList lines;
  QString msg,c2,t1;
  QString ABC{"ABCDEFGHIJKLMNOPQRSTUVWXYZ"};
  QList<int> list;
  int i,j,k,n,nlines;

  if(m_bFirst) {
    QTextDocument *doc = ui->foxPlainTextEdit->document();
    QFont font = doc->defaultFont();
    font.setFamily("Courier New");
    font.setPointSize(12);
    doc->setDefaultFont(font);
    ui->label_2->setFont(font);
    ui->label_2->setText("Call         Grid   dB  Freq   Age");
    ui->pteToBeCalled->setFont(font);
    ui->pteCalled->setFont(font);
    m_bFirst=false;
  }

  m_t0=t;
// Save only the most recent transmission from each caller.
  lines = t.split("\n");
  nlines=lines.length()-1;
  for(i=0; i<nlines; i++) {
    msg=lines.at(i);
    c2=msg.split(" ").at(0);
    map[c2]=msg;
  }

  j=0;
  t="";
  for(auto a: map.keys()) {
    t1=map[a].split(" ",QString::SkipEmptyParts).at(2);
    int nsnr=t1.toInt();
    if(nsnr>=ui->sbMinDB->value() and nsnr<=ui->sbMaxDB->value()) {
      if(ui->rbCall->isChecked()) t += map[a] + "\n";
      if(ui->rbSNR->isChecked() or ui->rbAge->isChecked()) {
        i=2;
        if(ui->rbAge->isChecked()) i=4;
        t1=map[a].split(" ",QString::SkipEmptyParts).at(i);
        n=1000*(t1.toInt()+100) + j;
      }

      if(ui->rbGrid->isChecked()) {
        t1=map[a].split(" ",QString::SkipEmptyParts).at(1);
        int i1=ABC.indexOf(t1.mid(0,1));
        int i2=ABC.indexOf(t1.mid(1,1));
        n=100*(26*i1+i2)+t1.mid(2,2).toInt();
        n=1000*n + j;
      }

      list.insert(j,n);
      m_lines2.insert(j,map[a]);
      j++;
    }
  }

  if(ui->rbSNR->isChecked() or ui->rbAge->isChecked() or ui->rbGrid->isChecked()) {
    if(m_bReverse) {
      qSort(list.begin(),list.end(),qGreater<int>());
    } else {
      qSort(list.begin(),list.end());
    }
  }

  if(ui->rbSNR->isChecked() or ui->rbAge->isChecked() or ui->rbGrid->isChecked()) {
    for(i=0; i<j; i++) {
      k=list[i]%1000;
      n=list[i]/1000 - 100;
      t += m_lines2.at(k) + "\n";
    }
  }

  ui->foxPlainTextEdit->setPlainText(t);
  QString uniqueCalls;
  uniqueCalls.sprintf("   Unique callers: %d",j);
  ui->labCallers->setText(uniqueCalls);
}

void FoxCalls::on_rbCall_toggled(bool b)
{
  ui->cbReverse->setVisible(!b);
  insertText(m_t0);
}

void FoxCalls::on_rbGrid_toggled(bool b)
{
  ui->cbReverse->setVisible(b);
  insertText(m_t0);
}
void FoxCalls::on_rbSNR_toggled(bool b)
{
  ui->cbReverse->setVisible(b);
  insertText(m_t0);
}
void FoxCalls::on_rbAge_toggled(bool b)
{
  ui->cbReverse->setVisible(b);
  insertText(m_t0);
}

void FoxCalls::on_cbReverse_toggled(bool b)
{
  m_bReverse=b;
  insertText(m_t0);
}

void FoxCalls::on_sbMaxDB_valueChanged(int n)
{
  insertText(m_t0);
}

void FoxCalls::on_sbMinDB_valueChanged(int n)
{
  insertText(m_t0);
}

bool FoxCalls::eventFilter(QObject *obj, QEvent *e)
{
  if(m_nToBeCalled<4) {
    if ((obj == ui->foxPlainTextEdit || obj==ui->foxPlainTextEdit->viewport()) &&
        e->type() == QEvent::MouseButtonPress) {
      QMouseEvent *me= static_cast<QMouseEvent*>(e);
      int i=int(0.05592*me->y()+0.5) - 1;
      QString t3=m_lines2.at(i);
      t3=t3.split(" ").at(0) + "\n";
      ui->pteToBeCalled->insertPlainText(t3);
      m_nToBeCalled++;
      qDebug() << "a" << m_nToBeCalled;
    }
  }
  return QWidget::eventFilter(obj, e);
}
