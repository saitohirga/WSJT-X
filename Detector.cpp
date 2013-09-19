#include "Detector.hpp"

#include <QDateTime>
#include <QtAlgorithms>
#include <QDebug>

#include "commons.h"

Detector::Detector (unsigned frameRate, unsigned periodLengthInSeconds, unsigned framesPerSignal, QObject * parent)
  : AudioDevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_framesPerSignal (framesPerSignal)
  , m_monitoring (false)
  , m_starting (false)
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

      qint64 framesAcceptable (sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]) - jt9com_.kin);
      qint64 framesAccepted (qMin (static_cast<qint64> (maxSize / bytesPerFrame ()), framesAcceptable));
  
      if (framesAccepted < static_cast<qint64> (maxSize / bytesPerFrame ()))
	{
	  qDebug () << "dropped " << maxSize / sizeof (jt9com_.d2[0]) - framesAccepted << " frames of data on the floor!";
	}

      store (data, framesAccepted, &jt9com_.d2[jt9com_.kin]);

      unsigned lastSignalIndex (jt9com_.kin / m_framesPerSignal);
      jt9com_.kin += framesAccepted;
      unsigned currentSignalIndex (jt9com_.kin / m_framesPerSignal);

      if (currentSignalIndex != lastSignalIndex && m_monitoring)
	{
	  Q_EMIT framesWritten (currentSignalIndex * m_framesPerSignal);
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
	      m_starting = true;
	    }
	}
      else if (m_starting)
	{
	  m_starting = false;
	}
    }
  else
    {
      jt9com_.kin = 0;
    }

  return maxSize;		// we drop any data past the end of
				// the buffer on the floor until the
				// next period starts
}

unsigned Detector::secondInPeriod () const
{
  // we take the time of the data as the following assuming no latency
  // delivering it to us (not true but close enough for us)
  qint64 now (QDateTime::currentMSecsSinceEpoch ());

  unsigned secondInToday ((now % 86400000LL) / 1000);
  return secondInToday % m_period;
}
