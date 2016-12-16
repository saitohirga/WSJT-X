#include "DecodesModel.hpp"

#include <QStandardItem>
#include <QModelIndex>
#include <QTime>
#include <QString>
#include <QFont>
#include <QList>

namespace
{
  char const * const headings[] = {
    QT_TRANSLATE_NOOP ("DecodesModel", "Client"),
    QT_TRANSLATE_NOOP ("DecodesModel", "Time"),
    QT_TRANSLATE_NOOP ("DecodesModel", "Snr"),
    QT_TRANSLATE_NOOP ("DecodesModel", "DT"),
    QT_TRANSLATE_NOOP ("DecodesModel", "DF"),
    QT_TRANSLATE_NOOP ("DecodesModel", "Md"),
    QT_TRANSLATE_NOOP ("DecodesModel", "Message"),
  };

  QFont text_font {"Courier", 10};

  QList<QStandardItem *> make_row (QString const& client_id, QTime time, qint32 snr, float delta_time
                                   , quint32 delta_frequency, QString const& mode, QString const& message
                                   , bool is_fast)
  {
    auto time_item = new QStandardItem {time.toString (is_fast ? "hh:mm:ss" : "hh:mm")};
    time_item->setData (time);
    time_item->setTextAlignment (Qt::AlignRight);

    auto snr_item = new QStandardItem {QString::number (snr)};
    snr_item->setData (snr);
    snr_item->setTextAlignment (Qt::AlignRight);

    auto dt = new QStandardItem {QString::number (delta_time)};
    dt->setData (delta_time);
    dt->setTextAlignment (Qt::AlignRight);

    auto df = new QStandardItem {QString::number (delta_frequency)};
    df->setData (delta_frequency);
    df->setTextAlignment (Qt::AlignRight);

    auto md = new QStandardItem {mode};
    md->setTextAlignment (Qt::AlignHCenter);

    QList<QStandardItem *> row {
      new QStandardItem {client_id}, time_item, snr_item, dt, df, md, new QStandardItem {message}};
    Q_FOREACH (auto& item, row)
      {
        item->setEditable (false);
        item->setFont (text_font);
        item->setTextAlignment (item->textAlignment () | Qt::AlignVCenter);
      }
    return row;
  }
}

DecodesModel::DecodesModel (QObject * parent)
  : QStandardItemModel {0, 7, parent}
{
  int column {0};
  for (auto const& heading : headings)
    {
      setHeaderData (column++, Qt::Horizontal, tr (heading));
    }
}

void DecodesModel::add_decode (bool is_new, QString const& client_id, QTime time, qint32 snr, float delta_time
                               , quint32 delta_frequency, QString const& mode, QString const& message
                               , bool is_fast)
{
  if (!is_new)
    {
      int target_row {-1};
      for (auto row = 0; row < rowCount (); ++row)
        {
          if (data (index (row, 0)).toString () == client_id)
            {
              auto row_time = item (row, 1)->data ().toTime ();
              if (row_time == time
                  && item (row, 2)->data ().toInt () == snr
                  && item (row, 3)->data ().toFloat () == delta_time
                  && item (row, 4)->data ().toUInt () == delta_frequency
                  && data (index (row, 5)).toString () == mode
                  && data (index (row, 6)).toString () == message)
                {
                  return;
                }
              if (time <= row_time)
                {
                  target_row = row; // last row with same time
                }
            }
        }
      if (target_row >= 0)
        {
          insertRow (target_row + 1, make_row (client_id, time, snr, delta_time, delta_frequency, mode
                                               , message, is_fast));
          return;
        }
    }

  appendRow (make_row (client_id, time, snr, delta_time, delta_frequency, mode, message, is_fast));
}

void DecodesModel::clear_decodes (QString const& client_id)
{
  for (auto row = rowCount () - 1; row >= 0; --row)
    {
      if (data (index (row, 0)).toString () == client_id)
        {
          removeRow (row);
        }
    }
}

void DecodesModel::do_reply (QModelIndex const& source)
{
  auto row = source.row ();
  Q_EMIT reply (data (index (row, 0)).toString ()
                , item (row, 1)->data ().toTime ()
                , item (row, 2)->data ().toInt ()
                , item (row, 3)->data ().toFloat ()
                , item (row, 4)->data ().toInt ()
                , data (index (row, 5)).toString ()
                , data (index (row, 6)).toString ());
}

#include "moc_DecodesModel.cpp"
