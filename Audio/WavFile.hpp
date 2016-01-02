#ifndef WSV_FILE_HPP__
#define WSV_FILE_HPP__

#include <array>

#include <QFile>
#include <QAudioFormat>
#include <QMap>
#include <QByteArray>

class QObject;
class QString;

class WavFile final
  : public QIODevice
{
  Q_OBJECT
public:
  using FileHandleFlags = QFile::FileHandleFlags;
  using Permissions = QFile::Permissions;
  using FileError = QFile::FileError;
  using MemoryMapFlags = QFile::MemoryMapFlags;
  using InfoDictionary = QMap<std::array<char, 4>, QByteArray>;

  explicit WavFile (QAudioFormat const&, QObject * parent = nullptr);
  explicit WavFile (QAudioFormat const&, QString const& name, QObject * parent = nullptr);
  explicit WavFile (QAudioFormat const&, QString const& name, InfoDictionary const&, QObject * parent = nullptr);
  ~WavFile ();
  QAudioFormat const& format () const {return format_;}
  qint64 header_length () const {return header_length_;}
  InfoDictionary const& info () const {return info_dictionary_;}

  // Emulate QFile interface
  bool open (OpenMode) override;
  bool open (FILE *, OpenMode, FileHandleFlags = QFile::DontCloseHandle);
  bool open (int fd, OpenMode, FileHandleFlags = QFile::DontCloseHandle);
  bool copy (QString const& new_name);

  // forward to QFile
  bool exists () const {return file_.exists ();}
  bool link (QString const& link_name) {return file_.link (link_name);}
  bool remove () {return file_.remove ();}
  bool rename (QString const& new_name) {return file_.rename (new_name);}
  void setFileName (QString const& name) {file_.setFileName (name);}
  QString symLinkTarget () const {return file_.symLinkTarget ();}
  QString fileName () const {return file_.fileName ();}
  Permissions permissions () const {return file_.permissions ();}
  bool resize (qint64 new_size) {return file_.resize (new_size + header_length_);}
  bool setPermissions (Permissions permissions) {return file_.setPermissions (permissions);}
  FileError error () const {return file_.error ();}
  bool flush () {return file_.flush ();}
  int handle () const {return file_.handle ();}
  uchar * map (qint64 offset, qint64 size, MemoryMapFlags flags = QFile::NoOptions)
  {
    return file_.map (offset, size, flags);
  }
  bool unmap (uchar * address) {return file_.unmap (address);}
  void unsetError () {file_.unsetError ();}

  // QIODevice overrides
  bool isSequential () const override;
  bool reset () override;
  bool seek (qint64) override;
  void close () override;

protected:
  qint64 readData (char * data, qint64 max_size) override;
  qint64 writeData (char const* data, qint64 max_size) override;

private:
  bool initialize (OpenMode);
  bool read_header ();
  bool write_header (QAudioFormat);
  bool update_header ();

  bool header_dirty_;
  QAudioFormat format_;
  QFile file_;
  qint64 header_length_;
  InfoDictionary info_dictionary_;
};

#endif
