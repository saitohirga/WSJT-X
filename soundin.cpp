#include "soundin.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QAudioInput>
#include <QDebug>

bool SoundInput::audioError () const
{
  bool result (true);

  Q_ASSERT_X (m_stream, "SoundInput", "programming error");
  if (m_stream)
    {
      switch (m_stream->error ())
	{
	case QAudio::OpenError:
	  Q_EMIT error (tr ("An error opening the audio input device has occurred."));
	  break;

	case QAudio::IOError:
	  Q_EMIT error (tr ("An error occurred during read from the audio input device."));
	  break;

	case QAudio::UnderrunError:
	  Q_EMIT error (tr ("Audio data not being fed to the audio input device fast enough."));
	  break;

	case QAudio::FatalError:
	  Q_EMIT error (tr ("Non-recoverable error, audio input device not usable at this time."));
	  break;

	case QAudio::NoError:
	  result = false;
	  break;
	}
    }
  return result;
}

void SoundInput::start(QAudioDeviceInfo const& device, unsigned channels, int framesPerBuffer, QIODevice * sink, unsigned downSampleFactor)
{
  Q_ASSERT (0 < channels && channels < 3);
  Q_ASSERT (sink);

  stop();

  QAudioFormat format (device.preferredFormat());
  format.setChannelCount (channels);
  format.setCodec ("audio/pcm");
  format.setSampleRate (12000 * downSampleFactor);
  format.setSampleType (QAudioFormat::SignedInt);
  format.setSampleSize (16);

  if (!format.isValid ())
    {
      Q_EMIT error (tr ("Requested input audio format is not valid."));
      return;
    }

  // this function lies!
  // if (!device.isFormatSupported (format))
  //   {
  //     Q_EMIT error (tr ("Requested input audio format is not supported on device."));
  //     return;
  //   }

  m_stream.reset (new QAudioInput (device, format, this));
  if (audioError ())
    {
      return;
    }

  connect (m_stream.data(), &QAudioInput::stateChanged, this, &SoundInput::handleStateChanged);
  m_stream->setBufferSize (m_stream->format ().bytesForFrames (framesPerBuffer));
  m_stream->start (sink);
  audioError ();
}

void SoundInput::handleStateChanged (QAudio::State newState) const
{
  switch (newState)
    {
    case QAudio::IdleState:
      Q_EMIT status (tr ("Idle"));
      break;

    case QAudio::ActiveState:
      Q_EMIT status (tr ("Receiving"));
      break;

    case QAudio::SuspendedState:
      Q_EMIT status (tr ("Suspended"));
      break;

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

void SoundInput::stop()
{
  if (m_stream)
    {
      m_stream->stop ();
    }
  m_stream.reset ();
}

SoundInput::~SoundInput ()
{
}
