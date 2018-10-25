#include "WorkedBefore.hpp"

#include <boost/multi_index_container.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index/key_extractors.hpp>
#include <QByteArray>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include "countrydat.h"

#include "pimpl_impl.hpp"

// worked before set element
struct worked_entry
{
  explicit worked_entry (std::string const& call
                         , std::string const& grid
                         , std::string const& band
                         , std::string const& mode
                         , std::string const& country)
    : call {call}
    , grid {grid}
    , band {band}
    , mode {mode}
    , country {country}
  {
  }

  std::string call;
  std::string grid;
  std::string band;
  std::string mode;
  std::string country;
};

// tags
struct call_mode_band {};
struct call_band {};
struct grid_mode_band {};
struct grid_band {};
struct entity_mode_band {};
struct entity_band {};

// set with multiple ordered unique indexes that allow for efficient
// determination of various categories of worked before status
typedef boost::multi_index::multi_index_container<
  worked_entry,
  boost::multi_index::indexed_by<
    // call+mode+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<call_mode_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::call>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::mode>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >,
    // call+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<call_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::call>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >,
    // grid+mode+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<grid_mode_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::grid>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::mode>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >,
    // grid+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<grid_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::grid>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >,
    // country+mode+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<entity_mode_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::country>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::mode>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >,
      // country+band
    boost::multi_index::ordered_unique<
      boost::multi_index::tag<entity_band>,
      boost::multi_index::composite_key<
        worked_entry,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::country>,
        boost::multi_index::member<worked_entry, std::string, &worked_entry::band>
        >
      >
    >
  > worked_type;

namespace
{
  auto const logFileName = "wsjtx_log.adi";

  std::string extractField (QString const& record, QString const& fieldName)
  {
    int fieldNameIndex = record.indexOf ('<' + fieldName + ':', 0, Qt::CaseInsensitive);
    if (fieldNameIndex >=0)
      {
        int closingBracketIndex = record.indexOf('>',fieldNameIndex);
        int fieldLengthIndex = record.indexOf(':',fieldNameIndex);  // find the size delimiter
        int dataTypeIndex = -1;
        if (fieldLengthIndex >= 0)
          {
            dataTypeIndex = record.indexOf(':',fieldLengthIndex+1);  // check for a second : indicating there is a data type
            if (dataTypeIndex > closingBracketIndex)
              dataTypeIndex = -1; // second : was found but it was beyond the closing >
          }

        if ((closingBracketIndex > fieldNameIndex) && (fieldLengthIndex > fieldNameIndex) && (fieldLengthIndex< closingBracketIndex))
          {
            int fieldLengthCharCount = closingBracketIndex - fieldLengthIndex -1;
            if (dataTypeIndex >= 0)
              fieldLengthCharCount -= 2; // data type indicator is always a colon followed by a single character
            QString fieldLengthString = record.mid(fieldLengthIndex+1,fieldLengthCharCount);
            int fieldLength = fieldLengthString.toInt();
            if (fieldLength > 0)
              {
                QString field = record.mid(closingBracketIndex+1,fieldLength);
                return field.toStdString ();
              }
          }
      }
    return "";
  }
}

class WorkedBefore::impl final
{
public:
  impl ()
    : path_ {QDir {QStandardPaths::writableLocation (QStandardPaths::DataLocation)}.absoluteFilePath (logFileName)}
  {
  }

  QString path_;
  CountryDat countries_;
  worked_type worked_;
};

WorkedBefore::WorkedBefore ()
{
  QFile inputFile {m_->path_};
  if (inputFile.open (QFile::ReadOnly))
    {
      QTextStream in(&inputFile);
      QString buffer;
      bool pre_read {false};
      int end_position {-1};

      // skip optional header record
      do
        {
          buffer += in.readLine () + '\n';
          if (buffer.startsWith (QChar {'<'})) // denotes no header
            {
              pre_read = true;
            }
          else
            {
              end_position = buffer.indexOf ("<EOH>", 0, Qt::CaseInsensitive);
            }
        }
      while (!in.atEnd () && !pre_read && end_position < 0);
      if (!pre_read)            // found header
        {
          buffer.remove (0, end_position + 5);
        }
      while (buffer.size () || !in.atEnd ())
        {
          do
            {
              end_position = buffer.indexOf ("<EOR>", 0, Qt::CaseInsensitive);
              if (!in.atEnd () && end_position < 0)
                {
                  buffer += in.readLine () + '\n';
                }
            }
          while (!in.atEnd () && end_position < 0);
          int record_length {end_position >= 0 ? end_position + 5 : -1};
          auto record = buffer.left (record_length).trimmed ();
          auto next_record = buffer.indexOf (QChar {'<'}, record_length);
          buffer.remove (0, next_record >=0 ? next_record : buffer.size ());
          record = record.mid (record.indexOf (QChar {'<'}));
          auto call = extractField (record, "CALL");
          if (call.size ())
            {
              m_->worked_.emplace (call
                                   , extractField (record, "GRIDSQUARE").substr (0, 4) // not interested in 6-digit grids
                                   , extractField (record, "BAND")
                                   , extractField (record, "MODE")
                                   , m_->countries_.find (QString::fromStdString (call)).toStdString ());
            }
        }
    }
}

