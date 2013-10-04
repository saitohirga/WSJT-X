#include "Detector.hpp"

#include <QDateTime>
#include <QtAlgorithms>
#include <QDebug>

#include "commons.h"

extern "C" {
void   fil4_(qint16*, qint32*, qint16*, qint32*);
}

Detector::Detector (unsigned frameRate, unsigned periodLengthInSeconds, unsigned framesPerSignal, unsigned downSampleFactor, QObject * parent)
  : AudioDevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_downSampleFactor (downSampleFactor)
  , m_framesPerSignal (framesPerSignal)
  , m_monitoring (false)
  , m_starting (false)
  , m_buffer ((downSampleFactor > 1) ? new short [framesPerSignal * downSampleFactor] : 0)
  , m_bufferPos (0)
{
  clear ();
}

bool Detector::reset ()
{
  clear ();
  return QIODevice::reset ();
}

void Detector::clear ()
{
  // set index to roughly where we are in time (1ms resolution)
  // qint64 now (QDateTime::currentMSecsSinceEpoch ());
  // unsigned msInPeriod ((now % 86400000LL) % (m_period * 1000));
  // jt9com_.kin = qMin ((msInPeriod * m_frameRate) / 1000, static_cast<unsigned> (sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0])));
  jt9com_.kin = 0;

  // fill buffer with zeros (G4WJS commented out because it might cause decoder hangs)
  // qFill (jt9com_.d2, jt9com_.d2 + sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]), 0);
}

qint64 Detector::writeData (char const * data, qint64 maxSize)
{
  if (m_monitoring)
    {
      Q_ASSERT (!(maxSize % static_cast<qint64> (bytesPerFrame ()))); // no torn frames

      // these are in terms of input frames (not down sampled)
      size_t framesAcceptable ((sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]) - jt9com_.kin) * m_downSampleFactor);
      size_t framesAccepted (qMin (static_cast<size_t> (maxSize / bytesPerFrame ()), framesAcceptable));

      if (framesAccepted < static_cast<size_t> (maxSize / bytesPerFrame ()))
	{
	  qDebug () << "dropped " << maxSize / bytesPerFrame () - framesAccepted << " frames of data on the floor!";
	}

      for (unsigned remaining = framesAccepted; remaining; )
	{
	  size_t numFramesProcessed (qMin (m_framesPerSignal * m_downSampleFactor - m_bufferPos, remaining));

	  if (m_downSampleFactor > 1)
	    {
	      store (&data[(framesAccepted - remaining) * bytesPerFrame ()], numFramesProcessed, &m_buffer[m_bufferPos]);
	      m_bufferPos += numFramesProcessed;
	      if (m_bufferPos == m_framesPerSignal * m_downSampleFactor && m_monitoring)
		{
		  qint32 framesToProcess (m_framesPerSignal * m_downSampleFactor);
		  qint32 framesAfterDownSample;
		  fil4_(&m_buffer[0], &framesToProcess, &jt9com_.d2[jt9com_.kin], &framesAfterDownSample);
		  jt9com_.kin += framesAfterDownSample;
		  Q_EMIT framesWritten (jt9com_.kin);
		  m_bufferPos = 0;
		}

	    }
	  else
	    {
	      store (&data[(framesAccepted - remaining) * bytesPerFrame ()], numFramesProcessed, &jt9com_.d2[jt9com_.kin]);
	      m_bufferPos += numFramesProcessed;
	      jt9com_.kin += numFramesProcessed;
	      if (m_bufferPos == static_cast<unsigned> (m_framesPerSignal) && m_monitoring)
		{
		  Q_EMIT framesWritten (jt9com_.kin);
		  m_bufferPos = 0;
		}
	    }

	  if (!secondInPeriod ())
	    {
	      if (!m_starting)
		{
		  // next samples will be in new period so wrap around to
		  // start of buffer
		  //
		  // we don't bother calling reset () since we expect to fill
		  // the whole buffer and don't need to waste cycles zeroing
		  jt9com_.kin = 0;
		  m_bufferPos = 0;
		  m_starting = true;
		}
	    }
	  else if (m_starting)
	    {
	      m_starting = false;
	    }
	  remaining -= numFramesProcessed;
	}
    }
  else
    {
      jt9com_.kin = 0;
      m_bufferPos = 0;
    }

  return maxSize;    // we drop any data past the end of the buffer on
		     // the floor until the next period starts
}

unsigned Detector::secondInPeriod () const
{
  // we take the time of the data as the following assuming no latency
  // delivering it to us (not true but close enough for us)
  qint64 now (QDateTime::currentMSecsSinceEpoch ());

  unsigned secondInToday ((now % 86400000LL) / 1000);
  return secondInToday % m_period;
}
