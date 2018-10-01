#include "LotWUsers.hpp"

#include <future>

#include <QHash>
#include <QString>
#include <QDate>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QFileInfo>
#include <QPointer>
#include <QSaveFile>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QDebug>

#include "Configuration.hpp"

#include "pimpl_impl.hpp"

#include "moc_LotWUsers.cpp"

namespace
{
  // Dictionary mapping call sign to date of last upload to LotW
  using dictionary = QHash<QString, QDate>;
}

class LotWUsers::impl final
  : public QObject
{
  Q_OBJECT

public:
  impl (LotWUsers * self, QNetworkAccessManager * network_manager, QString const& lotw_csv_file)
    : self_ {self}
    , network_manager_ {network_manager}
    , csv_file_ {lotw_csv_file}
    , url_valid_ {false}
    , redirect_count_ {0}
  {
  }

  void load (bool forced_fetch)
  {
    auto csv_file_name = csv_file_.fileName ();
    abort ();                   // abort any active download
    if (!QFileInfo::exists (csv_file_name) || forced_fetch)
      {
        current_url_.setUrl ("https://lotw.arrl.org/lotw-user-activity.csv");
        redirect_count_ = 0;
        download (current_url_);
      }
    else
      {
        // load the database asynchronously
        future_load_ = std::async (std::launch::async, &LotWUsers::impl::load_dictionary, this, csv_file_name);
      }
  }

  void download (QUrl url)
  {
    if (QNetworkAccessManager::Accessible != network_manager_->networkAccessible ()) {
      // try and recover network access for QNAM
      network_manager_->setNetworkAccessible (QNetworkAccessManager::Accessible);
    }

    if (url.isValid () && !QSslSocket::supportsSsl ())
      {
        url.setScheme ("http");
      }
    QNetworkRequest request {url};
    request.setRawHeader ("User-Agent", "WSJT LotW User Downloader");
    request.setOriginatingObject (this);

    // this blocks for a second or two the first time it is used on
    // Windows - annoying
    if (!url_valid_)
      {
        reply_ = network_manager_->head (request);
      }
    else
      {
        reply_ = network_manager_->get (request);
      }

    connect (reply_.data (), &QNetworkReply::finished, this, &LotWUsers::impl::reply_finished);
    connect (reply_.data (), &QNetworkReply::readyRead, this, &LotWUsers::impl::store);
  }

  void reply_finished ()
  {
    if (!reply_) return;        // we probably deleted it in an
                                // earlier call
    QUrl redirect_url {reply_->attribute (QNetworkRequest::RedirectionTargetAttribute).toUrl ()};
    if (reply_->error () == QNetworkReply::NoError && !redirect_url.isEmpty ())
      {
        if (++redirect_count_ < 10) // maintain sanity
          {
            // follow redirect
            download (reply_->url ().resolved (redirect_url));
          }
        else
          {
            Q_EMIT self_->LotW_users_error (tr ("Network Error - Too many redirects:\n\'%1\'")
                                            .arg (redirect_url.toDisplayString ()));
            url_valid_ = false; // reset
          }
      }
    else if (reply_->error () != QNetworkReply::NoError)
      {
        csv_file_.cancelWriting ();
        csv_file_.commit ();
        url_valid_ = false;     // reset
        // report errors that are not due to abort
        if (QNetworkReply::OperationCanceledError != reply_->error ())
          {
            Q_EMIT self_->LotW_users_error (tr ("Network Error:\n%1")
                                            .arg (reply_->errorString ()));
          }
      }
    else
      {
        if (url_valid_ && !csv_file_.commit ())
          {
            Q_EMIT self_->LotW_users_error (tr ("File System Error - Cannot commit changes to:\n\"%1\"")
                                            .arg (csv_file_.fileName ()));
            url_valid_ = false; // reset
          }
        else
          {
            if (!url_valid_)
              {
                // now get the body content
                url_valid_ = true;
                download (reply_->url ().resolved (redirect_url));
              }
            else
              {
                url_valid_ = false; // reset
                qDebug () << "LotW Users Data downloaded from" << reply_->url ().toDisplayString ();
                // load the database asynchronously
                future_load_ = std::async (std::launch::async, &LotWUsers::impl::load_dictionary, this, csv_file_.fileName ());
              }
          }
      }
    if (reply_ && reply_->isFinished ())
      {
        reply_->deleteLater ();
      }
  }

  void store ()
  {
    if (url_valid_)
      {
        if (!csv_file_.isOpen ())
          {
            // create temporary file in the final location
            if (!csv_file_.open (QSaveFile::WriteOnly))
              {
                abort ();
                Q_EMIT self_->LotW_users_error (tr ("File System Error - Cannot open file:\n\"%1\"\nError(%2): %3")
                                                .arg (csv_file_.fileName ())
                                                .arg (csv_file_.error ())
                                                .arg (csv_file_.errorString ()));
              }
          }
        if (csv_file_.write (reply_->read (reply_->bytesAvailable ())) < 0)
          {
            abort ();
            Q_EMIT self_->LotW_users_error (tr ("File System Error - Cannot write to file:\n\"%1\"\nError(%2): %3")
                                            .arg (csv_file_.fileName ())
                                            .arg (csv_file_.error ())
                                            .arg (csv_file_.errorString ()));
          }
      }
  }

  void abort ()
  {
    if (reply_ && reply_->isRunning ())
      {
        reply_->abort ();
      }
  }

  // Load the database from the given file name
  //
  // Expects the file to be in CSV format with no header with one
  // record per line. Record fields are call sign followed by upload
  // date in yyyy-MM-dd format followed by upload time (ignored)
  dictionary load_dictionary (QString const& lotw_csv_file)
  {
    dictionary result;
    QFile f {lotw_csv_file};
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

  LotWUsers * self_;
  QNetworkAccessManager * network_manager_;
  QSaveFile csv_file_;
  bool url_valid_;
  QUrl current_url_;            // may be a redirect
  int redirect_count_;
  QPointer<QNetworkReply> reply_;
  std::future<dictionary> future_load_;
  dictionary last_uploaded_;
};

#include "LotWUsers.moc"

LotWUsers::LotWUsers (Configuration const * configuration, QNetworkAccessManager * network_manager
                      , QObject * parent)
  : QObject {parent}
  , m_ {this
        , network_manager
        , configuration->writeable_data_dir ().absoluteFilePath ("lotw-user-activity.csv")}
{
  m_->load (false);
}

LotWUsers::~LotWUsers ()
{
}

void LotWUsers::download_new_file ()
{
  m_->load (true);
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
