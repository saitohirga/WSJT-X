#include "WavFile.hpp"

#include <cstring>
#include <numeric>
#include <algorithm>

#include <qendian.h>
#include <QAudioFormat>
#include <QDebug>

#include "moc_WavFile.cpp"

namespace
{
  struct Desc
  {
    Desc () = default;
    explicit Desc (char const * id, quint32 size = 0)
      : size_ {size}
    {
      set (id);
    }

    void set (char const * id = nullptr)
    {
      if (id)
        {
          auto len = std::min (size_t (4), strlen (id));
          memcpy (id_.data (), id, len);
          memset (id_.data () + len, ' ', 4u - len);
        }
      else
        {
          memcpy (id_.data (), "JUNK", 4);
        }
    }

    void set (char const * id, quint32 size)
    {
      set (id);
      size_ = size;
    }

    char * operator & () {return reinterpret_cast<char *> (this);}
    char const * operator & () const {return &*this;}

    std::array<char, 4> id_;
    quint32 size_;
  };

  struct FormatChunk
  {
    quint16 audio_format;
    quint16 num_channels;
    quint32 sample_rate;
    quint32 byte_rate;
    quint16 block_align;
    quint16 bits_per_sample;
  };
}

WavFile::WavFile (QAudioFormat const& format, QObject * parent)
  : QIODevice {parent}
  , header_dirty_ {true}
  , format_ {format}
  , header_length_ {-1}
{
}

WavFile::WavFile (QAudioFormat const& format, QString const& name, QObject * parent)
  : QIODevice {parent}
  , header_dirty_ {true}
  , format_ {format}
  , file_ {name}
  , header_length_ {-1}
{
}

WavFile::WavFile (QAudioFormat const& format, QString const& name
                  , InfoDictionary const& dictionay, QObject * parent)
  : QIODevice {parent}
  , header_dirty_ {true}
  , format_ {format}
  , file_ {name}
  , header_length_ {-1}
  , info_dictionary_ {dictionay}
{
}

WavFile::~WavFile ()
{
  QIODevice::close ();
  if (header_dirty_) update_header ();
  file_.close ();
}

bool WavFile::open (OpenMode mode)
{
  bool result {false};
  if (!(mode & ReadOnly)) return result;
  if (!(mode & WriteOnly))
    {
      result = file_.open (mode & ~Text) && read_header ();
    }
  else
    {
      if ((result = file_.open (mode & ~Text)))
        {
          if (!(result = read_header () || write_header (format_)))
            {
              file_.close ();
              return false;
            }
        }
    }
  return result ? initialize (mode) : false;
}

bool WavFile::open(FILE * fh, OpenMode mode, FileHandleFlags flags)
{
  bool result {false};
  if (!(mode & ReadOnly)) return result;
  if (!mode & WriteOnly)
    {
      result = file_.open (fh, mode & ~Text, flags) && read_header ();
    }
  else
    {
      if ((result = file_.open (fh, mode & ~Text, flags)))
        {
          if (!(result = read_header () || write_header (format_)))
            {
              file_.close ();
              return false;
            }
        }
    }
  return result ? initialize (mode) : false;
}

bool WavFile::open (int fd, OpenMode mode, FileHandleFlags flags)
{
  bool result {false};
  if (!(mode & ReadOnly)) return result;
  if (!(mode & WriteOnly))
    {
      result = file_.open (fd, mode & ~Text, flags) && read_header ();
    }
  else
    {
      if ((result = file_.open (fd, mode & ~Text, flags)))
        {
          if (!(result = read_header () || write_header (format_)))
            {
              file_.close ();
              return false;
            }
        }
    }
  return result ? initialize (mode) : false;
}

bool WavFile::initialize (OpenMode mode)
{
  bool result {QIODevice::open (mode | Unbuffered)};
  if (result && (mode & Append))
    {
      result = file_.seek (file_.size ());
      if (result) result = seek (file_.size () - header_length_);
    }
  else
    {
      result = seek (0);
    }
  if (!result)
    {
      file_.close ();
      close ();
    }
  return result;
}

