#include <fftw3.h>
#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QApplication>

#include "revision_utils.hpp"
#include "mainwindow.h"

extern "C" {
  // Fortran procedures we need
  void four2a_ (_Complex float *, int * nfft, int * ndim, int * isign, int * iform, int len);
}

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
  auto result = a.exec ();

  // clean up lazily initialized FFTW3 resources
  {
    int nfft {-1};
    int ndim {1};
    int isign {1};
    int iform {1};
    // free FFT plan resources
    four2a_ (nullptr, &nfft, &ndim, &isign, &iform, 0);
  }
  fftwf_forget_wisdom ();
  fftwf_cleanup ();

  return result;
}
