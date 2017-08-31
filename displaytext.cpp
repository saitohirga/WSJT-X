#include "displaytext.h"

#include <QMouseEvent>
#include <QDateTime>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextBlock>

#include "qt_helpers.hpp"

#include "moc_displaytext.cpp"

DisplayText::DisplayText(QWidget *parent) :
    QTextEdit(parent)
{
  setReadOnly (true);
  viewport ()->setCursor (Qt::ArrowCursor);
  setWordWrapMode (QTextOption::NoWrap);
  document ()->setMaximumBlockCount (5000); // max lines to limit heap usage
}

void DisplayText::setContentFont(QFont const& font)
{
  char_font_ = font;
  selectAll ();
  auto cursor = textCursor ();
  cursor.beginEditBlock ();
  auto char_format = cursor.charFormat ();
  char_format.setFont (char_font_);
  cursor.mergeCharFormat (char_format);
  cursor.clearSelection ();
  cursor.movePosition (QTextCursor::End);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::Up);
  cursor.movePosition (QTextCursor::StartOfLine);
  cursor.endEditBlock ();

  setTextCursor (cursor);
  ensureCursorVisible ();
}

void DisplayText::mouseDoubleClickEvent(QMouseEvent *e)
{
  bool ctrl = (e->modifiers() & Qt::ControlModifier);
  bool alt = (e->modifiers() & Qt::AltModifier);
  emit(selectCallsign(alt,ctrl));
  QTextEdit::mouseDoubleClickEvent(e);
}

void DisplayText::insertLineSpacer(QString const& line)
{
  appendText (line, "#d3d3d3");
}

void DisplayText::appendText(QString const& text, QColor bg)
{
  auto cursor = textCursor ();
  cursor.movePosition (QTextCursor::End);
  auto block_format = cursor.blockFormat ();
  block_format.setBackground (bg);
  if (0 == cursor.position ())
    {
      cursor.setBlockFormat (block_format);
      auto char_format = cursor.charFormat ();
      char_format.setFont (char_font_);
      cursor.setCharFormat (char_format);
    }
  else
    {
      cursor.insertBlock (block_format);
    }
  cursor.insertText (text);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::StartOfLine);
  setTextCursor (cursor);
  ensureCursorVisible ();
  document ()->setMaximumBlockCount (document ()->maximumBlockCount ());
}


QString DisplayText::appendDXCCWorkedB4(QString message, QString const& callsign, QColor * bg,
					LogBook const& logBook, QColor color_CQ,
					QColor color_DXCC,
					QColor color_NewCall)
{
    QString call = callsign;
    QString countryName;
    bool callWorkedBefore;
    bool countryWorkedBefore;

    if(call.length()==2) {
      int i0=message.indexOf("CQ "+call);
      call=message.mid(i0+6,-1);
      i0=call.indexOf(" ");
      call=call.mid(0,i0);
    }
    if(call.length()<3) return message;
    if(!call.contains(QRegExp("[0-9]|[A-Z]"))) return message;

    logBook.match(/*in*/call,/*out*/countryName,callWorkedBefore,countryWorkedBefore);
    int charsAvail = 48;

    // the decoder (seems) to always generate 41 chars. For a normal CQ call, the last five are spaces
    // TODO this magic 37 characters is also referenced in MainWindow::doubleClickOnCall()
    int nmin=37;
    int i=message.indexOf(" CQ ");
    int k=message.mid(i+4,3).toInt();
    if(k>0 and k<999) nmin += 4;
    int s3 = message.indexOf(" ",nmin);
    if (s3 < nmin) s3 = nmin; // always want at least the characters to position 35
    s3 += 1; // convert the index into a character count
    message = message.left(s3);  // reduce trailing white space
    charsAvail -= s3;
    if (charsAvail > 4)
    {
        if (!countryWorkedBefore) // therefore not worked call either
        {
            message += "!";
            *bg = color_DXCC;
        }
        else
            if (!callWorkedBefore) // but have worked the country
            {
                message += "~";
                *bg = color_NewCall;
            }
            else
            {
                message += " ";  // have worked this call before
                *bg = color_CQ;
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

        message += countryName;
    }
    return message;
}

void DisplayText::displayDecodedText(DecodedText const& decodedText, QString const& myCall,
                                     bool displayDXCCEntity, LogBook const& logBook,
                                     QColor color_CQ, QColor color_MyCall,
                                     QColor color_DXCC, QColor color_NewCall)
{
  QColor bg {Qt::white};
    bool CQcall = false;
    if (decodedText.string ().contains (" CQ ")
        || decodedText.string ().contains (" CQDX ")
        || decodedText.string ().contains (" QRZ "))
    {
        CQcall = true;
        bg = color_CQ;
    }
    if (myCall != "" and (
          decodedText.indexOf (" " + myCall + " ") >= 0
          or decodedText.indexOf (" " + myCall + "/") >= 0
          or decodedText.indexOf ("/" + myCall + " ") >= 0
          or decodedText.indexOf ("<" + myCall + " ") >= 0
          or decodedText.indexOf (" " + myCall + ">") >= 0)) {
      bg = color_MyCall;
    }
    // if enabled add the DXCC entity and B4 status to the end of the
    // preformated text line t1
    auto message = decodedText.string ();
    if (displayDXCCEntity && CQcall)
      message = appendDXCCWorkedB4 (message, decodedText.CQersCall (), &bg, logBook, color_CQ,
				    color_DXCC, color_NewCall);
    appendText (message, bg);
}


void DisplayText::displayTransmittedText(QString text, QString modeTx, qint32 txFreq,
                                         QColor color_TxMsg, bool bFastMode)
{
    QString t1=" @  ";
    if(modeTx=="FT8") t1=" ~  ";
    if(modeTx=="JT4") t1=" $  ";
    if(modeTx=="JT65") t1=" #  ";
    if(modeTx=="MSK144") t1=" &  ";
    QString t2;
    t2.sprintf("%4d",txFreq);
    QString t;
    if(bFastMode or modeTx=="FT8") {
      t = QDateTime::currentDateTimeUtc().toString("hhmmss") + \
        "  Tx      " + t2 + t1 + text;
    } else {
      t = QDateTime::currentDateTimeUtc().toString("hhmm") + \
        "  Tx      " + t2 + t1 + text;
    }
    appendText (t, color_TxMsg);
}

void DisplayText::displayQSY(QString text)
{
  QString t = QDateTime::currentDateTimeUtc().toString("hhmmss") + "            " + text;
  appendText (t, "hotpink");
}