WorkedBefore::~WorkedBefore ()
{
}

QString const& WorkedBefore::path () const
{
  return m_->path_;
}

CountryDat const& WorkedBefore::countries () const
{
  return m_->countries_;
}

bool WorkedBefore::add (QString const& call
                        , QString const& grid
                        , QString const& band
                        , QString const& mode
                        , QByteArray const& ADIF_record)
{
  if (call.size ())
    {
      QFile file {m_->path_};
      if (!file.open(QIODevice::Text | QIODevice::Append))
        {
          return false;
        }
      else
        {
          QTextStream out {&file};
          if (!file.size ())
            {
              out << "WSJT-X ADIF Export<eoh>" << endl;  // new file
            }
          out << ADIF_record << " <eor>" << endl;
        }
      m_->worked_.emplace (call.toStdString ()
                           , grid.toStdString ()
                           , band.toStdString ()
                           , mode.toStdString ()
                           , m_->countries_.find (call).toStdString ());
    }
  return true;
}

bool WorkedBefore::country_worked (QString const& country, QString const& mode, QString const& band) const
{
  if (mode.size ())
    {
      if (band.size ())
        {
          return
            country.size ()
            && m_->worked_.get<entity_mode_band> ().end ()
            != m_->worked_.get<entity_mode_band> ().find (std::make_tuple (country.toStdString ()
                                                                           , mode.toStdString ()
                                                                           , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return
            country.size ()
            && m_->worked_.get<entity_mode_band> ().end ()
            != m_->worked_.get<entity_mode_band> ().find (std::make_tuple (country.toStdString ()
                                                                           , mode.toStdString ()));
        }
    }
  else
    {
      if (band.size ())
        {
          return
            country.size ()
            && m_->worked_.get<entity_band> ().end ()
            != m_->worked_.get<entity_band> ().find (std::make_tuple (country.toStdString ()
                                                                      , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return
            country.size ()
            && m_->worked_.get<entity_band> ().end ()
            != m_->worked_.get<entity_band> ().find (std::make_tuple (country.toStdString ()));
        }
    }
}

bool WorkedBefore::grid_worked (QString const& grid, QString const& mode, QString const& band) const
{
  if (mode.size ())
    {
      if (band.size ())
        {
          return m_->worked_.get<grid_mode_band> ().end ()
            != m_->worked_.get<grid_mode_band> ().find (std::make_tuple (grid.toStdString ()
                                                                         , mode.toStdString ()
                                                                         , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return m_->worked_.get<grid_mode_band> ().end ()
            != m_->worked_.get<grid_mode_band> ().find (std::make_tuple (grid.toStdString ()
                                                                         , mode.toStdString ()));
        }
    }
  else
    {
      if (band.size ())
        {
          return m_->worked_.get<grid_band> ().end ()
            != m_->worked_.get<grid_band> ().find (std::make_tuple (grid.toStdString ()
                                                                    , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return m_->worked_.get<grid_band> ().end ()
            != m_->worked_.get<grid_band> ().find (std::make_tuple (grid.toStdString ()));
        }
    }
}

bool WorkedBefore::call_worked (QString const& call, QString const& mode, QString const& band) const
{
  if (mode.size ())
    {
      if (band.size ())
        {
          return m_->worked_.get<call_mode_band> ().end ()
            != m_->worked_.get<call_mode_band> ().find (std::make_tuple (call.toStdString ()
                                                                         , mode.toStdString ()
                                                                         , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return m_->worked_.get<call_mode_band> ().end ()
            != m_->worked_.get<call_mode_band> ().find (std::make_tuple (call.toStdString ()
                                                                         , mode.toStdString ()));
        }
    }
  else
    {
      if (band.size ())
        {
          return m_->worked_.get<call_band> ().end ()
            != m_->worked_.get<call_band> ().find (std::make_tuple (call.toStdString ()
                                                                    , band.toStdString ()));
        }
      else
        {
          // partial key lookup
          return m_->worked_.get<call_band> ().end ()
            != m_->worked_.get<call_band> ().find (std::make_tuple (call.toStdString ()));
        }
    }
}