bool WavFile::read_header ()
{
  if (!file_.seek (0)) return false;
  Desc outer_desc;
  quint32 outer_offset = file_.pos ();
  quint32 outer_size {0};
  bool be {false};
  while (outer_offset < sizeof outer_desc + outer_desc.size_ - 1) // allow for uncounted pad
    {
      if (file_.read (&outer_desc, sizeof outer_desc) != sizeof outer_desc) return false;
      be = !memcmp (&outer_desc.id_, "RIFX", 4);
      outer_size = be ? qFromBigEndian<quint32> (outer_desc.size_) : qFromLittleEndian<quint32> (outer_desc.size_);
      if (!memcmp (&outer_desc.id_, "RIFF", 4) || be)
        {
          // RIFF or RIFX
          char riff_item[4];
          if (file_.read (riff_item, sizeof riff_item) != sizeof riff_item) return false;
          if (!memcmp (riff_item, "WAVE", 4))
            {
              // WAVE
              Desc wave_desc;
              quint32 wave_offset = file_.pos ();
              quint32 wave_size {0};
              while (wave_offset < outer_offset + sizeof outer_desc + outer_size - 1)
                {
                  if (file_.read (&wave_desc, sizeof wave_desc) != sizeof wave_desc) return false;
                  wave_size = be ? qFromBigEndian<quint32> (wave_desc.size_) : qFromLittleEndian<quint32> (wave_desc.size_);
                  if (!memcmp (&wave_desc.id_, "fmt ", 4))
                    {
                      FormatChunk fmt;
                      if (file_.read (reinterpret_cast<char *> (&fmt), sizeof fmt) != sizeof fmt) return false;
                      auto audio_format = be ? qFromBigEndian<quint16> (fmt.audio_format) : qFromLittleEndian<quint16> (fmt.audio_format);
                      if (audio_format != 0 && audio_format != 1) return false; // not PCM nor undefined
                      format_.setByteOrder (be ? QAudioFormat::BigEndian : QAudioFormat::LittleEndian);
                      format_.setChannelCount (be ? qFromBigEndian<quint16> (fmt.num_channels) : qFromLittleEndian<quint16> (fmt.num_channels));
                      format_.setCodec ("audio/pcm");
                      format_.setSampleRate (be ? qFromBigEndian<quint32> (fmt.sample_rate) : qFromLittleEndian<quint32> (fmt.sample_rate));
                      int bits_per_sample {be ? qFromBigEndian<quint16> (fmt.bits_per_sample) : qFromLittleEndian<quint16> (fmt.bits_per_sample)};
                      format_.setSampleSize (bits_per_sample);
                      format_.setSampleType (8 == bits_per_sample ? QAudioFormat::UnSignedInt : QAudioFormat::SignedInt);
                    }
                  else if (!memcmp (&wave_desc.id_, "data", 4))
                    {
                      header_length_ = file_.pos ();
                      return true; // done
                    }
                  else if (!memcmp (&wave_desc.id_, "LIST", 4))
                    {
                      char list_type[4];
                      if (file_.read (list_type, sizeof list_type) != sizeof list_type) return false;
                      if (!memcmp (list_type, "INFO", 4))
                        {
                          Desc info_desc;
                          quint32 info_offset = file_.pos ();
                          quint32 info_size {0};
                          while (info_offset < wave_offset + sizeof wave_desc + wave_size - 1)
                            {
                              if (file_.read (&info_desc, sizeof info_desc) != sizeof info_desc) return false;
                              info_size = be ? qFromBigEndian<quint32> (info_desc.size_) : qFromLittleEndian<quint32> (info_desc.size_);
                              info_dictionary_[info_desc.id_] = file_.read (info_size);
                              if (!file_.seek (info_offset + sizeof info_desc + (info_size + 1) / 2 * 2)) return false;;
                              info_offset = file_.pos ();
                            }
                        }
                    }
                  if (!file_.seek (wave_offset + sizeof wave_desc + (wave_size + 1) / 2 * 2)) return false;
                  wave_offset = file_.pos ();
                }
            }
        }
      if (!file_.seek (outer_offset + sizeof outer_desc + (outer_size + 1) / 2 * 2)) return false;
      outer_offset = file_.pos ();
    }
  return false;
}

