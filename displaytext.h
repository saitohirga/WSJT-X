// -*- Mode: C++ -*-
#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextBrowser>
#include "logbook/logbook.h"
#include "decodedtext.h"


class DisplayText : public QTextBrowser
{
    Q_OBJECT
public:
    explicit DisplayText(QWidget *parent = 0);

    void setFont(QFont const& font);

    void insertLineSpacer();
    void displayDecodedText(DecodedText decodedText, QString myCall, bool displayDXCCEntity,
                            LogBook logBook, QColor color_CQ, QColor color_MyCall,
                            QColor color_DXCC, QColor color_NewCall);
    void displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
                                QColor color_TxMsg);

signals:
    void selectCallsign(bool shift, bool ctrl);

public slots:


protected:
    void mouseDoubleClickEvent(QMouseEvent *e);
    void resizeEvent(QResizeEvent * event);

private:
    int _fontWidth;
    int _maxDisplayedCharacters;
    void _insertText(const QString text, const QString bg);
    void _appendDXCCWorkedB4(/*mod*/DecodedText& t1, QString &bg, LogBook logBook,
                 QColor color_CQ, QColor color_DXCC, QColor color_NewCall);

};

#endif // DISPLAYTEXT_H
