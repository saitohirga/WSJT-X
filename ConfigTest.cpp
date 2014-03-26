#include <iostream>
#include <exception>

#include <locale.h>

#include <QApplication>
#include <QSettings>
#include <QDir>
#include <QDebug>

#include "GetUserId.hpp"
#include "TraceFile.hpp"
#include "TestConfiguration.hpp"
#include "AudioDevice.hpp"
#include "TransceiverFactory.hpp"
#include "Configuration.hpp"

int main (int argc, char *argv[])
{
  try
    {
      QApplication application {argc, argv};
      setlocale (LC_NUMERIC, "C"); // ensure number forms are in
				   // consistent format, do this after
				   // instantiating QApplication so
				   // that GUI has correct l18n

      // get a unique id from the user
      auto id = get_user_id ();

      // open a user specific trace file
      TraceFile trace_file {QDir {QApplication::applicationDirPath () + "/logs"}.absoluteFilePath (id + "_config_test.log")};

      // announce to log file
      qDebug () << "Configuration Test v" WSJTX_STRINGIZE (CONFIG_TEST_VERSION_MAJOR) "." WSJTX_STRINGIZE (CONFIG_TEST_VERSION_MINOR) "." WSJTX_STRINGIZE (CONFIG_TEST_VERSION_PATCH) ", " WSJTX_STRINGIZE (SVNVERSION) " - Program startup";

      // open user specific settings
      QSettings settings {QDir {QApplication::applicationDirPath () + "/settings"}.absoluteFilePath (id + "_config_test.ini"), QSettings::IniFormat};

      // the test GUI
      TestConfiguration main_window ("ConfigTest", &settings);

      // hook up close down mechanism
      QObject::connect (&application, SIGNAL (lastWindowClosed ()), &application, SLOT (quit ()));

      // start event loop
      auto status = application.exec();
      qDebug () << "Normal exit with status: " << status;
      return status;
    }
  catch (std::exception const& e)
    {
      qDebug () << "Error exit: " << e.what () << '\n';
      std::cerr << "Error: " << e.what () << '\n';
    }
  catch (...)
    {
      qDebug () << "Unknown error exit\n";
      std::cerr << "Unexpected error\n";
      throw; // hoping the runtime might tell us more about the exception
    }
  return -1;
}
