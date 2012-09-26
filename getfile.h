#ifndef GETFILE_H
#define GETFILE_H
#include <QString>
#include <QFile>
#include <QDebug>
#include "commons.h"

void getfile(QString fname, int ntrperiod);
void savetf2(QString fname, int ntrperiod);
float gran();

#endif // GETFILE_H
