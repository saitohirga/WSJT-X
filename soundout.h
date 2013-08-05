#ifndef SOUNDOUT_H__
#define SOUNDOUT_H__

#include <QObject>
#include <QString>
#include <QAudioOutput>

#include "Modulator.hpp"

class QAudioDeviceInfo;

// An instance of this sends audio data to a specified soundcard.

class SoundOutput : public QObject
{
  Q_OBJECT;

  Q_PROPERTY(bool running READ isRunning);

 private:
  Q_DISABLE_COPY (SoundOutput);

 public:
  SoundOutput ()
    : m_active(false)
    {
    }
  ~SoundOutput ();

  bool isRunning() const {return m_active;}

public Q_SLOTS:
  bool start(QAudioDeviceInfo const& device, QIODevice * source);
  void stop();

Q_SIGNALS:
  void error (QString message) const;
  void status (QString message) const;

private:
  bool audioError () const;

private Q_SLOTS:
  void handleStateChanged (QAudio::State) const;

 private:
  QScopedPointer<QAudioOutput> m_stream;

  bool m_active;
};

#endif
