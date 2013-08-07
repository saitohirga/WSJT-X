#ifndef SOUNDOUT_H__
#define SOUNDOUT_H__

#include <QObject>
#include <QString>
#include <QAudioOutput>
#include <QAudioDeviceInfo>

class QAudioDeviceInfo;

class QAudioDeviceInfo;

// An instance of this sends audio data to a specified soundcard.

class SoundOutput : public QObject
{
  Q_OBJECT;

  Q_PROPERTY(bool running READ isRunning);

 private:
  Q_DISABLE_COPY (SoundOutput);

 public:
  SoundOutput (QIODevice * source);
  ~SoundOutput ();

  bool isRunning() const {return m_active;}

 public Q_SLOTS:
  void startStream (QAudioDeviceInfo const& device);
  void suspend ();
  void resume ();
  void stopStream ();

 Q_SIGNALS:
  void error (QString message) const;
  void status (QString message) const;

private:
  bool audioError () const;

 private Q_SLOTS:
  void handleStateChanged (QAudio::State);

 private:
  QScopedPointer<QAudioOutput> m_stream;

  QIODevice * m_source;
  bool volatile m_active;
  QAudioDeviceInfo m_currentDevice;
};

#endif
