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
  } else {
    ui->header_label->setText("   UTC  Sync    DT  Freq   ");
    ui->lab1->setVisible(false);
    ui->lab2->setVisible(false);
    ui->lab3->setVisible(false);
  }
  setWindowTitle(m_title_);
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
}

void MessageAveraging::write_settings ()
{
  SettingsGroup group {settings_, "MessageAveraging"};
  settings_->setValue ("window/geometry", saveGeometry ());
  settings_->setValue("window/title",m_title_);
}

void MessageAveraging::displayAvg(QString const& t)
{
  ui->msgAvgPlainTextEdit->setPlainText(t);
}

void MessageAveraging::foxLogSetup()
{
  m_title_=QApplication::applicationName () + " - Fox Log";
  setWindowTitle(m_title_);
  ui->header_label->setText("   Date    Time  Call    Grid Sent Rcvd Band");
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
  t.sprintf("Queued: %3d",n);
  ui->lab2->setText(t);
}

void MessageAveraging::foxLabRate(int n)
{
  QString t;
  t.sprintf("Rate: %3d",n);
  ui->lab3->setText(t);
}

void MessageAveraging::foxAddLog(QString logLine)
{
  ui->msgAvgPlainTextEdit->insertPlainText(logLine + "\n");
}
