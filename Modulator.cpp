#include "Modulator.hpp"

#include <cstdlib>
#include <cmath>
#include <algorithm>
#include <limits>

#include <QDateTime>

extern float gran();		// Noise generator (for tests only)

double const Modulator::m_twoPi = 2.0 * 3.141592653589793238462;

//    float wpm=20.0;
//    unsigned m_nspd=1.2*48000.0/wpm;
//    m_nspd=3072;                           //18.75 WPM
unsigned const Modulator::m_nspd = 2048 + 512; // 22.5 WPM

Modulator::Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent)
  : QIODevice (parent)
  , m_frameRate (frameRate)
  , m_period (periodLengthInSeconds)
  , m_state (Idle)
  , m_phi (0.)
  , m_ic (0)
  , m_isym0 (std::numeric_limits<unsigned>::max ()) // ensure we set up first symbol tone
{
}

bool Modulator::open (std::vector<int> const * symbols, std::vector<int> const * cw, double framesPerSymbol, unsigned frequency, double dBSNR)
{
  m_symbols.reset (symbols);	// take over ownership (cannot throw)
  m_cw.reset (cw);		// take over ownership (cannot throw)
  m_addNoise = dBSNR < 0.;
  m_nsps = framesPerSymbol;
  m_frequency = frequency;
  m_amp = std::numeric_limits<frame_t>::max ();
  m_state = Idle;

  // noise generator parameters
  if (m_addNoise)
    {
      m_snr = std::pow (10.0, 0.05 * (dBSNR - 6.0));
      m_fac = 3000.0;
      if (m_snr > 1.0)
	{
	  m_fac = 3000.0 / m_snr;
	}
    }
  
  return QIODevice::open (QIODevice::ReadOnly);
}

qint64 Modulator::readData (char * data, qint64 maxSize)
{
  frame_t * frames (reinterpret_cast<frame_t *> (data));
  unsigned numFrames (maxSize / sizeof (frame_t));

  switch (m_state)
    {
    case Idle:
      {
	// Time according to this computer
	qint64 ms = QDateTime::currentMSecsSinceEpoch() % 86400000;
	unsigned mstr = ms % (1000 * m_period);
	if (mstr < 1000)	// send silence up to first second
	  {
	    std::fill (frames, frames + numFrames, 0);		 // silence
	    return numFrames * sizeof (frame_t);
	  }
	m_ic = (mstr - 1000) * 48;

	std::srand (mstr);		// Initialize random seed

	m_state = Active;
      }
      // fall through

    case Active:
      {
	unsigned isym (m_tuning ? 0 : m_ic / (4.0 * m_nsps)); // Actual fsample=48000

	if (isym >= m_symbols->size () && (*m_cw)[0] > 0)
	  {
	    // Output the CW ID
	    m_dphi = m_twoPi * m_frequency / m_frameRate;

	    unsigned const ic0 = m_symbols->size () * 4 * m_nsps;
	    unsigned j (0);
	    for (unsigned i = 0; i < numFrames; ++i)
	      {
		m_phi += m_dphi;
		if (m_phi > m_twoPi)
		  {
		    m_phi -= m_twoPi;
		  }
		frame_t frame = std::numeric_limits<frame_t>::max () * std::sin (m_phi);
		j = (m_ic - ic0) / m_nspd + 1;
		if (!(*m_cw)[j])
		  {
		    frame = 0;
		  }

		frame = postProcessFrame (frame);

		*frames++ = frame; //left
		++m_ic;
	      }
	    if (j > static_cast<unsigned> ((*m_cw)[0]))
	      {
		m_state = Done;
	      }
	    return numFrames * sizeof (frame_t);
	  }

	double const baud (12000.0 / m_nsps);

	// fade out parameters (no fade out for tuning)
	unsigned const i0 = m_tuning ? 999 * m_nsps : (m_symbols->size () - 0.017) * 4.0 * m_nsps;
	unsigned const i1 = m_tuning ? 999 * m_nsps : m_symbols->size () * 4.0 * m_nsps;

	for (unsigned i = 0; i < numFrames; ++i)
	  {
	    isym = m_tuning ? 0 : m_ic / (4.0 * m_nsps); //Actual fsample=48000
	    if (isym != m_isym0)
	      {
		double toneFrequency = m_frequency + (*m_symbols)[isym] * baud;
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
	    frame_t frame (m_amp * std::sin (m_phi));
	    frame = postProcessFrame (frame);
	    *frames++ = frame;	//left
	    ++m_ic;
	  }

	if (m_amp == 0.0) // TODO G4WJS: compare double with zero might not be wise
	  {
	    if ((*m_cw)[0] == 0)
	      {
		// no CW ID to send
		m_state = Done;
		return numFrames * sizeof (frame_t);
	      }

	    m_phi = 0.0;
	  }

	// done for this chunk - continue on next call
	return numFrames * sizeof (frame_t);
      }

    case Done:
      break;
    }

  Q_ASSERT (m_state == Done);
  return 0;
}

Modulator::frame_t Modulator::postProcessFrame (frame_t frame) const
{
  if (m_muted)			// silent frame
    {
      return 0;
    }

  if (m_addNoise)
    {
      int i4 = m_fac * (gran () + frame * m_snr / 32768.0);
      if (i4 > std::numeric_limits<frame_t>::max ())
	{
	  i4 = std::numeric_limits<frame_t>::max ();
	}
      if (i4 < std::numeric_limits<frame_t>::min ())
	{
	  i4 = std::numeric_limits<frame_t>::min ();
	}
      frame = i4;
    }
  return frame;
}
