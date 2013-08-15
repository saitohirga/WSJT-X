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



void DisplayText::insertLineSpacer()
{
    QTextCursor cursor;
    QTextBlockFormat bf;
    QString bg="#d3d3d3";
    bf.setBackground(QBrush(QColor(bg)));
    QString tt="----------------------------------------";
    QString s = "<table border=0 cellspacing=0 width=100%><tr><td bgcolor=\"" +
            bg + "\"><pre>" + tt + "</pre></td></tr></table>";
    cursor = this->textCursor();
    cursor.movePosition(QTextCursor::End);
    bf = cursor.blockFormat();
    bf.setBackground(QBrush(QColor(bg)));
    cursor.insertHtml(s);
}


void DisplayText::_appendDXCCWorkedB4(/*mod*/QString& t1, QString& bg, /*uses*/LogBook logBook)
{
    // extract the CQer's call   TODO: does this work with all call formats?  What about 'CQ DX'?
    int s1 = 4 + t1.indexOf(" CQ ");
    int s2 = t1.indexOf(" ",s1);
    QString call = t1.mid(s1,s2-s1);
    QString countryName;
    bool callWorkedBefore;
    bool countryWorkedBefore;
    logBook.match(/*in*/call,/*out*/countryName,callWorkedBefore,countryWorkedBefore);

    int charsAvail = _maxDisplayedCharacters;

    // the decoder (seems) to always generate 40 chars. For a normal CQ call, the last five are spaces
    t1 = t1.left(36);  // reduce trailing white space  TODO this magic 36 is also referenced in MainWindow::doubleClickOnCall()
    charsAvail -= 36;
    if (charsAvail > 4)
    {
        if (!countryWorkedBefore) // therefore not worked call either
        {
            t1 += "!";
            bg = "#66ff66"; // strong green
        }
        else
            if (!callWorkedBefore) // but have worked the country
            {
                t1 += "~";
                bg = "#76cd76"; // mid green
            }
            else
            {
                t1 += " ";  // have worked this call before
                bg="#9cc79c"; // pale green
            }
        charsAvail -= 1;

        if (countryName.length()>charsAvail)
            countryName = countryName.left(1)+"."+countryName.right(charsAvail-2);  //abreviate the first word to the first letter, show remaining right most chars
        t1 += countryName;
    }
}

void DisplayText::displayDecodedText(QString decodedText, QString myCall, bool displayDXCCEntity, LogBook logBook)
{
    QString bg="white";
    bool CQcall = false;
    if (decodedText.indexOf(" CQ ") > 0)
    {
        CQcall = true;
        bg="#66ff66";  //green
    }
    if (myCall != "" and decodedText.indexOf(" " + myCall + " ") > 0)
        bg="#ff6666"; //red

    // if enabled add the DXCC entity and B4 status to the end of the preformated text line t1
    if (displayDXCCEntity && CQcall)
        _appendDXCCWorkedB4(/*mod*/decodedText,bg,logBook);


    QString s = "<table border=0 cellspacing=0 width=100%><tr><td bgcolor=\"" +
            bg + "\"><pre>" + decodedText + "</pre></td></tr></table>";

    QTextCursor cursor = textCursor();
    cursor.movePosition(QTextCursor::End);
    QTextBlockFormat bf = cursor.blockFormat();
    bf.setBackground(QBrush(QColor(bg)));
    cursor.insertHtml(s);
    this->setTextCursor(cursor);
}
