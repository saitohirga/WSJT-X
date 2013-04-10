#include <QtGui>
#include <QtGui/QApplication>
#include "mainwindow.h"

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

  MainWindow w;
  w.show();
  return a.exec();
}
