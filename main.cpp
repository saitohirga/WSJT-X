#include <QtGui>
#include <QtGui/QApplication>
#include <portaudio.h>
#include "mainwindow.h"

QSharedMemory mem_jt9("mem_jt9");

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

  MainWindow w(&mem_jt9);
  w.show();
  return a.exec();
}
