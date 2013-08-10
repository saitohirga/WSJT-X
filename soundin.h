#ifndef SOUNDIN_H__
#define SOUNDIN_H__

#include <QObject>
#include <QString>
#include <QScopedPointer>
#include <QAudioInput>

class QAudioDeviceInfo;
class QAudioInput;
class QIODevice;

// Gets audio data from sound sample source and passes it to a sink device
class SoundInput : public QObject
{
  Q_OBJECT;

 private:
  Q_DISABLE_COPY (SoundInput);

 public:
  SoundInput (QObject * parent = 0)
    : QObject (parent)
  {
  }

  ~SoundInput ();

Q_SIGNALS:
  void error (QString message) const;
  void status (QString message) const;

public Q_SLOTS:
  // sink must exist from the start call to any following stop () call
  bool start(QAudioDeviceInfo const&, unsigned channels, int framesPerBuffer, QIODevice * sink);
  void stop();

private:
  bool audioError () const;

  QScopedPointer<QAudioInput> m_stream;

private Q_SLOTS:
  void handleStateChanged (QAudio::State) const;
};

#endif
