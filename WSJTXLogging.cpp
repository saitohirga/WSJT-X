#include "WSJTXLogging.hpp"

#include <sstream>

#include <boost/container/flat_map.hpp>

#include <QFile>
#include <QTextStream>
#include <QString>
#include <QStandardPaths>
#include <QRegularExpression>
#include <QMessageLogContext>

#include "Logger.hpp"
#include "qt_helpers.hpp"

namespace logging = boost::log;
namespace container = boost::container;

WSJTXLogging::WSJTXLogging ()
{
  QFile log_config {QStandardPaths::locate (QStandardPaths::ConfigLocation, "wsjtx_log_config.ini")};
  if (!log_config.exists ())
    {
      log_config.setFileName (":/wsjtx_log_config.ini");
    }
  if (log_config.open (QFile::ReadOnly) && log_config.isReadable ())
    {
      QTextStream ts {&log_config};
      auto config = ts.readAll ();

      // substitute variable
      container::flat_map<QString, QString> replacements =
        {
         {"DesktopLocation", QStandardPaths::writableLocation (QStandardPaths::DesktopLocation)},
         {"DocumentsLocation", QStandardPaths::writableLocation (QStandardPaths::DocumentsLocation)},
         {"TempLocation", QStandardPaths::writableLocation (QStandardPaths::TempLocation)},
         {"HomeLocation", QStandardPaths::writableLocation (QStandardPaths::HomeLocation)},
         {"CacheLocation", QStandardPaths::writableLocation (QStandardPaths::CacheLocation)},
         {"GenericCacheLocation", QStandardPaths::writableLocation (QStandardPaths::GenericCacheLocation)},
         {"GenericDataLocation", QStandardPaths::writableLocation (QStandardPaths::GenericDataLocation)},
         {"AppDataLocation", QStandardPaths::writableLocation (QStandardPaths::AppDataLocation)},
         {"AppLocalDataLocation", QStandardPaths::writableLocation (QStandardPaths::AppLocalDataLocation)},
        };
      QString new_config;
      int pos {0};
      QRegularExpression subst_vars {R"(\${([^}]+)})"};
      auto iter = subst_vars.globalMatch (config);
      while (iter.hasNext ())
        {
          auto match = iter.next ();
          auto const& name = match.captured (1);
          auto repl_iter = replacements.find (name);
          auto repl = repl_iter != replacements.end () ? repl_iter->second : "${" + name + "}";
          new_config += config.mid (pos, match.capturedStart (1) - 2 - pos) + repl;
          pos = match.capturedEnd (0);
        }
      new_config += config.mid (pos);
      std::stringbuf buffer {new_config.toStdString (), std::ios_base::in};
      std::istream stream {&buffer};
      Logger::init_from_config (stream);
    }
  else
    {
      LOG_WARN ("Unable to read logging configuration file: " << log_config.fileName ());
    }
}

WSJTXLogging::~WSJTXLogging ()
{
  LOG_INFO ("Log Finish");
  auto lg = logging::core::get ();
  lg->flush ();
  lg->remove_all_sinks ();
}

// Reroute Qt messages to the system logger
void WSJTXLogging::qt_log_handler (QtMsgType type, QMessageLogContext const& context, QString const& msg)
{
  // Convert Qt message types to logger severities
  auto severity = boost::log::trivial::trace;
  switch (type)
    {
    case QtDebugMsg: severity = boost::log::trivial::debug; break;
    case QtInfoMsg: severity = boost::log::trivial::info; break;
    case QtWarningMsg: severity = boost::log::trivial::warning; break;
    case QtCriticalMsg: severity = boost::log::trivial::error; break;
    case QtFatalMsg: severity = boost::log::trivial::fatal; break;
    }
  // Map non-default Qt categories to logger channels, Qt logger
  // context is mapped to the appropriate logger attributes.
  auto log = Logger::sys::get ();
  if (!qstrcmp (context.category, "default"))
    {
      BOOST_LOG_SEV (log, severity)
        << boost::log::add_value ("Line", context.line)
        << boost::log::add_value ("File", context.file)
        << boost::log::add_value ("Function", context.function)
        << msg.toStdString ();
    }
  else
    {
      BOOST_LOG_CHANNEL_SEV (log, context.category, severity)
        << boost::log::add_value ("Line", context.line)
        << boost::log::add_value ("File", context.file)
        << boost::log::add_value ("Function", context.function)
        << msg.toStdString ();
    }
  if (QtFatalMsg == type)
    {
      // bail out
      throw std::runtime_error {"Fatal Qt Error"};
    }
}
