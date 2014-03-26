#include "Bands.hpp"

#include <algorithm>

#include <QString>
#include <QVariant>

namespace
{
  // Local structure to hold a single ADIF band definition.
  struct ADIF_band
  {
    char const * const name_;
    Radio::Frequency lower_bound_;
    Radio::Frequency upper_bound_;
  };

  // Table of ADIF band definitions as defined in the ADIF
  // specification.
  ADIF_band constexpr ADIF_bands[] = {
    {"2190m", 	136000u, 	137000u},
    {"630m", 	472000u, 	479000u},
    {"560m", 	501000u, 	504000u},
    {"160m", 	1800000u, 	2000000u},
    {"80m", 	3500000u, 	4000000u},
    {"60m", 	5102000u, 	5406500u},
    {"40m", 	7000000u, 	7300000u},
    {"30m", 	10000000u, 	10150000u},
    {"20m", 	14000000u, 	14350000u},
    {"17m", 	18068000u, 	18168000u},
    {"15m", 	21000000u, 	21450000u},
    {"12m", 	24890000u, 	24990000u},
    {"10m", 	28000000u, 	29700000u},
    {"6m", 	50000000u, 	54000000u},
    {"4m", 	70000000u, 	71000000u},
    {"2m", 	144000000u, 	148000000u},
    {"1.25m", 	222000000u, 	225000000u},
    {"70cm", 	420000000u, 	450000000u},
    {"33cm", 	902000000u, 	928000000u},
    {"23cm", 	1240000000u, 	1300000000u},
    {"13cm", 	2300000000u, 	2450000000u},
    {"9cm", 	3300000000u, 	3500000000u},
    {"6cm", 	5650000000u, 	5925000000u},
    {"3cm", 	10000000000u,	10500000000u},
    {"1.25cm", 	24000000000u,	24250000000u},
    {"6mm", 	47000000000u,	47200000000u},
    {"4mm", 	75500000000u,	81000000000u},
    {"2.5mm", 	119980000000u,	120020000000u},
    {"2mm", 	142000000000u,	149000000000u},
    {"1mm", 	241000000000u,	250000000000u},
  };

  auto constexpr out_of_band = "OOB";

  int constexpr table_rows ()
  {
    return sizeof (ADIF_bands) / sizeof (ADIF_bands[0]);
  }
}

Bands::Bands (QObject * parent)
  : QAbstractTableModel {parent}
{
}

QModelIndex Bands::find (QVariant const& v) const
{
  auto f = v.value<Radio::Frequency> ();
  auto end_iter = ADIF_bands + table_rows ();
  auto row_iter = std::find_if (ADIF_bands, end_iter, [f] (ADIF_band const& band) {
      return band.lower_bound_ <= f && f <= band.upper_bound_;
    });
  if (row_iter != end_iter)
    {
      return index (row_iter - ADIF_bands, 0); // return the band row index
    }

  return QModelIndex {};
}

int Bands::rowCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : table_rows ();
}

int Bands::columnCount (QModelIndex const& parent) const
{
  return parent.isValid () ? 0 : 3;
}

Qt::ItemFlags Bands::flags (QModelIndex const& index) const
{
  return QAbstractTableModel::flags (index) | Qt::ItemIsDropEnabled;
}

QVariant Bands::data (QModelIndex const& index, int role) const
{
  QVariant item;

  if (!index.isValid ())
    {
      // Hijack root for OOB string.
      if (Qt::DisplayRole == role)
        {
          item = out_of_band;
        }
    }
  else
    {
      auto row = index.row ();
      auto column = index.column ();

      if (row < table_rows ())
        {
          switch (role)
            {
            case Qt::ToolTipRole:
            case Qt::AccessibleDescriptionRole:
              switch (column)
                {
                case 0: item = tr ("Band name"); break;
                case 1: item = tr ("Lower frequency limit"); break;
                case 2: item = tr ("Upper frequency limit"); break;
                }
              break;

            case SortRole:
            case Qt::DisplayRole:
            case Qt::EditRole:
              switch (column)
                {
                case 0:
                  if (SortRole == role)
                    {
                      // band name sorts by lower bound
                      item = ADIF_bands[row].lower_bound_;
                    }
                  else
                    {
                      item = ADIF_bands[row].name_;
                    }
                  break;

                case 1: item = ADIF_bands[row].lower_bound_; break;
                case 2: item = ADIF_bands[row].upper_bound_; break;
                }
              break;

            case Qt::AccessibleTextRole:
              switch (column)
                {
                case 0: item = ADIF_bands[row].name_; break;
                case 1: item = ADIF_bands[row].lower_bound_; break;
                case 2: item = ADIF_bands[row].upper_bound_; break;
                }
              break;

            case Qt::TextAlignmentRole:
              switch (column)
                {
                case 0:
                  item = Qt::AlignHCenter + Qt::AlignVCenter;
                  break;

                case 1:
                case 2:
                  item = Qt::AlignRight + Qt::AlignVCenter;
                  break;
                }
              break;
            }
        }
    }
  return item;
}

QVariant Bands::headerData (int section, Qt::Orientation orientation, int role) const
{
  QVariant result;

  if (Qt::DisplayRole == role && Qt::Horizontal == orientation)
    {
      switch (section)
        {
        case 0: result = tr ("Band"); break;
        case 1: result = tr ("Lower Limit"); break;
        case 2: result = tr ("Upper Limit"); break;
        }
    }
  else
    {
      result = QAbstractTableModel::headerData (section, orientation, role);
    }

  return result;
}
