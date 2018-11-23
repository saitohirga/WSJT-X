#include "FoxLog.hpp"

#include <stdexcept>
#include <utility>
#include <QString>
#include <QDateTime>
#include <QSqlDatabase>
#include <QSqlTableModel>
#include <QSqlRecord>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>
#include "qt_db_helpers.hpp"
#include "pimpl_impl.hpp"

class FoxLog::impl final
  : public QSqlTableModel
{
public:
  impl ();

  QSqlQuery mutable dupe_query_;
};

FoxLog::impl::impl ()
{
  if (!database ().tables ().contains ("fox_log"))
    {
      QSqlQuery query;
      SQL_error_check (query, static_cast<bool (QSqlQuery::*) (QString const&)> (&QSqlQuery::exec),
                       "CREATE TABLE fox_log ("
                       "	id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"
                       "	\"when\" DATETIME NOT NULL,"
                       "	call VARCHAR(20) NOT NULL,"
                       "	grid VARCHAR(4),"
                       "	report_sent VARCHAR(3),"
                       "	report_rcvd VARCHAR(3),"
                       "	band VARCHAR(6) NOT NULL,"
                       "	CONSTRAINT no_dupes UNIQUE (call, band)"
                       ")");
    }

  SQL_error_check (dupe_query_, &QSqlQuery::prepare,
                   "SELECT COUNT(*) FROM fox_log WHERE call = :call AND band = :band");

  setEditStrategy (QSqlTableModel::OnManualSubmit);
  setTable ("fox_log");
  setHeaderData (fieldIndex ("when"), Qt::Horizontal, tr ("Date & Time(UTC)"));
  setHeaderData (fieldIndex ("call"), Qt::Horizontal, tr ("Call"));
  setHeaderData (fieldIndex ("grid"), Qt::Horizontal, tr ("Grid"));
  setHeaderData (fieldIndex ("report_sent"), Qt::Horizontal, tr ("Sent"));
  setHeaderData (fieldIndex ("report_rcvd"), Qt::Horizontal, tr ("Rcvd"));
  setHeaderData (fieldIndex ("band"), Qt::Horizontal, tr ("Band"));
  SQL_error_check (*this, &QSqlTableModel::select);
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

namespace
{
  void set_value_maybe_null (QSqlRecord& record, QString const& name, QString const& value)
  {
    if (value.size ())
      {
        record.setValue (name, value);
      }
    else
      {
        record.setNull (name);
      }
  }
}

bool FoxLog::add_QSO (QDateTime const& when, QString const& call, QString const& grid
                      , QString const& report_sent, QString const& report_received
                      , QString const& band)
{
  ConditionalTransaction transaction {*m_};
  auto record = m_->record ();
  if (!when.isNull ())
    {
      record.setValue ("when", when.toMSecsSinceEpoch () / 1000);
    }
  else
    {
      record.setNull ("when");
    }
  set_value_maybe_null (record, "call", call);
  set_value_maybe_null (record, "grid", grid);
  set_value_maybe_null (record, "report_sent", report_sent);
  set_value_maybe_null (record, "report_rcvd", report_received);
  set_value_maybe_null (record, "band", band);
  SQL_error_check (*m_, &QSqlTableModel::insertRecord, -1, record);
  if (!transaction.submit (false))
    {
      transaction.revert ();
      return false;
    }
  return true;
}

bool FoxLog::dupe (QString const& call, QString const& band) const
{
  m_->dupe_query_.bindValue (":call", call);
  m_->dupe_query_.bindValue (":band", band);
  SQL_error_check (m_->dupe_query_, static_cast<bool (QSqlQuery::*) ()> (&QSqlQuery::exec));
  m_->dupe_query_.next ();
  return m_->dupe_query_.value (0).toInt ();
}

void FoxLog::reset ()
{
  if (m_->rowCount ())
    {
      ConditionalTransaction transaction {*m_};
      SQL_error_check (*m_, &QSqlTableModel::removeRows, 0, m_->rowCount (), QModelIndex {});
      transaction.submit ();
    }
}
