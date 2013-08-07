#include "soundout.h"

#include <QDateTime>
#include <QAudioDeviceInfo>
#include <QAudioOutput>
#include <QDebug>

#if defined (WIN32)
# define MS_BUFFERED 1000
#else
# define MS_BUFFERED 2000
#endif

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

SoundOutput::SoundOutput (QIODevice * source)
  : m_source (source)
  , m_active (false)
  , m_currentDevice (QAudioDeviceInfo::defaultOutputDevice ())
{
  Q_ASSERT (source);
}

void SoundOutput::startStream (QAudioDeviceInfo const& device)
{
  if (!m_stream || device != m_currentDevice)
    {
      QAudioFormat format (device.preferredFormat ());

#ifdef UNIX
      format.setChannelCount (2);
#else
      format.setChannelCount (1);
#endif

      format.setCodec ("audio/pcm");
      format.setSampleRate (48000);
      format.setSampleType (QAudioFormat::SignedInt);
      format.setSampleSize (16);
      if (!format.isValid ())
	{
	  Q_EMIT error (tr ("Requested output audio format is not valid."));
	}
      if (!device.isFormatSupported (format))
	{
	  Q_EMIT error (tr ("Requested output audio format is not supported on device."));
	}

      m_stream.reset (new QAudioOutput (device, format, this));
      audioError ();

      connect (m_stream.data(), &QAudioOutput::stateChanged, this, &SoundOutput::handleStateChanged);

      m_currentDevice = device;
    }

  //
  // This buffer size is critical since we are running in the GUI
  // thread. If it is too short; high activity levels on the GUI can
  // starve the audio buffer. On the other hand the Windows
  // implementation seems to take the length of the buffer in time to
  // stop the audio stream even if reset() is used.
  //
  // 1 seconds seems a reasonable compromise except for Windows
  // where things are probably broken.
  //
  // we have to set this before every start on the stream because the
  // Windows implementation seems to forget the buffer size after a
  // stop.
  m_stream->setBufferSize (m_stream->format ().bytesForDuration (MS_BUFFERED * 1000));
  m_stream->start (m_source);
  audioError ();

  qDebug () << "audio output buffer size = " << m_stream->bufferSize () << " bytes";
}

void SoundOutput::suspend ()
{
  if (m_stream && QAudio::ActiveState == m_stream->state ())
    {
      m_stream->suspend ();
      audioError ();
    }
}

void SoundOutput::resume ()
{
  if (m_stream && QAudio::SuspendedState == m_stream->state ())
    {
      m_stream->resume ();
      audioError ();
    }
}

void SoundOutput::stopStream ()
{
  if (m_stream)
    {
      m_stream->stop ();
      audioError ();
    }
}

void SoundOutput::handleStateChanged (QAudio::State newState)
{
  switch (newState)
    {
    case QAudio::IdleState:
      qDebug () << "SoundOutput: entered Idle state";
      Q_EMIT status (tr ("Idle"));
      m_active = false;
      break;

    case QAudio::ActiveState:
      qDebug () << "SoundOutput: entered Active state";
      m_active = true;
      Q_EMIT status (tr ("Sending"));
      break;

    case QAudio::SuspendedState:
      qDebug () << "SoundOutput: entered Suspended state";
      m_active = true;
      Q_EMIT status (tr ("Suspended"));
      break;

    case QAudio::StoppedState:
      qDebug () << "SoundOutput: entered Stopped state";
      m_active = false;
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

SoundOutput::~SoundOutput ()
{
  if (m_stream)
    {
      m_stream->stop ();
    }
}
