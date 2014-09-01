#include <iostream>
#include <exception>
#include <stdexcept>
#include <string>

#include <locale.h>

#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QApplication>
#include <QRegularExpression>
#include <QObject>
#include <QSettings>
#include <QLibraryInfo>
#include <QSysInfo>
#include <QDir>
#include <QStandardPaths>
#include <QStringList>

#if QT_VERSION >= 0x050200
#include <QCommandLineParser>
#include <QCommandLineOption>
#endif

#include "revision_utils.hpp"

#include "SettingsGroup.hpp"
#include "TraceFile.hpp"
#include "mainwindow.h"

// Multiple instances:
QSharedMemory mem_jt9;
QString       my_key;

int main(int argc, char *argv[])
{
  QApplication a(argc, argv);
  try
    {
      setlocale (LC_NUMERIC, "C"); // ensure number forms are in
                                   // consistent format, do this after
                                   // instantiating QApplication so
                                   // that GUI has correct l18n
	      
      // Override programs executable basename as application name.
      a.setApplicationName ("WSJT-X");
#if CMAKE_BUILD
      a.setApplicationVersion (WSJTX_STRINGIZE (WSJTX_VERSION_MAJOR)
                               "." WSJTX_STRINGIZE (WSJTX_VERSION_MINOR)
                               "." WSJTX_STRINGIZE (WSJTX_VERSION_PATCH) " " + revision ());
#else
      a.setApplicationVersion ("1.4.0");
#endif

      bool multiple {false};

#if QT_VERSION >= 0x050200
      QCommandLineParser parser;
      parser.setApplicationDescription ("\nJT65A & JT9 Weak Signal Communications Program.");
      parser.addHelpOption ();
      parser.addVersionOption ();

#if WSJT_STANDARD_FILE_LOCATIONS
      // support for multiple instances running from a single installation
      QCommandLineOption rig_option (QStringList {} << "r" << "rig-name"
                                     , a.translate ("main", "Where <rig-name> is for multi-instance support.")
                                     , a.translate ("main", "rig-name"));
      parser.addOption (rig_option);
#endif

      QCommandLineOption test_option (QStringList {} << "test-mode"
                                      , a.translate ("main", "Writable files in test location.  Use with caution, for testing only."));
      parser.addOption (test_option);

      parser.process (a);

      QStandardPaths::setTestModeEnabled (parser.isSet (test_option));

#if WSJT_STANDARD_FILE_LOCATIONS
      // support for multiple instances running from a single installation
      if (parser.isSet (rig_option))
        {
          auto temp_name = parser.value (rig_option);
          if (!temp_name.isEmpty ())
            {
              if (temp_name.contains (QRegularExpression {R"([\\/])"}))
                {
                  std::cerr << QObject::tr ("Invalid rig name - \\ & / not allowed").toLocal8Bit ().data () << std::endl;
                  parser.showHelp (-1);
                }
                
              a.setApplicationName (a.applicationName () + " - " + temp_name);
            }
          multiple = true;
        }
#endif
#endif

      auto config_directory = QStandardPaths::writableLocation (QStandardPaths::ConfigLocation);
      QDir config_path {config_directory}; // will be "." if config_directory is empty
      if (!config_path.mkpath ("."))
        {
          throw std::runtime_error {"Cannot find a usable configuration path \"" + config_path.path ().toStdString () + '"'};
        }
      QSettings settings(config_path.absoluteFilePath (a.applicationName () + ".ini"), QSettings::IniFormat);

#if WSJT_QDEBUG_TO_FILE
      // // open a trace file
      TraceFile trace_file {QDir {QApplication::applicationDirPath ()}.absoluteFilePath ("wsjtx_trace.log")};

      // announce to trace file
      qDebug () << program_title (revision ()) + " - Program startup";
#endif

      // Create and initialize shared memory segment
      // Multiple instances: use rig_name as shared memory key
      my_key = a.applicationName ();
      mem_jt9.setKey(my_key);

      if(!mem_jt9.attach()) {
        if (!mem_jt9.create(sizeof(jt9com_))) {
          QMessageBox::critical (nullptr, "Error", "Unable to create shared memory segment.");
          exit(1);
        }
      }
      char *to = (char*)mem_jt9.data();
      int size=sizeof(jt9com_);
      if(jt9com_.newdat==0) {
      }
      memset(to,0,size);         //Zero all decoding params in shared memory

      unsigned downSampleFactor;
      {
        SettingsGroup {&settings, "Tune"};

        // deal with Windows Vista and earlier input audio rate
        // converter problems
        downSampleFactor = settings.value ("Audio/DisableInputResampling",
#if defined (Q_OS_WIN)
                                           // default to true for
                                           // Windows Vista and older
                                           QSysInfo::WV_VISTA >= QSysInfo::WindowsVersion ? true : false
#else
                                           false
#endif
                                           ).toBool () ? 1u : 4u;
      }

      MainWindow w(multiple, &settings, &mem_jt9, my_key, downSampleFactor, parser.isSet (test_option));
      w.show();

      QObject::connect (&a, SIGNAL (lastWindowClosed()), &a, SLOT (quit()));
      return a.exec();
    }
  catch (std::exception const& e)
    {
      QMessageBox::critical (nullptr, QObject::tr ("Error"), e.what ());
      std::cerr << "Error: " << e.what () << '\n';
    }
  catch (...)
    {
      QMessageBox::critical (nullptr, QObject::tr ("Unexpected"), QObject::tr ("Error"));
      std::cerr << "Unexpected error\n";
      throw;			// hoping the runtime might tell us more about the exception
    }
  return -1;
}
