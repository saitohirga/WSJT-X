// -*- Mode: C++ -*-
#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextEdit>
#include "logbook/logbook.h"
#include "decodedtext.h"


class DisplayText : public QTextEdit
{
    Q_OBJECT
public:
    explicit DisplayText(QWidget *parent = 0);

    void setContentFont (QFont const&);
    void insertLineSpacer(QString const&);
    void displayDecodedText(DecodedText decodedText, QString myCall, bool displayDXCCEntity,
                            LogBook logBook, QColor color_CQ, QColor color_MyCall,
                            QColor color_DXCC, QColor color_NewCall);
    void displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
                                QColor color_TxMsg, bool bFastMode);
    void displayQSY(QString text);

signals:
    void selectCallsign(bool alt, bool ctrl);

public slots:
  void appendText(QString const& text, QString const& bg = "white");

protected:
    void mouseDoubleClickEvent(QMouseEvent *e);

private:
  QString _appendDXCCWorkedB4(QString message, QString const& callsign, QString * bg, LogBook logBook,
                 QColor color_CQ, QColor color_DXCC, QColor color_NewCall);

  QTextCharFormat m_charFormat;
};

#endif // DISPLAYTEXT_H
