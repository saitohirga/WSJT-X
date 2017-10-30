#include "foxcalls.h"
#include "qt_helpers.hpp"
#include <QSettings>
#include <QApplication>
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
  restoreGeometry (m_settings->value ("geometry", saveGeometry ()).toByteArray ());
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
  m_settings->setValue ("geometry", saveGeometry ());
  m_settings->endGroup();
}

void FoxCalls::insertText(QString t)
{
  QTextDocument *doc = ui->foxPlainTextEdit->document();
  QFont font = doc->defaultFont();
  font.setFamily("Courier New");
  doc->setDefaultFont(font);
  qDebug() << font;
  ui->foxPlainTextEdit->setPlainText(t);
  ui->foxPlainTextEdit->setReadOnly (true);
}
