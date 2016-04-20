#include <iostream>
#include <exception>
#include <stdexcept>
#include <string>

#include <locale.h>

#include <QDateTime>
#include <QApplication>
#include <QNetworkAccessManager>
#include <QRegularExpression>
#include <QObject>
#include <QSettings>
#include <QLibraryInfo>
#include <QSysInfo>
#include <QDir>
#include <QStandardPaths>
#include <QStringList>
#include <QMessageBox>
#include <QLockFile>
#include <QStack>

#if QT_VERSION >= 0x050200
#include <QCommandLineParser>
#include <QCommandLineOption>
#endif

#include "revision_utils.hpp"
#include "MetaDataRegistry.hpp"
#include "SettingsGroup.hpp"
#include "TraceFile.hpp"
#include "MultiSettings.hpp"
#include "mainwindow.h"
#include "commons.h"
#include "lib/init_random_seed.h"

namespace
{
  struct RNGSetup
  {
    RNGSetup ()
    {
      // one time seed of pseudo RNGs from current time
      auto seed = QDateTime::currentMSecsSinceEpoch ();
      qsrand (seed);            // this is good for rand() as well
    }
  } seeding;

  class MessageTimestamper
  {
  public:
    MessageTimestamper ()
    {
      prior_handlers_.push (qInstallMessageHandler (message_handler));
    }
    ~MessageTimestamper ()
    {
      if (prior_handlers_.size ()) qInstallMessageHandler (prior_handlers_.pop ());
    }

  private:
    static void message_handler (QtMsgType type, QMessageLogContext const& context, QString const& msg)
    {
      QtMessageHandler handler {prior_handlers_.top ()};
      if (handler)
        {
          handler (type, context,
                   QDateTime::currentDateTimeUtc ().toString ("yy-MM-ddTHH:mm:ss.zzzZ: ") + msg);
        }
    }
    static QStack<QtMessageHandler> prior_handlers_;
  };
  QStack<QtMessageHandler> MessageTimestamper::prior_handlers_;
}

