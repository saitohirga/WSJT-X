#include "displaytext.h"
#include <QDebug>
#include <QMouseEvent>
#include <QDateTime>

#include "moc_displaytext.cpp"

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


void DisplayText::setFont(QFont const& font)
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
    QString tt="----------------------------------------";
    QString bg="#d3d3d3";
    _insertText(tt,bg);
}

void DisplayText::_insertText(const QString text, const QString bg)
{
    QString tt = text.mid(0,_maxDisplayedCharacters); //truncate to max display chars
    QString s = "<table border=0 cellspacing=0 width=100%><tr><td bgcolor=\"" +
                bg + "\"><pre>" + tt + "</pre></td></tr></table>";

    QTextCursor cursor = textCursor();
    cursor.movePosition(QTextCursor::End);
    QTextBlockFormat bf = cursor.blockFormat();
    bf.setBackground(QBrush(QColor(bg)));
    cursor.insertHtml(s);
    this->setTextCursor(cursor);
}


void DisplayText::_appendDXCCWorkedB4(/*mod*/DecodedText& t1, QString& bg, /*uses*/LogBook logBook)
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
    // TODO this magic 36 characters is also referenced in MainWindow::doubleClickOnCall()
    int s3 = t1.indexOf(" ",35);
    if (s3 < 35)
        s3 = 35; // we always want at least the characters to position 35
    s3 += 1; // convert the index into a character count
    t1 = t1.left(s3);  // reduce trailing white space
    charsAvail -= s3;
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

void DisplayText::displayDecodedText(DecodedText decodedText, QString myCall, bool displayDXCCEntity, LogBook logBook)
{
    QString bg="white";
    bool CQcall = false;
    if (decodedText.indexOf(" CQ ") > 0)
    {
        CQcall = true;
        bg="#66ff66";  //green
    }
    if (myCall != "" and (
                          decodedText.indexOf (" " + myCall + " ") >= 0
                          or decodedText.indexOf (" " + myCall + "/") >= 0
                          or decodedText.indexOf ("/" + myCall + " ") >= 0
                          ))
        bg="#ff6666"; //red

    // if enabled add the DXCC entity and B4 status to the end of the preformated text line t1
    if (displayDXCCEntity && CQcall)
        _appendDXCCWorkedB4(/*mod*/decodedText,bg,logBook);

    _insertText(decodedText.string(),bg);
}


void DisplayText::displayTransmittedText(QString text, QString modeTx, qint32 txFreq)
{
    QString bg="yellow";
    QString t1=" @ ";
    if(modeTx=="JT65") t1=" # ";
    QString t2;
    t2.sprintf("%4d",txFreq);
    QString t = QDateTime::currentDateTimeUtc().toString("hhmm") + \
        "  Tx      " + t2 + t1 + text;   // The position of the 'Tx' is searched for in DecodedText and in MainWindow.  Not sure if thats required anymore? VK3ACF

    _insertText(t,bg);
}
