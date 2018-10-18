#include "displaytext.h"
#include <QMouseEvent>
#include <QDateTime>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextBlock>
#include <QMenu>
#include <QAction>

#include "Configuration.hpp"
#include "LotWUsers.hpp"
#include "DecodeHighlightingModel.hpp"

#include "qt_helpers.hpp"
#include "moc_displaytext.cpp"

DisplayText::DisplayText(QWidget *parent)
  : QTextEdit(parent)
  , m_config {nullptr}
  , erase_action_ {new QAction {tr ("&Erase"), this}}
{
  setReadOnly (true);
  setUndoRedoEnabled (false);
  viewport ()->setCursor (Qt::ArrowCursor);
  setWordWrapMode (QTextOption::NoWrap);

  // max lines to limit heap usage
  document ()->setMaximumBlockCount (5000);

  // context menu erase action
  setContextMenuPolicy (Qt::CustomContextMenu);
  connect (this, &DisplayText::customContextMenuRequested, [this] (QPoint const& position) {
      auto * menu = createStandardContextMenu (position);
      menu->addAction (erase_action_);
      menu->exec (mapToGlobal (position));
      delete menu;
    });
  connect (erase_action_, &QAction::triggered, this, &DisplayText::erase);
}

void DisplayText::erase ()
{
  clear ();
  Q_EMIT erased ();
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
  Q_EMIT selectCallsign(e->modifiers ());
  QTextEdit::mouseDoubleClickEvent(e);
}

void DisplayText::insertLineSpacer(QString const& line)
{
  appendText (line, "#d3d3d3");
}

namespace
{
  void set_colours (Configuration const * config, QColor * bg, QColor * fg, DecodeHighlightingModel::Highlight type)
  {
    if (config)
      {
        for (auto const& item : config->decode_highlighting ().items ())
          {
            if (type == item.type_ && item.enabled_)
              {
                if (item.background_.style () != Qt::NoBrush)
                  {
                    *bg = item.background_.color ();
                  }
                if (item.foreground_.style () != Qt::NoBrush)
                  {
                    *fg = item.foreground_.color ();
                  }
                break;
              }
          }
      }
  }
}

void DisplayText::appendText(QString const& text, QColor bg, QColor fg
                             , QString const& call1, QString const& call2)
{
  auto cursor = textCursor ();
  cursor.movePosition (QTextCursor::End);
  auto block_format = cursor.blockFormat ();
  if (bg.isValid ())
    {
      block_format.setBackground (bg);
    }
  else
    {
      block_format.clearBackground ();
    }
  if (fg.isValid ())
    {
      block_format.setForeground (fg);
    }
  else
    {
      block_format.clearForeground ();
    }
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
      auto char_format = cursor.charFormat ();
      char_format.clearBackground ();
      char_format.clearForeground ();
      cursor.setCharFormat (char_format);
    }

  QTextCharFormat format = cursor.charFormat();
  int text_index {0};
  if (call1.size ())
    {
      auto call_index = text.indexOf (call1);
      if (call_index != -1) // sanity check
        {
          auto pos = highlighted_calls_.find (call1);
          if (pos != highlighted_calls_.end ())
            {
              cursor.insertText(text.left (call_index), format);
              if (pos.value ().first.isValid ())
                {
                  format.setBackground (pos.value ().first);
                }
              if (pos.value ().second.isValid ())
                {
                  format.setForeground (pos.value ().second);
                }
              cursor.insertText(text.mid (call_index, call1.size ()), format);
              text_index = call_index + call1.size ();
            }
        }
    }
  if (call2.size ())
    {
      auto call_index = text.indexOf (call2, text_index);
      if (call_index != -1) // sanity check
        {
          auto pos = highlighted_calls_.find (call2);
          if (pos != highlighted_calls_.end ())
            {
              format.setBackground (bg);
              format.setForeground (fg);
              cursor.insertText(text.mid (text_index, call_index - text_index), format);
              if (pos.value ().second.isValid ())
                {
                  format.setBackground (pos.value ().first);
                }
              if (pos.value ().second.isValid ())
                {
                  format.setForeground (pos.value ().second);
                }
              cursor.insertText(text.mid (call_index, call2.size ()), format);
              text_index = call_index + call2.size ();
            }
        }
    }
  if (call2.size () && m_config && m_config->lotw_users ().user (call2))
    {
      QColor bg;
      QColor fg;
      set_colours (m_config, &bg, &fg, DecodeHighlightingModel::Highlight::LotW);
      if (bg.isValid ()) format.setBackground (bg);
      if (fg.isValid ()) format.setForeground (fg);
    }
  cursor.insertText(text.mid (text_index), format);

  // position so viewport scrolled to left
  cursor.movePosition (QTextCursor::StartOfLine);
  setTextCursor (cursor);
  ensureCursorVisible ();
  document ()->setMaximumBlockCount (document ()->maximumBlockCount ());
}

