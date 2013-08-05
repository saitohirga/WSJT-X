#include "Detector.hpp"

#include <algorithm>

#include <QDateTime>
#include <QDebug>

#include "commons.h"

Detector::Detector (unsigned frameRate, unsigned periodLengthInSeconds, unsigned bytesPerSignal, QObject * parent)
  : QIODevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_bytesPerSignal (bytesPerSignal)
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
  // set index to roughly where we are in time (1s resolution)
  jt9com_.kin = secondInPeriod () * m_frameRate;

  // fill buffer with zeros
  std::fill (jt9com_.d2, jt9com_.d2 + sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]), 0);
}

qint64 Detector::writeData (char const * data, qint64 maxSize)
{
  Q_ASSERT (!(maxSize % sizeof (jt9com_.d2[0]))); // no torn frames
  Q_ASSERT (!(reinterpret_cast<size_t> (data) % __alignof__ (frame_t)));	  // data is aligned as frame_t would be

  frame_t const * frames (reinterpret_cast<frame_t const *> (data));

  qint64 framesAcceptable (sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]) - jt9com_.kin);
  qint64 framesAccepted (std::min (maxSize / sizeof (jt9com_.d2[0]), framesAcceptable));
  
  if (framesAccepted < maxSize / sizeof (jt9com_.d2[0]))
    {
      qDebug () << "dropped " << maxSize / sizeof (jt9com_.d2[0]) - framesAccepted << " frames of data on the floor!\n";
    }

  std::copy (frames, frames + framesAccepted, &jt9com_.d2[jt9com_.kin]);

  unsigned lastSignalIndex (jt9com_.kin * sizeof (jt9com_.d2[0]) / m_bytesPerSignal);
  jt9com_.kin += framesAccepted;
  unsigned currentSignalIndex (jt9com_.kin * sizeof (jt9com_.d2[0]) / m_bytesPerSignal);

  if (currentSignalIndex != lastSignalIndex && m_monitoring)
    {
      Q_EMIT bytesWritten (currentSignalIndex * m_bytesPerSignal);
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
