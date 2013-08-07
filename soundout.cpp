#include "soundout.h"

#include <QDateTime>
#include <QAudioDeviceInfo>
#include <QAudioOutput>
#include <QDebug>

bool SoundOutput::audioError () const
{
  bool result (true);

  Q_ASSERT_X (m_stream, "SoundOutput", "programming error");
  if (m_stream)
    {
      switch (m_stream->error ())
	{
	case QAudio::OpenError:
	  Q_EMIT error (tr ("An error opening the audio output device has occurred."));
	  break;

	case QAudio::IOError:
	  Q_EMIT error (tr ("An error occurred during write to the audio output device."));
	  break;

	case QAudio::UnderrunError:
	  Q_EMIT error (tr ("Audio data not being fed to the audio output device fast enough."));
	  break;

	case QAudio::FatalError:
	  Q_EMIT error (tr ("Non-recoverable error, audio output device not usable at this time."));
	  break;

	case QAudio::NoError:
	  result = false;
	  break;
	}
    }
  return result;
}

bool SoundOutput::start(QAudioDeviceInfo const& device, QIODevice * source)
{
  Q_ASSERT (source);

  stop();

  QAudioFormat format (device.preferredFormat());
  format.setChannelCount (1);
  format.setCodec ("audio/pcm");
  format.setSampleRate (48000);
  format.setSampleType (QAudioFormat::SignedInt);
  format.setSampleSize (16);
  if (!format.isValid ())
    {
      Q_EMIT error (tr ("Requested output audio format is not valid."));
      return false;
    }
  if (!device.isFormatSupported (format))
    {
      Q_EMIT error (tr ("Requested output audio format is not supported on device."));
      return false;
    }

  m_stream.reset (new QAudioOutput (device, format, this));
  if (audioError ())
    {
      return false;
    }
  connect (m_stream.data(), &QAudioOutput::stateChanged, this, &SoundOutput::handleStateChanged);

  m_stream->setBufferSize(48000);
  m_stream->start (source);
  if (audioError ())		// start the input stream
    {
      return false;
    }

  m_active = true;
  return true;
}

void SoundOutput::handleStateChanged (QAudio::State newState) const
{
  switch (newState)
    {
    case QAudio::IdleState: Q_EMIT status (tr ("Idle")); break;
    case QAudio::ActiveState: Q_EMIT status (tr ("Sending")); break;
    case QAudio::SuspendedState: Q_EMIT status (tr ("Suspended")); break;

    case QAudio::StoppedState:
      if (audioError ())
	{
	  Q_EMIT status (tr ("Error"));
	}
      else
	{
	  Q_EMIT status (tr ("Stopped"));
	}
      break;
    }
}

void SoundOutput::stop()
{
  m_stream.reset ();
  m_active = false;
}

SoundOutput::~SoundOutput()
{
  stop ();
}