bool WavFile::write_header (QAudioFormat format)
{
  if ("audio/pcm" != format.codec ()) return false;
  if (!file_.seek (0)) return false;
  header_length_ = 0;
  bool be {QAudioFormat::BigEndian == format_.byteOrder ()};
  Desc desc {be ? "RIFX" : "RIFF"};
  if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
  header_dirty_ = true;
  if (file_.write ("WAVE", 4) != 4) return false;
  FormatChunk fmt;
  if (be)
    {
      fmt.audio_format = qToBigEndian<quint16> (1); // PCM
      fmt.num_channels = qToBigEndian<quint16> (format.channelCount ());
      fmt.sample_rate = qToBigEndian<quint32> (format.sampleRate ());
      fmt.byte_rate = qToBigEndian<quint32> (format.bytesForDuration (1000));
      fmt.block_align = qToBigEndian<quint16> (format.bytesPerFrame ());
      fmt.bits_per_sample = qToBigEndian<quint16> (format.sampleSize ());
      desc.set ("fmt", qToBigEndian<quint32> (sizeof fmt));
    }
  else
    {
      fmt.audio_format = qToLittleEndian<quint16> (1); // PCM
      fmt.num_channels = qToLittleEndian<quint16> (format.channelCount ());
      fmt.sample_rate = qToLittleEndian<quint32> (format.sampleRate ());
      fmt.byte_rate = qToLittleEndian<quint32> (format.bytesForDuration (1000));
      fmt.block_align = qToLittleEndian<quint16> (format.bytesPerFrame ());
      fmt.bits_per_sample = qToLittleEndian<quint16> (format.sampleSize ());
      desc.set ("fmt", qToLittleEndian<quint32> (sizeof fmt));
    }
  if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
  if (file_.write (reinterpret_cast<char const *> (&fmt), sizeof fmt) != sizeof fmt) return false;
  if (info_dictionary_.size ())
    {
      auto position = file_.pos ();
      desc.set ("LIST");
      if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
      if (file_.write ("INFO", 4) != 4) return false;
      for (auto iter = info_dictionary_.constBegin ()
             ; iter != info_dictionary_.constEnd (); ++iter)
        {
          auto value = iter.value ();
          auto len = value.size () + 1;
          auto padded_len = (len + 1) / 2 * 2;
          if (padded_len > value.size ()) value.append ('\0');
          desc.set (iter.key ().data (), be ? qToBigEndian<quint32> (len) : qToLittleEndian<quint32> (len));
          if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
          if (file_.write (value.constData (), padded_len) != padded_len) return false;
        }
      auto end_position = file_.pos ();
      if (!file_.seek (position)) return false;
      if (file_.peek (&desc, sizeof desc) != sizeof desc) return false;
      Q_ASSERT (!memcmp (desc.id_.data (), "LIST", 4));
      auto size = end_position - position - sizeof desc;
      desc.size_ = be ? qToBigEndian<quint32> (size) : qToLittleEndian<quint32> (size);
      if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
      if (!file_.seek (end_position)) return false;
    }
  auto size = file_.size () - file_.pos () - sizeof desc;
  desc.set ("data", be ? qToBigEndian<quint32> (size) : qToLittleEndian<quint32> (size));
  if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
  header_length_ = file_.pos ();
  return true;
}

bool WavFile::update_header ()
{
  if (header_length_ < 0 || !(file_.openMode () & WriteOnly)) return false;
  auto position = file_.pos ();
  bool be {QAudioFormat::BigEndian == format_.byteOrder ()};
  Desc desc;
  if (!file_.seek (header_length_ - sizeof desc)) return false;
  if (file_.peek (&desc, sizeof desc) != sizeof desc) return false;
  Q_ASSERT (!memcmp (desc.id_.data (), "data", 4));
  auto size = file_.size () - header_length_;
  desc.size_ = be ? qToBigEndian<quint32> (size) : qToLittleEndian<quint32> (size);
  if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
  if (!file_.seek (0)) return false;
  if (file_.peek (&desc, sizeof desc) != sizeof desc) return false;
  Q_ASSERT (!memcmp (desc.id_.data (), "RIFF", 4) || !memcmp (desc.id_.data (), "RIFX", 4));
  size = file_.size () - sizeof desc;
  desc.size_ = be ? qToBigEndian<quint32> (size) : qToLittleEndian<quint32> (size);
  if (file_.write (&desc, sizeof desc) != sizeof desc) return false;
  return file_.seek (position);
}

bool WavFile::reset ()
{
  file_.seek (header_length_);
  return QIODevice::reset ();
}

bool WavFile::isSequential () const
{
  return file_.isSequential ();
}

void WavFile::close ()
{
  QIODevice::close ();
  file_.close ();
}

bool WavFile::seek (qint64 pos)
{
  if (pos < 0) return false;
  QIODevice::seek (pos);
  return file_.seek (pos + header_length_);
}

qint64 WavFile::readData (char * data, qint64 max_size)
{
  return file_.read (data, max_size);
}

qint64 WavFile::writeData (char const* data, qint64 max_size)
{
  auto bytes = file_.write (data, max_size);
  if (bytes > 0 && atEnd ()) header_dirty_ = true;
  return bytes;
}
