#ifndef WSJTX_LOGGING_HPP__
#define WSJTX_LOGGING_HPP__

#include <QtGlobal>

class QString;

//
// Class WSJTXLogging - wraps application specific logging
//
class WSJTXLogging final
{
public:
  explicit WSJTXLogging ();
  ~WSJTXLogging ();

  //
  // Install this as the Qt message handler (qInstallMessageHandler)
  // to integrate Qt messages.
  static void qt_log_handler (QtMsgType type, QMessageLogContext const& context, QString const&);
};

#endif
