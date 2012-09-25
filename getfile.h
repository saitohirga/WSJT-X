#ifndef GETFILE_H
#define GETFILE_H
#include <QString>
#include <QFile>
#include <QDebug>
#include "commons.h"

void getfile(QString fname, bool xpol, int dbDgrd);
void savetf2(QString fname);
float gran();

#endif // GETFILE_H
