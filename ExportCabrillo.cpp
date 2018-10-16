#include "ExportCabrillo.h"
#include "SettingsGroup.hpp"
#include "MessageBox.hpp"

#include <QApplication>
#include <QDebug>
#include <QFileDialog>

#include "ui_ExportCabrillo.h"
#include "moc_ExportCabrillo.cpp"

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
  if(isVisible()) write_settings();
  delete ui;
}

void ExportCabrillo::closeEvent (QCloseEvent * e)
{
  write_settings();
  QWidget::closeEvent(e);
}


void ExportCabrillo::read_settings ()
{
  SettingsGroup group {settings_, "ExportCabrillo"};
  restoreGeometry (settings_->value("window/geometry").toByteArray());
  ui->lineEdit_1->setText(settings_->value("Location").toString());
  ui->lineEdit_2->setText(settings_->value("Contest").toString());
  ui->lineEdit_3->setText(settings_->value("Callsign").toString());
  ui->lineEdit_4->setText(settings_->value("Category-Operator").toString());
  ui->lineEdit_5->setText(settings_->value("Category-Transmitter").toString());
  ui->lineEdit_6->setText(settings_->value("Category-Power").toString());
  ui->lineEdit_7->setText(settings_->value("Category-Assisted").toString());
  ui->lineEdit_8->setText(settings_->value("Category-Band").toString());
  ui->lineEdit_9->setText(settings_->value("Claimed-Score").toString());
  ui->lineEdit_10->setText(settings_->value("Operators").toString());
  ui->lineEdit_11->setText(settings_->value("Club").toString());
  ui->lineEdit_12->setText(settings_->value("Name").toString());
  ui->lineEdit_13->setText(settings_->value("Address1").toString());
  ui->lineEdit_14->setText(settings_->value("Address2").toString());
}

void ExportCabrillo::write_settings ()
{
  SettingsGroup group {settings_, "ExportCabrillo"};
  settings_->setValue ("window/geometry", saveGeometry ());
  settings_->setValue("Location",ui->lineEdit_1->text());
  settings_->setValue("Contest",ui->lineEdit_2->text());
  settings_->setValue("Callsign",ui->lineEdit_3->text());
  settings_->setValue("Category-Operator",ui->lineEdit_4->text());
  settings_->setValue("Category-Transmitter",ui->lineEdit_5->text());
  settings_->setValue("Category-Power",ui->lineEdit_6->text());
  settings_->setValue("Category-Assisted",ui->lineEdit_7->text());
  settings_->setValue("Category-Band",ui->lineEdit_8->text());
  settings_->setValue("Claimed-Score",ui->lineEdit_9->text());
  settings_->setValue("Operators",ui->lineEdit_10->text());
  settings_->setValue("Club",ui->lineEdit_11->text());
  settings_->setValue("Name",ui->lineEdit_12->text());
  settings_->setValue("Address1",ui->lineEdit_13->text());
  settings_->setValue("Address2",ui->lineEdit_14->text());
}

void ExportCabrillo::setFile(QString t)
{
  m_CabLog=t;
}


void ExportCabrillo::on_pbSaveAs_clicked()
{
  QString fname;
  QFileDialog saveAs(this);
  saveAs.setFileMode(QFileDialog::AnyFile);
  fname=saveAs.getSaveFileName(this, "Save File", "","Cabrillo Log (*.log)");
  QFile f {fname};
  if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
    QTextStream out(&f);
    out << "START-OF-LOG:3.0" << endl
        << "LOCATION: " << ui->lineEdit_1->text() << endl
        << "CONTEST: " << ui->lineEdit_2->text() << endl
        << "CALLSIGN: " << ui->lineEdit_3->text() << endl
        << "CATEGORY-OPERATOR: " << ui->lineEdit_4->text() << endl
        << "CATEGORY-TRANSMITTER: " << ui->lineEdit_5->text() << endl
        << "CATEGORY-POWER: " << ui->lineEdit_6->text() << endl
        << "CATEGORY-ASSISTED: " << ui->lineEdit_7->text() << endl
        << "CATEGORY-BAND: " << ui->lineEdit_8->text() << endl
        << "CLAIMED-SCORE: " << ui->lineEdit_9->text() << endl
        << "OPERATORS: " << ui->lineEdit_10->text() << endl
        << "CLUB: " << ui->lineEdit_11->text() << endl
        << "NAME: " << ui->lineEdit_12->text() << endl
        << "ADDRESS: " << ui->lineEdit_13->text() << endl
        << "ADDRESS: " << ui->lineEdit_14->text() << endl;

    QFile f2(m_CabLog);
    if(f2.open(QIODevice::ReadOnly | QIODevice::Text)) {
      QTextStream s(&f2);
      QString t=s.readAll();
      out << t << "END-OF-LOG:" << endl;
      f2.close();
    }
    f.close();
  } else {
    auto const& message = tr ("Cannot open \"%1\" for writing: %2")
        .arg (f.fileName ()).arg (f.errorString ());
      MessageBox::warning_message (this, tr ("Export Cabrillo File Error"), message);
  }
  write_settings();
}

void ExportCabrillo::accept()
{
  write_settings();
  QDialog::accept();
}
