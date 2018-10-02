#include "messageaveraging.h"

#include <QSettings>
#include <QApplication>
#include <QTextCharFormat>

#include "SettingsGroup.hpp"
#include "qt_helpers.hpp"
#include "ui_messageaveraging.h"

MessageAveraging::MessageAveraging(QSettings * settings, QFont const& font, QWidget *parent) :
  QWidget(parent),
  settings_ {settings},
  ui(new Ui::MessageAveraging)
{
  ui->setupUi(this);
//  setWindowTitle (QApplication::applicationName () + " - " + tr ("Message Averaging"));
  ui->msgAvgPlainTextEdit->setReadOnly (true);
  changeFont (font);
  read_settings ();
  if(m_title_.contains("Fox")) {
    ui->header_label->setText("   Date     Time   Call Grid Sent Rcvd Band");
  } else if(m_title_.contains("Contest")) {
    ui->header_label->setText("    Date    UTC   Band Call          Sent          Rcvd");
    ui->lab1->setText("QSOs: 0");
    ui->lab2->setText("Mults: 0");
    ui->lab3->setText("Score: 0");
    ui->lab4->setText("Rate: 0");
  } else {
    ui->header_label->setText("   UTC  Sync    DT  Freq   ");
    ui->lab1->setVisible(false);
    ui->lab2->setVisible(false);
    ui->lab3->setVisible(false);
    ui->lab4->setVisible(false);
  }

  setWindowTitle(m_title_);
  m_nLogged_=0;
}

MessageAveraging::~MessageAveraging()
{
  if (isVisible ()) write_settings ();
}

void MessageAveraging::changeFont (QFont const& font)
{
  ui->header_label->setStyleSheet (font_as_stylesheet (font));
  ui->msgAvgPlainTextEdit->setStyleSheet (font_as_stylesheet (font));
  setContentFont (font);
  updateGeometry ();
}

void MessageAveraging::setContentFont(QFont const& font)
{
  ui->msgAvgPlainTextEdit->setFont (font);
  QTextCharFormat charFormat;
  charFormat.setFont (font);
  ui->msgAvgPlainTextEdit->selectAll ();
  auto cursor = ui->msgAvgPlainTextEdit->textCursor ();
  cursor.mergeCharFormat (charFormat);
  cursor.clearSelection ();
  cursor.movePosition (QTextCursor::End);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::Up);
  cursor.movePosition (QTextCursor::StartOfLine);

  ui->msgAvgPlainTextEdit->setTextCursor (cursor);
  ui->msgAvgPlainTextEdit->ensureCursorVisible ();
}

void MessageAveraging::closeEvent (QCloseEvent * e)
{
  write_settings ();
  QWidget::closeEvent (e);
}

void MessageAveraging::read_settings ()
{
  SettingsGroup group {settings_, "MessageAveraging"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
  m_title_=settings_->value("window/title","Message Averaging").toString();
  m_nContest_=settings_->value("nContest",0).toInt();
}

void MessageAveraging::write_settings ()
{
  SettingsGroup group {settings_, "MessageAveraging"};
  settings_->setValue ("window/geometry", saveGeometry ());
  settings_->setValue("window/title",m_title_);
  settings_->setValue("nContest",m_nContest_);
}

void MessageAveraging::displayAvg(QString const& t)
{
  ui->msgAvgPlainTextEdit->setPlainText(t);
}

void MessageAveraging::foxLogSetup(int nContest)
{
  if(nContest==5) {
    m_title_=QApplication::applicationName () + " - Fox Log";
    setWindowTitle(m_title_);
    ui->header_label->setText("   Date    Time  Call    Grid Sent Rcvd Band");
  }
  if(nContest>0 and nContest<5) {
    m_title_=QApplication::applicationName () + " - Contest Log";
    setWindowTitle(m_title_);
    ui->header_label->setText("    Date    UTC   Band Call          Sent          Rcvd");
  }
  m_nContest_=nContest;
}

void MessageAveraging::foxLabCallers(int n)
{
  QString t;
  t.sprintf("Callers: %3d",n);
  ui->lab1->setText(t);
}

void MessageAveraging::foxLabQueued(int n)
{
  QString t;
  t.sprintf("In progress: %3d",n);
  ui->lab2->setText(t);
}

void MessageAveraging::foxLabRate(int n)
{
  QString t;
  t.sprintf("Rate: %3d",n);
  ui->lab4->setText(t);
}

void MessageAveraging::foxAddLog(QString logLine)
{
  ui->msgAvgPlainTextEdit->appendPlainText(logLine);
  m_nLogged_++;
  QString t;
  t.sprintf("Logged: %d",m_nLogged_);
  ui->lab3->setText(t);
}

void MessageAveraging::contestAddLog(qint32 nContest, QString logLine)
{
  m_nContest_=nContest;
  ui->msgAvgPlainTextEdit->appendPlainText(logLine);
  m_nLogged_++;
  QString t;
  t.sprintf("QSOs: %d",m_nLogged_);
  ui->lab1->setText(t);
  if(m_mult_<1) m_mult_=1;
  t.sprintf("Mults: %d",m_mult_);
  ui->lab2->setText(t);
  int score=m_mult_*m_nLogged_;
  t.sprintf("Score: %d",score);
  ui->lab3->setText(t);
}
