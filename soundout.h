// -*- Mode: C++ -*-
#ifndef SOUNDOUT_H__
#define SOUNDOUT_H__

#include <QObject>
#include <QString>
#include <QAudioOutput>
#include <QAudioDeviceInfo>

class QAudioDeviceInfo;

// An instance of this sends audio data to a specified soundcard.

class SoundOutput
  : public QObject
{
  Q_OBJECT;
  
public:
  qreal attenuation () const;
  QAudioOutput * stream () {return m_stream.data ();}

public Q_SLOTS:
  void setFormat (QAudioDeviceInfo const& device, unsigned channels, unsigned msBuffered = 0u);
  void suspend ();
  void resume ();
  void setAttenuation (qreal);	/* unsigned */
  void resetAttenuation ();	/* to zero */
  
Q_SIGNALS:
  void error (QString message) const;
  void status (QString message) const;

private:
  bool audioError () const;

private Q_SLOTS:
  void handleStateChanged (QAudio::State);

private:
  QScopedPointer<QAudioOutput> m_stream;
  qreal m_volume;
};

#endif
