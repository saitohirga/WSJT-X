#include "arrl_digi.h"

#include <QSettings>
#include <QApplication>
#include <QTextCharFormat>

#include "SettingsGroup.hpp"
#include "qt_helpers.hpp"
#include "ui_arrl_digi.h"

#include "moc_arrl_digi.cpp"

ActiveStations::ActiveStations(QSettings * settings, QFont const& font, QWidget *parent) :
  QWidget(parent),
  settings_ {settings},
  ui(new Ui::ActiveStations)
{
  ui->setupUi(this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("ARRL International Digital Contest"));
  ui->ActiveStationsPlainTextEdit->setReadOnly (true);
  changeFont (font);
  read_settings ();
  ui->header_label->setText("Pts  Call   Grid  Az    S/N   Dial  Freq");
}

ActiveStations::~ActiveStations()
{
  write_settings ();
}

void ActiveStations::changeFont (QFont const& font)
{
  ui->header_label->setStyleSheet (font_as_stylesheet (font));
  ui->ActiveStationsPlainTextEdit->setStyleSheet (font_as_stylesheet (font));
  setContentFont (font);
  updateGeometry ();
}


void ActiveStations::setContentFont(QFont const& font)
{
  ui->ActiveStationsPlainTextEdit->setFont (font);
  QTextCharFormat charFormat;
  charFormat.setFont (font);
  ui->ActiveStationsPlainTextEdit->selectAll ();
  auto cursor = ui->ActiveStationsPlainTextEdit->textCursor ();
  cursor.mergeCharFormat (charFormat);
  cursor.clearSelection ();
  cursor.movePosition (QTextCursor::End);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::Up);
  cursor.movePosition (QTextCursor::StartOfLine);

  ui->ActiveStationsPlainTextEdit->setTextCursor (cursor);
  ui->ActiveStationsPlainTextEdit->ensureCursorVisible ();
}

void ActiveStations::read_settings ()
{
  SettingsGroup group {settings_, "ActiveStations"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
}

void ActiveStations::write_settings ()
{
  SettingsGroup group {settings_, "ActiveStations"};
  settings_->setValue ("window/geometry", saveGeometry ());
}

void ActiveStations::displayActiveStations(QString const& t)
{
  ui->ActiveStationsPlainTextEdit->setPlainText(t);
}
