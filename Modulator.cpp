#include "Modulator.hpp"
#include <limits>
#include <qmath.h>
#include <QDateTime>
#include <QDebug>
#include "mainwindow.h"

#include "moc_Modulator.cpp"

extern float gran();		// Noise generator (for tests only)

#define RAMP_INCREMENT 64  // MUST be an integral factor of 2^16

#if defined (WSJT_SOFT_KEYING)
# define SOFT_KEYING WSJT_SOFT_KEYING
#else
# define SOFT_KEYING 1
#endif

double const Modulator::m_twoPi = 2.0 * 3.141592653589793238462;

//    float wpm=20.0;
//    unsigned m_nspd=1.2*48000.0/wpm;
//    m_nspd=3072;                           //18.75 WPM
unsigned const Modulator::m_nspd = 2048 + 512; // 22.5 WPM

Modulator::Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent)
  : AudioDevice {parent}
  , m_stream {nullptr}
  , m_quickClose {false}
  , m_phi {0.0}
  , m_toneSpacing {0.0}
  , m_fSpread {0.0}
  , m_frameRate {frameRate}
  , m_period {periodLengthInSeconds}
  , m_state {Idle}
  , m_tuning {false}
  , m_cwLevel {false}
{
  qsrand (QDateTime::currentMSecsSinceEpoch()); // Initialize random
                                                // seed
}

void Modulator::start (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, double toneSpacing, SoundOutput * stream, Channel channel, bool synchronize, double dBSNR)
{
  Q_ASSERT (stream);

  // Time according to this computer which becomes our base time
  qint64 ms0 = QDateTime::currentMSecsSinceEpoch() % 86400000;

  // qDebug () << "Modulator: Using soft keying for CW is " << SOFT_KEYING;;

  if (m_state != Idle)
    {
      stop ();
    }

  m_quickClose = false;

  m_symbolsLength = symbolsLength;
  m_isym0 = std::numeric_limits<unsigned>::max (); // Arbitrary big number
  m_addNoise = dBSNR < 0.;
  m_nsps = framesPerSymbol;
  m_frequency = frequency;
  m_amp = std::numeric_limits<qint16>::max ();
  m_toneSpacing = toneSpacing;

  // noise generator parameters
  if (m_addNoise) {
    m_snr = qPow (10.0, 0.05 * (dBSNR - 6.0));
    m_fac = 3000.0;
    if (m_snr > 1.0) m_fac = 3000.0 / m_snr;
  }

  unsigned mstr = ms0 % (1000 * m_period); // ms in period
  m_ic = (mstr / 1000) * m_frameRate; // we start exactly N seconds
  // into period where N is the next whole second

  m_silentFrames = 0;
  // calculate number of silent frames to send
  if (synchronize && !m_tuning)	{
    m_silentFrames = m_ic + m_frameRate - (mstr * m_frameRate / 1000);
  }

  //  qDebug () << "Modulator: starting at " << m_ic / m_frameRate << " sec, sending " << m_silentFrames << " silent frames";

  initialize (QIODevice::ReadOnly, channel);
  Q_EMIT stateChanged ((m_state = (synchronize && m_silentFrames) ?
                        Synchronizing : Active));
  m_stream = stream;
  if (m_stream)
    {
      m_stream->restart (this);
    }
}

void Modulator::tune (bool newState)
{
  m_tuning = newState;
  if (!m_tuning)
    {
      stop (true);
    }
}

void Modulator::stop (bool quick)
{
  m_quickClose = quick;
  close ();
}

void Modulator::close ()
{
  if (m_stream)
    {
      if (m_quickClose)
        {
          m_stream->reset ();
        }
      else
        {
          m_stream->stop ();
        }
    }
  if (m_state != Idle)
    {
      Q_EMIT stateChanged ((m_state = Idle));
    }
  AudioDevice::close ();
}

