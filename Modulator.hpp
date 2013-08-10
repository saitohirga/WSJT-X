#ifndef MODULATOR_HPP__
#define MODULATOR_HPP__

#include "AudioDevice.hpp"

#ifdef UNIX
# define NUM_CHANNELS 2
#else
# define NUM_CHANNELS 1
#endif

//
// Input device that generates PCM audio frames that encode a message
// and an optional CW ID.
//
// Output can be muted while underway, preserving waveform timing when
// transmission is resumed.
//
class Modulator : public AudioDevice
{
  Q_OBJECT;

  Q_PROPERTY (unsigned frequency READ frequency WRITE setFrequency);
  Q_PROPERTY (bool tuning READ isTuning WRITE tune);
  Q_PROPERTY (bool muted READ isMuted WRITE mute);

public:
  enum ModulatorState {Synchronizing, Active, Idle};

  Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent = 0);

  Q_SLOT void open (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, AudioDevice::Channel, bool synchronize = true, double dBSNR = 99.);

  bool isTuning () const {return m_tuning;}
  bool isMuted () const {return m_muted;}
  unsigned frequency () const {return m_frequency;}
  bool isActive () const {return m_state != Idle;}

protected:
  qint64 readData (char * data, qint64 maxSize);
  qint64 writeData (char const * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't consume data
  }

private:
  /* private because we epect to run in a thread and don't want direct
     C++ calls made, instead they must be invoked via the Qt
     signal/slot mechanism which is thread safe */
  Q_SLOT void close ()
  {
    Q_EMIT stateChanged ((m_state = Idle));
    AudioDevice::close ();
  }

  Q_SLOT void tune (bool newState = true) {m_tuning = newState;}
  Q_SLOT void mute (bool newState = true) {m_muted = newState;}
  Q_SLOT void setFrequency (unsigned newFrequency) {m_frequency = newFrequency;}
  Q_SIGNAL void stateChanged (ModulatorState);

private:
  qint16 postProcessSample (qint16 sample) const;

  unsigned m_symbolsLength;

  static double const m_twoPi;
  static unsigned const m_nspd;	// CW ID WPM factor

  int m_frameRate;
  int m_period;
  double m_nsps;
  double volatile m_frequency;
  double m_snr;
  qint64 m_silentFrames;
  qint64 m_framesSent;
  ModulatorState volatile m_state;
  bool volatile m_tuning;
  bool volatile m_muted;
  bool m_addNoise;
  double m_phi;
  double m_dphi;
  double m_amp;
  unsigned m_ic;
  double m_fac;
  unsigned m_isym0;
  qint16 m_ramp;
};

#endif