QString DisplayText::appendWorkedB4(QString message, QString const& callsign, QString grid,
                                    QColor * bg, QColor * fg, LogBook const& logBook, QString currentBand)
{
  // allow for seconds
  int padding {message.indexOf (" ") > 4 ? 2 : 0};
  QString call = callsign;
  QString countryName;
  bool callWorkedBefore;
  bool callB4onBand;
  bool countryWorkedBefore;
  bool countryB4onBand;
  bool gridB4;
  bool gridB4onBand;

  if(call.length()==2) {
    int i0=message.indexOf("CQ "+call);
    call=message.mid(i0+6,-1);
    i0=call.indexOf(" ");
    call=call.mid(0,i0);
  }
  if(call.length()<3) return message;
  if(!call.contains(QRegExp("[0-9]|[A-Z]"))) return message;

  logBook.match(/*in*/call,grid,/*out*/countryName,callWorkedBefore,countryWorkedBefore,gridB4);
  logBook.match(/*in*/call,grid,/*out*/countryName,callB4onBand,countryB4onBand,gridB4onBand,
                /*in*/ currentBand);
  if(grid=="") {
    gridB4=true;
    gridB4onBand=true;
  }

  message = message.trimmed ();
  QString appendage{""};

  if (!countryWorkedBefore) {
    // therefore not worked call either
    //    appendage += "!";
    set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::DXCC);
  } else {
    if(!countryB4onBand) {
      set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::DXCCBand);
    } else {
      if(!gridB4) {
        set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::Grid);
      } else {
        if(!gridB4onBand) {
          set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::GridBand);
        } else {
          if (!callWorkedBefore) {
            // but have worked the country
//            appendage += "~";
            set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::Call);
          } else {
            if(!callB4onBand) {
//              appendage += "~";
              set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::CallBand);
            } else {
//              appendage += " ";  // have worked this call before
              set_colours (m_config, bg, fg, DecodeHighlightingModel::Highlight::CQ);
            }
          }
        }
      }
    }
  }

  int i1=countryName.indexOf(";");
  if(m_bPrincipalPrefix) {
    int i2=countryName.lastIndexOf(";");
    if(i1>0) countryName=countryName.mid(i1+2,i2-i1-2);
  } else {
    if(i1>0) countryName=countryName.mid(0,i1);
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
  }

  appendage += countryName;

  // use a nbsp to save the start of appended text so we can find
  // it again later, align appended data at a fixed column if
  // there is space otherwise let it float to the right
  int space_count {40 + padding - message.size ()};
  if (space_count > 0) {
    message += QString {space_count, QChar {' '}};
  }
  message += QChar::Nbsp + appendage;
  return message;
}

void DisplayText::displayDecodedText(DecodedText const& decodedText, QString const& myCall,
                                     bool displayDXCCEntity, LogBook const& logBook,
                                     QString currentBand, bool ppfx, bool bCQonly)
{
  m_bPrincipalPrefix=ppfx;
  QColor bg;
  QColor fg;
  bool CQcall = false;
  if (decodedText.string ().contains (" CQ ")
      || decodedText.string ().contains (" CQDX ")
      || decodedText.string ().contains (" QRZ "))
    {
      CQcall = true;
      set_colours (m_config, &bg, &fg, DecodeHighlightingModel::Highlight::CQ);
    }
  if(bCQonly and !CQcall) return;
  if (myCall != "" and (decodedText.indexOf (" " + myCall + " ") >= 0
        or decodedText.indexOf (" " + myCall + "/") >= 0
        or decodedText.indexOf ("<" + myCall + "/") >= 0
        or decodedText.indexOf ("/" + myCall + " ") >= 0
        or decodedText.indexOf ("/" + myCall + ">") >= 0
        or decodedText.indexOf ("<" + myCall + " ") >= 0
        or decodedText.indexOf ("<" + myCall + ">") >= 0
        or decodedText.indexOf (" " + myCall + ">") >= 0)) {
    set_colours (m_config, &bg, &fg, DecodeHighlightingModel::Highlight::MyCall);
  }
  auto message = decodedText.string();
  QString dxCall;
  QString dxGrid;
  decodedText.deCallAndGrid (/*out*/ dxCall, dxGrid);
  QRegularExpression grid_regexp {"\\A(?![Rr]{2}73)[A-Ra-r]{2}[0-9]{2}([A-Xa-x]{2}){0,1}\\z"};
  if(!dxGrid.contains(grid_regexp)) dxGrid="";
  message = message.left (message.indexOf (QChar::Nbsp)); // strip appended info
  if (displayDXCCEntity && CQcall)
    // if enabled add the DXCC entity and B4 status to the end of the
    // preformated text line t1
    message = appendWorkedB4 (message, decodedText.CQersCall(), dxGrid, &bg, &fg, logBook, currentBand);
  appendText (message.trimmed (), bg, fg, decodedText.call (), dxCall);
}


