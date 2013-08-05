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

bool SoundInput::start(QAudioDeviceInfo const& device, int framesPerBuffer, QIODevice * sink)
{
  stop();

  QAudioFormat format (device.preferredFormat());
  format.setChannelCount (1);
  format.setCodec ("audio/pcm");
  format.setSampleRate (12000);
  format.setSampleType (QAudioFormat::SignedInt);
  format.setSampleSize (16);

  if (!format.isValid ())
    {
      Q_EMIT error (tr ("Requested input audio format is not valid."));
      return false;
    }

  // this function lies!
  // if (!device.isFormatSupported (format))
  //   {
  //     Q_EMIT error (tr ("Requested input audio format is not supported on device."));
  //     return false;
  //   }

  m_stream.reset (new QAudioInput (device, format, this));
  if (audioError ())
    {
      return false;
    }

  connect (m_stream.data(), &QAudioInput::stateChanged, this, &SoundInput::handleStateChanged);

  m_stream->setBufferSize (m_stream->format ().bytesForFrames (framesPerBuffer));

  m_stream->start (sink);

  qDebug () << "audio input buffer size = " << m_stream->bufferSize () << " bytes\n";

  return audioError () ? false : true;
}

void SoundInput::handleStateChanged (QAudio::State newState) const
{
  switch (newState)
    {
    case QAudio::IdleState:
      qDebug () << "SoundInput idle\n";
      Q_EMIT status (tr ("Idle"));
      break;

    case QAudio::ActiveState:
      qDebug () << "SoundInput active\n";
      Q_EMIT status (tr ("Receiving"));
      break;

    case QAudio::SuspendedState:
      qDebug () << "SoundInput suspended\n";
      Q_EMIT status (tr ("Suspended"));
      break;

    case QAudio::StoppedState:
      if (audioError ())
	{
	  qDebug () << "SoundInput error\n";
	  Q_EMIT status (tr ("Error"));
	}
      else
	{
	  qDebug () << "SoundInput stopped\n";
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
