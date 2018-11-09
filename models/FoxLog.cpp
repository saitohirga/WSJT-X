#include "FoxLog.hpp"

#include <QString>
#include <QDateTime>
#include <QSqlDatabase>
#include <QSqlTableModel>
#include <QSqlRecord>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>
#include "pimpl_impl.hpp"

class FoxLog::impl final
  : public QSqlTableModel
{
public:
  impl ();
  QSqlQuery insert_;
};

FoxLog::impl::impl ()
{
  if (!database ().tables ().contains ("fox_log"))
    {
      QSqlQuery query;
      if (!query.exec ("CREATE TABLE fox_log ("
                       "	id INTEGER PRIMARY KEY AUTOINCREMENT,"
                       "	\"when\" DATETIME NOT NULL,"
                       "	call VARCHAR(20) NOT NULL,"
                       "	grid VARCHAR(4),"
                       "	report_sent VARCHAR(3),"
                       "	report_rcvd VARCHAR(3),"
                       "	band VARCHAR(6) NOT NULL,"
                       "	CONSTRAINT no_dupes UNIQUE (call, band)"
                       ")"))
        {
          throw std::runtime_error {("SQL Error: " + query.lastError ().text ()).toStdString ()};
        }
    }

  setEditStrategy (QSqlTableModel::OnRowChange);
  setTable ("fox_log");
  setHeaderData (fieldIndex ("when"), Qt::Horizontal, tr ("Date and Time"));
  setHeaderData (fieldIndex ("call"), Qt::Horizontal, tr ("Call"));
  setHeaderData (fieldIndex ("grid"), Qt::Horizontal, tr ("Grid"));
  setHeaderData (fieldIndex ("report_sent"), Qt::Horizontal, tr ("Sent"));
  setHeaderData (fieldIndex ("report_rcvd"), Qt::Horizontal, tr ("Rcvd"));
  setHeaderData (fieldIndex ("band"), Qt::Horizontal, tr ("Band"));
  if (!select ())
    {
      throw std::runtime_error {("SQL Error: " + lastError ().text ()).toStdString ()};
    }
}

FoxLog::FoxLog ()
{
}

FoxLog::~FoxLog ()
{
}

QAbstractItemModel * FoxLog::model ()
{
  return &*m_;
}

bool FoxLog::add_QSO (QDateTime const& when, QString const& call, QString const& grid
                      , QString const& report_received, QString const& report_sent
                      , QString const& band)
{
  auto db = m_->database ();
  auto record = m_->record ();
  record.setValue ("when", when.toMSecsSinceEpoch () / 1000);
  record.setValue ("call", call);
  record.setValue ("grid", grid);
  record.setValue ("report_sent", report_sent);
  record.setValue ("report_rcvd", report_received);
  record.setValue ("band", band);
  if (!m_->insertRecord (-1, record))
    {
      throw std::runtime_error {("SQL Error: " + m_->lastError ().text ()).toStdString ()};
    }
  if (!m_->submitAll ())
    {
      qDebug () << "type:" << m_->lastError ().type ();
      if (QSqlError::TransactionError == m_->lastError ().type ())
        {
          return false;
        }
      throw std::runtime_error {("SQL Error: " + m_->lastError ().text ()).toStdString ()};
    }
  return true;
}
