// -*- Mode: C++ -*-
#ifndef SIGNALMETER_H
#define SIGNALMETER_H

#include <QtGui>
#include <QLabel>
#include <meterwidget.h>

class SignalMeter : public QWidget
{
    Q_OBJECT
    
public:
    explicit SignalMeter(QWidget *parent = 0);
    ~SignalMeter();

public slots:
    void setValue(int value);

private:
    MeterWidget *m_meter;

    QLabel *m_label;

protected:
    void paintEvent( QPaintEvent * );
    void resizeEvent(QResizeEvent *s);
};

#endif // SIGNALMETER_H
