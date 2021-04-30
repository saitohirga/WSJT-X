#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QApplication>

#include "revision_utils.hpp"
#include "mainwindow.h"

static QtMessageHandler default_message_handler;

void my_message_handler (QtMsgType type, QMessageLogContext const& context, QString const& msg)
{
  // Handle the messages!

  // Call the default handler.
  (*default_message_handler) (type, context, msg);
}

int main(int argc, char *argv[])
{
  default_message_handler = qInstallMessageHandler (my_message_handler);

  QApplication a {argc, argv};
  // Override programs executable basename as application name.
  a.setApplicationName ("MAP65");
  a.setApplicationVersion ("3.0.0-devel");
  MainWindow w;
  w.show ();
  return a.exec ();
}
