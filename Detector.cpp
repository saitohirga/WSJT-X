#include "Detector.hpp"
#include <QDateTime>
#include <QtAlgorithms>
#include <QDebug>
#include "commons.h"

#include "moc_Detector.cpp"

extern "C" {
  void   fil4_(qint16*, qint32*, qint16*, qint32*);
}

Detector::Detector (unsigned frameRate, unsigned periodLengthInSeconds,
                    unsigned samplesPerFFT, unsigned downSampleFactor,
                    QObject * parent)
  : AudioDevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_downSampleFactor (downSampleFactor)
  , m_samplesPerFFT (samplesPerFFT)
  , m_ns (999)
  , m_buffer ((downSampleFactor > 1) ?
              new short [samplesPerFFT * downSampleFactor] : 0)
  , m_bufferPos (0)
{
  (void)m_frameRate;            // quell compiler warning
  clear ();
}

bool Detector::reset ()
{
  clear ();
  // don't call base call reset because it calls seek(0) which causes
  // a warning
  return isOpen ();
}

void Detector::clear ()
{
  // set index to roughly where we are in time (1ms resolution)
  // qint64 now (QDateTime::currentMSecsSinceEpoch ());
  // unsigned msInPeriod ((now % 86400000LL) % (m_period * 1000));
  // jt9com_.kin = qMin ((msInPeriod * m_frameRate) / 1000, static_cast<unsigned> (sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0])));
  jt9com_.kin = 0;
  m_bufferPos = 0;

  // fill buffer with zeros (G4WJS commented out because it might cause decoder hangs)
  // qFill (jt9com_.d2, jt9com_.d2 + sizeof (jt9com_.d2) / sizeof (jt9com_.d2[0]), 0);
}

qint64 Detector::writeData (char const * data, qint64 maxSize)
{
  int ns=secondInPeriod();
  if(ns < m_ns) {                      // When ns has wrapped around to zero, restart the buffers
    jt9com_.kin = 0;
    m_bufferPos = 0;
  }
  m_ns=ns;

  // no torn frames
  Q_ASSERT (!(maxSize % static_cast<qint64> (bytesPerFrame ())));
  // these are in terms of input frames (not down sampled)
  size_t framesAcceptable ((sizeof (jt9com_.d2) /
                            sizeof (jt9com_.d2[0]) - jt9com_.kin) * m_downSampleFactor);
  size_t framesAccepted (qMin (static_cast<size_t> (maxSize /
                                                    bytesPerFrame ()), framesAcceptable));

  if (framesAccepted < static_cast<size_t> (maxSize / bytesPerFrame ())) {
    qDebug () << "dropped " << maxSize / bytesPerFrame () - framesAccepted
                << " frames of data on the floor!"
                << jt9com_.kin << ns;
    }

    for (unsigned remaining = framesAccepted; remaining; ) {
      size_t numFramesProcessed (qMin (m_samplesPerFFT *
                                       m_downSampleFactor - m_bufferPos, remaining));

      if(m_downSampleFactor > 1) {
        store (&data[(framesAccepted - remaining) * bytesPerFrame ()],
               numFramesProcessed, &m_buffer[m_bufferPos]);
        m_bufferPos += numFramesProcessed;

        if(m_bufferPos==m_samplesPerFFT*m_downSampleFactor) {
          qint32 framesToProcess (m_samplesPerFFT * m_downSampleFactor);
          qint32 framesAfterDownSample (m_samplesPerFFT);
          if(framesToProcess==13824 and jt9com_.kin>=0 and
             jt9com_.kin < (NTMAX*12000 - framesAfterDownSample)) {
            fil4_(&m_buffer[0], &framesToProcess, &jt9com_.d2[jt9com_.kin],
                  &framesAfterDownSample);
            jt9com_.kin += framesAfterDownSample;
          } else {
            qDebug() << "framesToProcess = " << framesToProcess;
            qDebug() << "jt9com_.kin     = " << jt9com_.kin;
            qDebug() << "secondInPeriod  = " << secondInPeriod();
            qDebug() << "framesAfterDownSample" << framesAfterDownSample;
          }
          Q_EMIT framesWritten (jt9com_.kin);
          m_bufferPos = 0;
        }

      } else {
        store (&data[(framesAccepted - remaining) * bytesPerFrame ()],
               numFramesProcessed, &jt9com_.d2[jt9com_.kin]);
        m_bufferPos += numFramesProcessed;
        jt9com_.kin += numFramesProcessed;
        if (m_bufferPos == static_cast<unsigned> (m_samplesPerFFT)) {
          Q_EMIT framesWritten (jt9com_.kin);
          m_bufferPos = 0;
        }
      }
      remaining -= numFramesProcessed;
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