int main(int argc, char *argv[])
{
  // Add timestamps to all debug messages
  MessageTimestamper message_timestamper;

  init_random_seed ();

  register_types ();            // make the Qt magic happen

  // Multiple instances:
  QSharedMemory mem_jt9;

  QApplication a(argc, argv);
  try
    {
      setlocale (LC_NUMERIC, "C"); // ensure number forms are in
                                   // consistent format, do this after
                                   // instantiating QApplication so
                                   // that GUI has correct l18n

      // Override programs executable basename as application name.
      a.setApplicationName ("WSJT-X");
      a.setApplicationVersion (version ());
      bool multiple {false};

#if QT_VERSION >= 0x050200
      QCommandLineParser parser;
      parser.setApplicationDescription ("\nJT65A & JT9 Weak Signal Communications Program.");
      auto help_option = parser.addHelpOption ();
      auto version_option = parser.addVersionOption ();

      // support for multiple instances running from a single installation
      QCommandLineOption rig_option (QStringList {} << "r" << "rig-name"
                                     , a.translate ("main", "Where <rig-name> is for multi-instance support.")
                                     , a.translate ("main", "rig-name"));
      parser.addOption (rig_option);

      QCommandLineOption test_option (QStringList {} << "test-mode"
                                      , a.translate ("main", "Writable files in test location.  Use with caution, for testing only."));
      parser.addOption (test_option);

      if (!parser.parse (a.arguments ()))
        {
          QMessageBox::critical (nullptr, a.applicationName (), parser.errorText ());
          return -1;
        }
      else
        {
          if (parser.isSet (help_option))
            {
              QMessageBox::information (nullptr, a.applicationName (), parser.helpText ());
              return 0;
            }
          else if (parser.isSet (version_option))
            {
              QMessageBox::information (nullptr, a.applicationName (), a.applicationVersion ());
              return 0;
            }
        }

      QStandardPaths::setTestModeEnabled (parser.isSet (test_option));

      // support for multiple instances running from a single installation
      if (parser.isSet (rig_option) || parser.isSet (test_option))
        {
          auto temp_name = parser.value (rig_option);
          if (!temp_name.isEmpty ())
            {
              if (temp_name.contains (QRegularExpression {R"([\\/,])"}))
                {
                  std::cerr << QObject::tr ("Invalid rig name - \\ & / not allowed").toLocal8Bit ().data () << std::endl;
                  parser.showHelp (-1);
                }
                
              a.setApplicationName (a.applicationName () + " - " + temp_name);
            }

          if (parser.isSet (test_option))
            {
              a.setApplicationName (a.applicationName () + " - test");
            }

          multiple = true;
        }

      // find the temporary files path
      QDir temp_dir {QStandardPaths::writableLocation (QStandardPaths::TempLocation)};
      Q_ASSERT (temp_dir.exists ()); // sanity check

      // disallow multiple instances with same instance key
      QLockFile instance_lock {temp_dir.absoluteFilePath (a.applicationName () + ".lock")};
      instance_lock.setStaleLockTime (0);
      bool lock_ok {false};
      while (!(lock_ok = instance_lock.tryLock ()))
        {
          if (QLockFile::LockFailedError == instance_lock.error ())
            {
              auto button = QMessageBox::question (nullptr
                                                   , QApplication::applicationName ()
                                                   , QObject::tr ("Another instance may be running, try to remove stale lock file?")
                                                   , QMessageBox::Yes | QMessageBox::Retry | QMessageBox::No
                                                   , QMessageBox::Yes);
              switch (button)
                {
                case QMessageBox::Yes:
                  instance_lock.removeStaleLockFile ();
                  break;

                case QMessageBox::Retry:
                  break;

                default:
                  throw std::runtime_error {"Multiple instances must have unique rig names"};
                }
            }
        }
#endif

#if WSJT_QDEBUG_TO_FILE
      // Open a trace file
      TraceFile trace_file {temp_dir.absoluteFilePath (a.applicationName () + "_trace.log")};
      qDebug () << program_title (revision ()) + " - Program startup";
#endif

      // Create a unique writeable temporary directory in a suitable location
      bool temp_ok {false};
      QString unique_directory {QApplication::applicationName ()};
      do
        {
          if (!temp_dir.mkpath (unique_directory)
              || !temp_dir.cd (unique_directory))
            {
              QMessageBox::critical (nullptr,
                                     "WSJT-X",
                                     QObject::tr ("Create temporary directory error: ") + temp_dir.absolutePath ());
              throw std::runtime_error {"Failed to create a temporary directory"};
            }
          if (!temp_dir.isReadable () || !(temp_ok = QTemporaryFile {temp_dir.absoluteFilePath ("test")}.open ()))
            {
              if (QMessageBox::Cancel == QMessageBox::critical (nullptr,
                                                                "WSJT-X",
                                                                QObject::tr ("Create temporary directory error:\n%1\n"
                                                                    "Another application may be locking the directory").arg (temp_dir.absolutePath ()),
                                                                QMessageBox::Retry | QMessageBox::Cancel))
                {
                  throw std::runtime_error {"Failed to create a usable temporary directory"};
                }
              temp_dir.cdUp ();  // revert to parent as this one is no good
            }
        }
      while (!temp_ok);

      MultiSettings multi_settings;

      int result;
      do
        {
#if WSJT_QDEBUG_TO_FILE
          // announce to trace file and dump settings
          qDebug () << "++++++++++++++++++++++++++++ Settings ++++++++++++++++++++++++++++";
          for (auto const& key: multi_settings.settings ()->allKeys ())
            {
              auto const& value = multi_settings.settings ()->value (key);
              if (value.canConvert<QVariantList> ())
                {
                  auto const sequence = value.value<QSequentialIterable> ();
                  qDebug ().nospace () << key << ": ";
                  for (auto const& item: sequence)
                    {
                      qDebug ().nospace () << '\t' << item;
                    }
                }
              else
                {
                  qDebug ().nospace () << key << ": " << value;
                }
            }
          qDebug () << "---------------------------- Settings ----------------------------";
#endif

          // Create and initialize shared memory segment
          // Multiple instances: use rig_name as shared memory key
          mem_jt9.setKey(a.applicationName ());

          if(!mem_jt9.attach()) {
            if (!mem_jt9.create(sizeof(struct dec_data))) {
              QMessageBox::critical (nullptr, "Error", "Unable to create shared memory segment.");
              exit(1);
            }
          }
          memset(mem_jt9.data(),0,sizeof(struct dec_data)); //Zero all decoding params in shared memory

          unsigned downSampleFactor;
          {
            SettingsGroup {multi_settings.settings (), "Tune"};

            // deal with Windows Vista and earlier input audio rate
            // converter problems
            downSampleFactor = multi_settings.settings ()->value ("Audio/DisableInputResampling",
#if defined (Q_OS_WIN)
                                                                  // default to true for
                                                                  // Windows Vista and older
                                                                  QSysInfo::WV_VISTA >= QSysInfo::WindowsVersion ? true : false
#else
                                                                  false
#endif
                                                                  ).toBool () ? 1u : 4u;
          }

          // run the application UI
          MainWindow w(temp_dir, multiple, &multi_settings, &mem_jt9, downSampleFactor, new QNetworkAccessManager {&a});
          w.show();
          QObject::connect (&a, SIGNAL (lastWindowClosed()), &a, SLOT (quit()));
          result = a.exec();
        }
      while (!result && !multi_settings.exit ());
      temp_dir.removeRecursively (); // clean up temp files
      return result;
    }
  catch (std::exception const& e)
    {
      QMessageBox::critical (nullptr, a.applicationName (), e.what ());
      std::cerr << "Error: " << e.what () << '\n';
    }
  catch (...)
    {
      QMessageBox::critical (nullptr, a.applicationName (), QObject::tr ("Unexpected error"));
      std::cerr << "Unexpected error\n";
      throw;			// hoping the runtime might tell us more about the exception
    }
  return -1;
}