void DisplayText::displayTransmittedText(QString text, QString modeTx, qint32 txFreq,bool bFastMode)
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
    } else if(modeTx.mid(0,6)=="FT8fox") {
      t = QDateTime::currentDateTimeUtc().toString("hhmmss") + \
        " Tx" + modeTx.mid(7) + " " + text;
    } else {
      t = QDateTime::currentDateTimeUtc().toString("hhmm") + \
        "  Tx      " + t2 + t1 + text;
    }
    QColor bg;
    QColor fg;
    set_colours (m_config, &bg, &fg, DecodeHighlightingModel::Highlight::Tx);
    appendText (t, bg, fg);
}

void DisplayText::displayQSY(QString text)
{
  QString t = QDateTime::currentDateTimeUtc().toString("hhmmss") + "            " + text;
  appendText (t, "hotpink");
}

void DisplayText::displayFoxToBeCalled(QString t, QColor bg, QColor fg)
{
  appendText (t, bg, fg);
}

namespace
{
  void update_selection (QTextCursor& cursor, QColor const& bg, QColor const& fg)
  {
    if (!cursor.isNull ())
      {
        QTextCharFormat format {cursor.charFormat ()};
        if (bg.isValid ())
          {
            format.setBackground (bg);
          }
        else
          {
            format.clearBackground ();
          }
        if (fg.isValid ())
          {
            format.setForeground (fg);
          }
        else
          {
            format.clearForeground ();
          }
        cursor.mergeCharFormat (format);
      }
  }

  void reset_selection (QTextCursor& cursor)
  {
    if (!cursor.isNull ())
      {
        // restore previous text format, we rely on the text
        // char format at he start of the selection being the
        // old one which should be the case
        auto c2 = cursor;
        c2.setPosition (c2.selectionStart ());
        cursor.setCharFormat (c2.charFormat ());
      }
  }
}

void DisplayText::highlight_callsign (QString const& callsign, QColor const& bg,
                                      QColor const& fg, bool last_only)
{
  QTextCharFormat old_format {currentCharFormat ()};
  QTextCursor cursor {document ()};
  if (last_only)
    {
      cursor.movePosition (QTextCursor::End);
      cursor = document ()->find (callsign, cursor
                                  , QTextDocument::FindBackward | QTextDocument::FindWholeWords);
      if (bg.isValid () || fg.isValid ())
        {
          update_selection (cursor, bg, fg);
        }
      else
        {
          reset_selection (cursor);
        }
    }
  else
    {
      auto pos = highlighted_calls_.find (callsign);
      if (bg.isValid () || fg.isValid ())
        {
          auto colours = qMakePair (bg, fg);
          if (pos == highlighted_calls_.end ())
            {
              pos = highlighted_calls_.insert (callsign.toUpper (), colours);
            }
          else
            {
              pos.value () = colours; // update colours
            }
          while (!cursor.isNull ())
            {
              cursor = document ()->find (callsign, cursor, QTextDocument::FindWholeWords);
              update_selection (cursor, bg, fg);
            }
        }
      else if (pos != highlighted_calls_.end ())
        {
          highlighted_calls_.erase (pos);
          QTextCursor cursor {document ()};
          while (!cursor.isNull ())
            {
              cursor = document ()->find (callsign, cursor, QTextDocument::FindWholeWords);
              reset_selection (cursor);
            }
        }
    }
  setCurrentCharFormat (old_format);
}
