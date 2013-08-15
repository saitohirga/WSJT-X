#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextBrowser>
#include "logbook/logbook.h"

class DisplayText : public QTextBrowser
{
    Q_OBJECT
public:
    explicit DisplayText(QWidget *parent = 0);

    void setFont(QFont font);

    void insertLineSpacer();
    void displayDecodedText(QString decodedText, QString myCall, bool displayDXCCEntity, LogBook logBook);

signals:
    void selectCallsign(bool shift, bool ctrl);

public slots:


protected:
    void mouseDoubleClickEvent(QMouseEvent *e);
    void resizeEvent(QResizeEvent * event);

private:
    int _fontWidth;
    int _maxDisplayedCharacters;
    void _appendDXCCWorkedB4(/*mod*/QString& t1, QString &bg, LogBook logBook);

};

#endif // DISPLAYTEXT_H
