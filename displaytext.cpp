#include "displaytext.h"
#include <QDebug>
#include <QMouseEvent>
#include <QDateTime>

#include "qt_helpers.hpp"

#include "moc_displaytext.cpp"

DisplayText::DisplayText(QWidget *parent) :
    QTextEdit(parent)
{
    setReadOnly (true);
    viewport ()->setCursor (Qt::ArrowCursor);
}

void DisplayText::mouseDoubleClickEvent(QMouseEvent *e)
{
  bool ctrl = (e->modifiers() & Qt::ControlModifier);
  bool shift = (e->modifiers() & Qt::ShiftModifier);
  emit(selectCallsign(shift,ctrl));
  QTextEdit::mouseDoubleClickEvent(e);
}

void DisplayText::insertLineSpacer()
{
    QString tt="----------------------------------------";
    QString bg="#d3d3d3";
    _insertText(tt,bg);
}

void DisplayText::_insertText(const QString text, const QString bg)
{
    QString s = "<table border=0 cellspacing=0 width=100%><tr><td bgcolor=\"" +
      bg + "\"><pre>" + text.trimmed () + "</pre></td></tr></table>";
    moveCursor (QTextCursor::End);
    append (s);
    moveCursor (QTextCursor::End);
}


void DisplayText::_appendDXCCWorkedB4(DecodedText& t1, QString& bg,
                                      LogBook logBook, QColor color_CQ,
                                      QColor color_DXCC,
                                      QColor color_NewCall)
{
    // extract the CQer's call   TODO: does this work with all call formats?  What about 'CQ DX'?
    int s1 = 4 + t1.indexOf(" CQ ");
    int s2 = t1.indexOf(" ",s1);
    QString call = t1.mid(s1,s2-s1);

    QString countryName;
    bool callWorkedBefore;
    bool countryWorkedBefore;
    logBook.match(/*in*/call,/*out*/countryName,callWorkedBefore,countryWorkedBefore);

    int charsAvail = 48;

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
            bg=color_DXCC.name();
        }
        else
            if (!callWorkedBefore) // but have worked the country
            {
                t1 += "~";
                bg=color_NewCall.name();
            }
            else
            {
                t1 += " ";  // have worked this call before
                bg=color_CQ.name();
            }
        charsAvail -= 1;

        // do some obvious abbreviations
        countryName.replace ("Islands", "Is.");
        countryName.replace ("Island", "Is.");
        countryName.replace ("North ", "N. ");
        countryName.replace ("Northern ", "N. ");
        countryName.replace ("South ", "S. ");
        countryName.replace ("East ", "E. ");
        countryName.replace ("Eastern ", "E. ");
        countryName.replace ("West ", "W. ");
        countryName.replace ("Western ", "W. ");
        countryName.replace ("Central ", "C. ");
        countryName.replace (" and ", " & ");
        countryName.replace ("Republic", "Rep.");
        countryName.replace ("United States", "U.S.A.");
        countryName.replace ("Fed. Rep. of ", "");
        countryName.replace ("French ", "Fr.");
        countryName.replace ("Asiatic", "AS");
        countryName.replace ("European", "EU");
        countryName.replace ("African", "AF");
        t1 += countryName;
    }
}

void DisplayText::displayDecodedText(DecodedText decodedText, QString myCall,
                                     bool displayDXCCEntity, LogBook logBook,
                                     QColor color_CQ, QColor color_MyCall,
                                     QColor color_DXCC, QColor color_NewCall)
{
    QString bg="white";
    bool CQcall = false;
    if (decodedText.indexOf(" CQ ") > 0)
    {
        CQcall = true;
        bg=color_CQ.name();
    }
    if (myCall != "" and (
                          decodedText.indexOf (" " + myCall + " ") >= 0
                          or decodedText.indexOf (" " + myCall + "/") >= 0
                          or decodedText.indexOf ("/" + myCall + " ") >= 0
                          ))
      bg=color_MyCall.name();

    // if enabled add the DXCC entity and B4 status to the end of the preformated text line t1
    if (displayDXCCEntity && CQcall)
        _appendDXCCWorkedB4(/*mod*/decodedText,bg,logBook,color_CQ,
                            color_DXCC,color_NewCall);

    _insertText(decodedText.string(),bg);
}


void DisplayText::displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
                                         QColor color_TxMsg)
{
    QString bg=color_TxMsg.name();
    QString t1=" @ ";
    if(modeTx=="JT65") t1=" # ";
    QString t2;
    t2.sprintf("%4d",txFreq);
    QString t = QDateTime::currentDateTimeUtc().toString("hhmm") + \
        "  Tx      " + t2 + t1 + text;   // The position of the 'Tx' is searched for in DecodedText and in MainWindow.  Not sure if thats required anymore? VK3ACF

    _insertText(t,bg);
}
