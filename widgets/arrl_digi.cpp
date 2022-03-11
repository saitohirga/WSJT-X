#include "arrl_digi.h"

#include <QSettings>
#include <QApplication>
#include <QTextCharFormat>

#include "SettingsGroup.hpp"
#include "qt_helpers.hpp"
#include "ui_arrl_digi.h"

#include "moc_arrl_digi.cpp"

ARRL_Digi::ARRL_Digi(QSettings * settings, QFont const& font, QWidget *parent) :
  QWidget(parent),
  settings_ {settings},
  ui(new Ui::ARRL_Digi)
{
  ui->setupUi(this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("ARRL International Digital Contest"));
  ui->ARRL_DigiPlainTextEdit->setReadOnly (true);
  changeFont (font);
  read_settings ();
  ui->header_label->setText("Pts  Call   Grid  Az    S/N   Dial  Freq");
}

ARRL_Digi::~ARRL_Digi()
{
  write_settings ();
}

void ARRL_Digi::changeFont (QFont const& font)
{
  ui->header_label->setStyleSheet (font_as_stylesheet (font));
  ui->ARRL_DigiPlainTextEdit->setStyleSheet (font_as_stylesheet (font));
  setContentFont (font);
  updateGeometry ();
}


void ARRL_Digi::setContentFont(QFont const& font)
{
  ui->ARRL_DigiPlainTextEdit->setFont (font);
  QTextCharFormat charFormat;
  charFormat.setFont (font);
  ui->ARRL_DigiPlainTextEdit->selectAll ();
  auto cursor = ui->ARRL_DigiPlainTextEdit->textCursor ();
  cursor.mergeCharFormat (charFormat);
  cursor.clearSelection ();
  cursor.movePosition (QTextCursor::End);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::Up);
  cursor.movePosition (QTextCursor::StartOfLine);

  ui->ARRL_DigiPlainTextEdit->setTextCursor (cursor);
  ui->ARRL_DigiPlainTextEdit->ensureCursorVisible ();
}

void ARRL_Digi::read_settings ()
{
  SettingsGroup group {settings_, "ARRL_Digi"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
}

void ARRL_Digi::write_settings ()
{
  SettingsGroup group {settings_, "ARRL_Digi"};
  settings_->setValue ("window/geometry", saveGeometry ());
}

void ARRL_Digi::displayARRL_Digi(QString const& t)
{
  ui->ARRL_DigiPlainTextEdit->setPlainText(t);
}
