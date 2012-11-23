#include "displaytext.h"
#include <QDebug>
#include <QMouseEvent>

DisplayText::DisplayText(QWidget *parent) :
    QTextBrowser(parent)
{
}

void DisplayText::mouseDoubleClickEvent(QMouseEvent *e)
{
  bool ctrl = (e->modifiers() & Qt::ControlModifier);
  emit(selectCallsign(ctrl));
  QTextBrowser::mouseDoubleClickEvent(e);
}
