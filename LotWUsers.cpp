#include "LotWUsers.hpp"

#include <future>

#include <QHash>
#include <QString>
#include <QDate>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QDebug>

#include "Configuration.hpp"

#include "pimpl_impl.hpp"

#include "moc_LotWUsers.cpp"

namespace
{
  // Dictionary mapping call sign to date of last upload to LotW
  using dictionary = QHash<QString, QDate>;

  // Load the database from the given file name
  //
  // Expects the file to be in CSV format with no header with one
  // record per line. Record fields are call sign followed by upload
  // date in yyyy-MM-dd format followed by upload time (ignored)
  dictionary load (QString const& lotw_users_file)
  {
    dictionary result;
    QFile f {lotw_users_file};
    if (f.open (QFile::ReadOnly | QFile::Text))
      {
        QTextStream s {&f};
        for (auto l = s.readLine (); !l.isNull (); l = s.readLine ())
          {
            auto pos = l.indexOf (',');
            result[l.left (pos)] = QDate::fromString (l.mid (pos + 1, l.indexOf (',', pos + 1) - pos - 1), "yyyy-MM-dd");
          }
        qDebug () << "LotW User Data Loaded";
      }
    else
      {
        throw std::runtime_error {QObject::tr ("Failed to open LotW users CSV file: '%1'").arg (f.fileName ()).toLocal8Bit ()};
      }
    return result;
  }
}

class LotWUsers::impl final
{
public:
  std::future<dictionary> future_load_;
  dictionary last_uploaded_;
};

LotWUsers::LotWUsers (Configuration const * configuration, QObject * parent)
  : QObject {parent}
{
  // load the database asynchronously
  m_->future_load_ = std::async (std::launch::async, load, configuration->writeable_data_dir ().absoluteFilePath ("lotw-user-activity.csv"));
}

LotWUsers::~LotWUsers ()
{
}

bool LotWUsers::user (QString const& call, qint64 uploaded_since_days) const
{
  if (m_->future_load_.valid ())
    {
      try
        {
          // wait for the load to finish if necessary
          const_cast<dictionary&> (m_->last_uploaded_) = const_cast<std::future<dictionary>&> (m_->future_load_).get ();
        }
      catch (std::exception const& e)
        {
          Q_EMIT LotW_users_error (e.what ());
        }
    }
  auto p = m_->last_uploaded_.constFind (call);
  if (p != m_->last_uploaded_.end ())
    {
      return p.value ().daysTo (QDate::currentDate ()) <= uploaded_since_days;
    }
  return false;
}
