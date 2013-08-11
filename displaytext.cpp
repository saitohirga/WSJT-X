#include "displaytext.h"
#include <QDebug>
#include <QMouseEvent>


DisplayText::DisplayText(QWidget *parent) :
    QTextBrowser(parent)
{
    _fontWidth = 8; // typical
    _maxDisplayedCharacters = 48; // a nominal safe(?) value
}

void DisplayText::mouseDoubleClickEvent(QMouseEvent *e)
{
  bool ctrl = (e->modifiers() & Qt::ControlModifier);
  bool shift = (e->modifiers() & Qt::ShiftModifier);
  emit(selectCallsign(shift,ctrl));
  QTextBrowser::mouseDoubleClickEvent(e);
}


void DisplayText::setFont(QFont font)
{
  QFontMetrics qfm(font);
  _fontWidth = qfm.averageCharWidth()+1;  // the plus one is emperical
  QTextBrowser::setFont(font);
}

void DisplayText::resizeEvent(QResizeEvent * event)
{
    if (_fontWidth > 0 && _fontWidth < 999)
        _maxDisplayedCharacters = width()/_fontWidth;
    QTextBrowser::resizeEvent(event);
}