qint64 Modulator::readData (char * data, qint64 maxSize)
{
  static int j0=-1;
  static double toneFrequency0;
  double toneFrequency;

  if(maxSize==0) return 0;
  Q_ASSERT (!(maxSize % qint64 (bytesPerFrame ()))); // no torn frames
  Q_ASSERT (isOpen ());

  qint64 numFrames (maxSize / bytesPerFrame ());
  qint16 * samples (reinterpret_cast<qint16 *> (data));
  qint16 * end (samples + numFrames * (bytesPerFrame () / sizeof (qint16)));
  qint64 framesGenerated (0);

  //  qDebug () << "Modulator: " << numFrames << " requested, m_ic = " << m_ic << ", tune mode is " << m_tuning;
  //  qDebug() << "C" << maxSize << numFrames << bytesPerFrame();
  switch (m_state)
    {
    case Synchronizing:
      {
        if (m_silentFrames)	{  // send silence up to first second
          framesGenerated = qMin (m_silentFrames, numFrames);
          for ( ; samples != end; samples = load (0, samples)) { // silence
          }
          m_silentFrames -= framesGenerated;
          return framesGenerated * bytesPerFrame ();
        }

        Q_EMIT stateChanged ((m_state = Active));
        m_cwLevel = false;
        m_ramp = 0;		// prepare for CW wave shaping
      }
      // fall through

    case Active:
      {
        unsigned isym (m_tuning ? 0 : m_ic / (4.0 * m_nsps)); // Actual fsample=48000
        if (isym >= m_symbolsLength && icw[0] > 0) { // start CW condition
          // Output the CW ID
          m_dphi = m_twoPi * m_frequency / m_frameRate;
          unsigned const ic0 = m_symbolsLength * 4 * m_nsps;
          unsigned j (0);

          while (samples != end) {
            j = (m_ic - ic0) / m_nspd + 1; // symbol of this sample
            bool level {bool (icw[j])};

            m_phi += m_dphi;
            if (m_phi > m_twoPi) m_phi -= m_twoPi;

            qint16 sample ((SOFT_KEYING ? qAbs (m_ramp - 1) :
                            (m_ramp ? 32767 : 0)) * qSin (m_phi));

            if (int (j) <= icw[0] && j < NUM_CW_SYMBOLS) // stop condition
              {
                samples = load (postProcessSample (sample), samples);
                ++framesGenerated;
                ++m_ic;
              }
            else
              {
                Q_EMIT stateChanged ((m_state = Idle));
                return framesGenerated * bytesPerFrame ();
              }

            // adjust ramp
            if ((m_ramp != 0 && m_ramp != std::numeric_limits<qint16>::min ()) || level != m_cwLevel)
              {
                // either ramp has terminated at max/min or direction
                // has changed
                m_ramp += RAMP_INCREMENT; // ramp
              }

            // if (m_cwLevel != level)
            //   {
            //     qDebug () << "@m_ic:" << m_ic << "icw[" << j << "] =" << icw[j] << "@" << framesGenerated << "in numFrames:" << numFrames;
            //   }

            m_cwLevel = level;
          }

          return framesGenerated * bytesPerFrame ();
        }

        double const baud (12000.0 / m_nsps);
        // fade out parameters (no fade out for tuning)
        unsigned const i0 = m_tuning ? 999 * m_nsps :
          (m_symbolsLength - 0.017) * 4.0 * m_nsps;
        unsigned const i1 = m_tuning ? 999 * m_nsps :
          m_symbolsLength * 4.0 * m_nsps;

        for (unsigned i = 0; i < numFrames && m_ic <= i1; ++i) {
          isym = m_tuning ? 0 : m_ic / (4.0 * m_nsps); //Actual fsample=48000
          if (isym != m_isym0) {
            // qDebug () << "@m_ic:" << m_ic << "itone[" << isym << "] =" << itone[isym] << "@" << i << "in numFrames:" << numFrames;

            if(m_toneSpacing==0.0) {
              toneFrequency0=m_frequency + itone[isym]*baud;
            } else {
              toneFrequency0=m_frequency + itone[isym]*m_toneSpacing;
            }
            m_dphi = m_twoPi * toneFrequency0 / m_frameRate;
            m_isym0 = isym;
          }

          int j=m_ic/480;
          if(m_fSpread>0.0 and j!=j0) {
            float x1=(float)rand()/RAND_MAX;
            float x2=(float)rand()/RAND_MAX;
            toneFrequency = toneFrequency0 + 0.5*m_fSpread*(x1+x2-1.0);
            m_dphi = m_twoPi * toneFrequency / m_frameRate;
            j0=j;
          }

          m_phi += m_dphi;
          if (m_phi > m_twoPi) m_phi -= m_twoPi;
          if (m_ic > i0) m_amp = 0.98 * m_amp;
          if (m_ic > i1) m_amp = 0.0;

          samples = load (postProcessSample (m_amp * qSin (m_phi)), samples);
          ++framesGenerated;
          ++m_ic;
        }

        if (m_amp == 0.0) { // TODO G4WJS: compare double with zero might not be wise
          if (icw[0] == 0) {
            // no CW ID to send
            Q_EMIT stateChanged ((m_state = Idle));
            return framesGenerated * bytesPerFrame ();
          }

          m_phi = 0.0;
        }

        // done for this chunk - continue on next call
        return framesGenerated * bytesPerFrame ();
      }
      // fall through

    case Idle:
      break;
    }

  Q_ASSERT (Idle == m_state);
  return 0;
}

qint16 Modulator::postProcessSample (qint16 sample) const
{
  if (m_addNoise) {  // Test frame, we'll add noise
    qint32 s = m_fac * (gran () + sample * m_snr / 32768.0);
    if (s > std::numeric_limits<qint16>::max ()) {
      s = std::numeric_limits<qint16>::max ();
    }
    if (s < std::numeric_limits<qint16>::min ()) {
      s = std::numeric_limits<qint16>::min ();
    }
    sample = s;
  }
  return sample;
}
