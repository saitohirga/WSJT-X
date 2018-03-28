// -*- Mode: C++ -*-
#ifndef DISPLAYTEXT_H
#define DISPLAYTEXT_H

#include <QTextEdit>
#include <QFont>
#include <QHash>
#include <QPair>
#include <QString>

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
        QColor color_DXCC, QColor color_NewCall, bool ppfx, bool bCQonly=false);
  void displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
			      QColor color_TxMsg, bool bFastMode);
  void displayQSY(QString text);
  void displayFoxToBeCalled(QString t, QColor bg);

  Q_SIGNAL void selectCallsign (Qt::KeyboardModifiers);
  Q_SIGNAL void erased ();

  Q_SLOT void appendText (QString const& text, QColor bg = Qt::white
                          , QString const& call1 = QString {}, QString const& call2 = QString {});
  Q_SLOT void erase ();
  Q_SLOT void highlight_callsign (QString const& callsign, QColor const& bg, QColor const& fg, bool last_only);

protected:
  void mouseDoubleClickEvent(QMouseEvent *e);

private:
  bool m_bPrincipalPrefix;
  QString appendDXCCWorkedB4(QString message, QString const& callsign, QColor * bg, LogBook const& logBook,
			     QColor color_CQ, QColor color_DXCC, QColor color_NewCall);

  QFont char_font_;
  QAction * erase_action_;
  QHash<QString, QPair<QColor, QColor>> highlighted_calls_;
};

#endif // DISPLAYTEXT_H
