#include "activeStations.h"

#include <QSettings>
#include <QApplication>
#include <QTextCharFormat>
#include <QDateTime>
#include <QDebug>

#include "SettingsGroup.hpp"
#include "qt_helpers.hpp"
#include "ui_activeStations.h"

#include "moc_activeStations.cpp"

ActiveStations::ActiveStations(QSettings * settings, QFont const& font, QWidget *parent) :
  QWidget(parent),
  settings_ {settings},
  ui(new Ui::ActiveStations)
{
  ui->setupUi(this);
  setWindowTitle (QApplication::applicationName () + " - " + tr ("Active Stations"));
  ui->RecentStationsPlainTextEdit->setReadOnly (true);
  changeFont (font);
  read_settings ();
  ui->header_label2->setText("  N   Call    Grid   Az  S/N  Freq Tx Age Pts");
  connect(ui->RecentStationsPlainTextEdit, SIGNAL(selectionChanged()), this, SLOT(select()));
  connect(ui->cbReadyOnly, SIGNAL(toggled(bool)), this, SLOT(on_cbReadyOnly_toggled(bool)));
}

ActiveStations::~ActiveStations()
{
  write_settings ();
}

void ActiveStations::changeFont (QFont const& font)
{
  ui->header_label2->setStyleSheet (font_as_stylesheet (font));
  ui->RecentStationsPlainTextEdit->setStyleSheet (font_as_stylesheet (font));
  updateGeometry ();
}

void ActiveStations::read_settings ()
{
  SettingsGroup group {settings_, "ActiveStations"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
  ui->sbMaxRecent->setValue(settings_->value("MaxRecent",10).toInt());
  ui->sbMaxAge->setValue(settings_->value("MaxAge",10).toInt());
  ui->cbReadyOnly->setChecked(settings_->value("ReadyOnly",false).toBool());
}

void ActiveStations::write_settings ()
{
  SettingsGroup group {settings_, "ActiveStations"};
  settings_->setValue ("window/geometry", saveGeometry ());
  settings_->setValue("MaxRecent",ui->sbMaxRecent->value());
  settings_->setValue("MaxAge",ui->sbMaxAge->value());
  settings_->setValue("ReadyOnly",ui->cbReadyOnly->isChecked());
}

void ActiveStations::displayRecentStations(QString const& t)
{
  ui->RecentStationsPlainTextEdit->setPlainText(t);
}

int ActiveStations::maxRecent()
{
  return ui->sbMaxRecent->value();
}

int ActiveStations::maxAge()
{
  return ui->sbMaxAge->value();
}

void ActiveStations::select()
{
  if(m_clickOK) {
    qint64 msec=QDateTime::currentMSecsSinceEpoch();
    if((msec-m_msec0)<500) return;
    m_msec0=msec;
    int nline=ui->RecentStationsPlainTextEdit->textCursor().blockNumber();
    emit callSandP(nline);
  }
}

void ActiveStations::setClickOK(bool b)
{
  m_clickOK=b;
}

void ActiveStations::erase()
{
  ui->RecentStationsPlainTextEdit->clear();
}

bool ActiveStations::readyOnly()
{
  return ui->cbReadyOnly->isChecked();
}

void ActiveStations::on_cbReadyOnly_toggled(bool b)
{
  m_bReadyOnly=b;
  emit activeStationsDisplay();
}

void ActiveStations::setRate(int n)
{
  ui->rate->setText(QString::number(n));
}

void ActiveStations::setScore(int n)
{
  ui->score->setText(QLocale(QLocale::English).toString(n));
}

void ActiveStations::setBandChanges(int n)
{
  if(n >= 8) {
    ui->bandChanges->setStyleSheet("QLineEdit{background: rgb(255, 64, 64)}");
  } else {
    ui->bandChanges->setStyleSheet ("");
  }
  ui->bandChanges->setText(QString::number(n));
}
