#include "Modulator.hpp"

#include <limits>

#include <qmath.h>
#include <QDateTime>
#include <QDebug>

#include "mainwindow.h"

extern float gran();		// Noise generator (for tests only)

// MUST be an integral factor of 2^16
#define RAMP_INCREMENT 64

#if defined (WSJT_SOFT_KEYING)
# define SOFT_KEYING true
#else
# define SOFT_KEYING false
#endif

double const Modulator::m_twoPi = 2.0 * 3.141592653589793238462;

//    float wpm=20.0;
//    unsigned m_nspd=1.2*48000.0/wpm;
//    m_nspd=3072;                           //18.75 WPM
unsigned const Modulator::m_nspd = 2048 + 512; // 22.5 WPM

Modulator::Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent)
  : AudioDevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_framesSent (0)
  , m_state (Idle)
  , m_tuning (false)
  , m_muted (false)
  , m_phi (0.)
{
  qsrand (QDateTime::currentMSecsSinceEpoch()); // Initialize random seed
}

void Modulator::open (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, Channel channel, bool synchronize, double dBSNR)
{
  // Time according to this computer which becomes our base time
  qint64 ms0 = QDateTime::currentMSecsSinceEpoch() % 86400000;

  qDebug () << "Modulator: Using soft keying for CW is " << SOFT_KEYING;;

  m_symbolsLength = symbolsLength;

  m_framesSent = 0;
  m_isym0 = std::numeric_limits<unsigned>::max (); // ensure we set up first symbol tone
  m_addNoise = dBSNR < 0.;
  m_nsps = framesPerSymbol;
  m_frequency = frequency;
  m_amp = std::numeric_limits<qint16>::max ();

  // noise generator parameters
  if (m_addNoise)
    {
      m_snr = qPow (10.0, 0.05 * (dBSNR - 6.0));
      m_fac = 3000.0;
      if (m_snr > 1.0)
	{
	  m_fac = 3000.0 / m_snr;
	}
    }

  unsigned mstr = ms0 % (1000 * m_period); // ms in period
  m_ic = (mstr / 1000) * m_frameRate; // we start exactly N seconds
				      // into period where N is the
				      // next whole second

  m_silentFrames = 0;
  if (synchronize && !m_tuning)	// calculate number of silent frames to send
    {
      m_silentFrames = m_ic + m_frameRate - (mstr * m_frameRate / 1000);
    }

//  qDebug () << "Modulator: starting at " << m_ic / m_frameRate << " sec, sending " << m_silentFrames << " silent frames";

  AudioDevice::open (QIODevice::ReadOnly, channel);
  Q_EMIT stateChanged ((m_state = (synchronize && m_silentFrames) ? Synchronizing : Active));
}

