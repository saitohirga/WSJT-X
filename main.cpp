#ifdef QT5
#include <QtWidgets>
#else
#include <QtGui>
#endif
#include <QApplication>
#include <portaudio.h>
#include "mainwindow.h"

// Multiple instances:
QSharedMemory mem_jt9;
QUuid         my_uuid;
QString       my_key;

int main(int argc, char *argv[])
{
  QApplication a(argc, argv);

  QFile f("fonts.txt");
  if(f.open(QIODevice::ReadOnly)) {
     QTextStream in(&f);                          //Example:
     QString fontFamily;                          // helvetica
     qint32 fontSize,fontWeight;                  // 8,50
     in >> fontFamily >> fontSize >> fontWeight;
     f.close();
     QFont font;
     font=QFont(fontFamily,fontSize,fontWeight);
     a.setFont(font);
  }

  // Create and initialize shared memory segment
  // Multiple instances: generate shared memory keys with UUID
  my_uuid = QUuid::createUuid();
  my_key = my_uuid.toString();
  mem_jt9.setKey(my_key);

  if(!mem_jt9.attach()) {
    if (!mem_jt9.create(sizeof(jt9com_))) {
      QMessageBox::critical( 0, "Error", "Unable to create shared memory segment.");
      exit(1);
    }
  }
  char *to = (char*)mem_jt9.data();
  int size=sizeof(jt9com_);
  if(jt9com_.newdat==0) {
  }
  memset(to,0,size);         //Zero all decoding params in shared memory

  //Initialize Portaudio
  PaError paerr=Pa_Initialize();
  if(paerr!=paNoError) {
    QMessageBox::critical( 0, "Error", "Unable to initialize PortAudio.");
    exit(1);
  }

// Multiple instances:  Call MainWindow() with the UUID key
  MainWindow w(&mem_jt9, &my_key);
  w.show();
  return a.exec();
}
