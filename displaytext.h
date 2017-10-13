// -*- Mode: C++ -*-
#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextEdit>
#include <QFont>

#include "logbook/logbook.h"
#include "decodedtext.h"

class QAction;

class DisplayText
  : public QTextEdit
{
  Q_OBJECT
public:
  explicit DisplayText(QWidget *parent = 0);

  void setContentFont (QFont const&);
  void insertLineSpacer(QString const&);
  void displayDecodedText(DecodedText const& decodedText, QString const& myCall, bool displayDXCCEntity,
			  LogBook const& logBook, QColor color_CQ, QColor color_MyCall,
			  QColor color_DXCC, QColor color_NewCall);
  void displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
			      QColor color_TxMsg, bool bFastMode);
  void displayQSY(QString text);

  Q_SIGNAL void selectCallsign (Qt::KeyboardModifiers);
  Q_SIGNAL void erased ();

  Q_SLOT void appendText (QString const& text, QColor bg = Qt::white);
  Q_SLOT void erase ();

protected:
  void mouseDoubleClickEvent(QMouseEvent *e);

private:
  QString appendDXCCWorkedB4(QString message, QString const& callsign, QColor * bg, LogBook const& logBook,
			     QColor color_CQ, QColor color_DXCC, QColor color_NewCall);

  QFont char_font_;
  QAction * erase_action_;
};

#endif // DISPLAYTEXT_H