qint64 Modulator::readData (char * data, qint64 maxSize)
{
  Q_ASSERT (!(maxSize % static_cast<qint64> (bytesPerFrame ()))); // no torn frames
  Q_ASSERT (isOpen ());

  qint64 numFrames (maxSize / bytesPerFrame ());
  qint16 * samples (reinterpret_cast<qint16 *> (data));
  qint16 * end (samples + numFrames * (bytesPerFrame () / sizeof (qint16)));

//  qDebug () << "Modulator: " << numFrames << " requested, m_ic = " << m_ic << ", tune mode is " << m_tuning;

  switch (m_state)
    {
    case Synchronizing:
      {
	if (m_silentFrames)	// send silence up to first second
	  {
	    numFrames = qMin (m_silentFrames, numFrames);
	    for ( ; samples != end; samples = load (0, samples)) // silence
	      {
	      }
	    m_silentFrames -= numFrames;
	    return numFrames * bytesPerFrame ();
	  }

	Q_EMIT stateChanged ((m_state = Active));
	m_ramp = 0;		// prepare for CW wave shaping
      }
      // fall through

    case Active:
      {
	unsigned isym (m_tuning ? 0 : m_ic / (4.0 * m_nsps)); // Actual fsample=48000

	if (isym >= m_symbolsLength && icw[0] > 0) // start CW condition
	  {
	    // Output the CW ID
	    m_dphi = m_twoPi * m_frequency / m_frameRate;

	    unsigned const ic0 = m_symbolsLength * 4 * m_nsps;
	    unsigned j (0);
	    qint64 framesGenerated (0);

	    while (samples != end)
	      {
		m_phi += m_dphi;
		if (m_phi > m_twoPi)
		  {
		    m_phi -= m_twoPi;
		  }

		qint16 sample ((SOFT_KEYING ? qAbs (m_ramp - 1) : (m_ramp ? 32767 : 0)) * qSin (m_phi));

		j = (m_ic - ic0 - 1) / m_nspd + 1;
		bool l0 (icw[j] && icw[j] <= 1); // first element treated specially as it's a count
		j = (m_ic - ic0) / m_nspd + 1;

		if ((m_ramp != 0 && m_ramp != std::numeric_limits<qint16>::min ()) || !!icw[j] != l0)
		  {
		    if (!!icw[j] != l0)
		      {
			Q_ASSERT (m_ramp == 0 || m_ramp == std::numeric_limits<qint16>::min ());
		      }
		    m_ramp += RAMP_INCREMENT; // ramp
		  }

		if (j < NUM_CW_SYMBOLS) // stop condition
		  {
		    // if (!m_ramp && !icw[j])
		    //   {
		    // 	sample = 0;
		    //   }

		    samples = load (postProcessSample (sample), samples);

		    ++framesGenerated;
		    ++m_ic;
		  }
	      }

	    if (j > static_cast<unsigned> (icw[0]))
	      {
		Q_EMIT stateChanged ((m_state = Idle));
	      }

	    m_framesSent += framesGenerated;
	    return framesGenerated * bytesPerFrame ();
	  }

	double const baud (12000.0 / m_nsps);

	// fade out parameters (no fade out for tuning)
	unsigned const i0 = m_tuning ? 999 * m_nsps : (m_symbolsLength - 0.017) * 4.0 * m_nsps;
	unsigned const i1 = m_tuning ? 999 * m_nsps : m_symbolsLength * 4.0 * m_nsps;

	for (unsigned i = 0; i < numFrames; ++i)
	  {
	    isym = m_tuning ? 0 : m_ic / (4.0 * m_nsps); //Actual fsample=48000
	    if (isym != m_isym0)
	      {
		double toneFrequency = m_frequency + itone[isym] * baud;
		m_dphi = m_twoPi * toneFrequency / m_frameRate;
		m_isym0 = isym;
	      }
	    m_phi += m_dphi;
	    if (m_phi > m_twoPi)
	      {
		m_phi -= m_twoPi;
	      }
	    if (m_ic > i0)
	      {
		m_amp = 0.98 * m_amp;
	      }
	    if (m_ic > i1)
	      {
		m_amp = 0.0;
	      }

	    samples = load (postProcessSample (m_amp * qSin (m_phi)), samples);

	    ++m_ic;
	  }

	if (m_amp == 0.0) // TODO G4WJS: compare double with zero might not be wise
	  {
	    if (icw[0] == 0)
	      {
		// no CW ID to send
		Q_EMIT stateChanged ((m_state = Idle));
		m_framesSent += numFrames;
		return numFrames * bytesPerFrame ();
	      }

	    m_phi = 0.0;
	  }

	// done for this chunk - continue on next call
	m_framesSent += numFrames;
	return numFrames * bytesPerFrame ();
      }
      Q_EMIT stateChanged ((m_state = Idle));
      // fall through

    case Idle:
      break;
    }

  Q_ASSERT (Idle == m_state);
  return 0;
}

qint16 Modulator::postProcessSample (qint16 sample) const
{
  if (m_muted)			// silent frame
    {
      sample = 0;
    }
  else if (m_addNoise)
    {
      qint32 s = m_fac * (gran () + sample * m_snr / 32768.0);
      if (s > std::numeric_limits<qint16>::max ())
	{
	  s = std::numeric_limits<qint16>::max ();
	}
      if (s < std::numeric_limits<qint16>::min ())
	{
	  s = std::numeric_limits<qint16>::min ();
	}
      sample = s;
    }
  return sample;
}
