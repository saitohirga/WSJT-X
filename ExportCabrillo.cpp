#include "ExportCabrillo.h"
#include "ui_exportCabrillo.h"
#include "SettingsGroup.hpp"

#include <QApplication>
#include <QDebug>
#include <QFileDialog>

ExportCabrillo::ExportCabrillo(QSettings *settings, QWidget *parent) :
  QDialog(parent),
  settings_ {settings},
  ui(new Ui::ExportCabrillo)
{
  ui->setupUi(this);
  read_settings();
  setWindowTitle(QApplication::applicationName() + " - Export Cabrillo");
}

ExportCabrillo::~ExportCabrillo()
{
  if (isVisible ()) write_settings();
  delete ui;
}

void ExportCabrillo::read_settings ()
{
  SettingsGroup group {settings_, "ExportCabrillo"};
  restoreGeometry (settings_->value ("window/geometry").toByteArray ());
}

void ExportCabrillo::write_settings ()
{
  SettingsGroup group {settings_, "ExportCabrillo"};
  settings_->setValue ("window/geometry", saveGeometry ());
}

void ExportCabrillo::on_pbSaveAs_clicked()
{
  QString fname;
  QFileDialog saveAs(this);
  saveAs.setFileMode(QFileDialog::AnyFile);
  fname=saveAs.getSaveFileName(this, "Save File", "","Cabrillo Log (*.log)");
  qDebug() << "AA" << fname;
}
