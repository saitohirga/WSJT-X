#ifndef MODULATOR_HPP__
#define MODULATOR_HPP__

#include <QAudio>

#include "AudioDevice.hpp"

class SoundOutput;

//
// Input device that generates PCM audio frames that encode a message
// and an optional CW ID.
//
// Output can be muted while underway, preserving waveform timing when
// transmission is resumed.
//
class Modulator
  : public AudioDevice
{
  Q_OBJECT;

public:
  enum ModulatorState {Synchronizing, Active, Idle};

  Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent = nullptr);

  void close () override;

  bool isTuning () const {return m_tuning;}
  unsigned frequency () const {return m_frequency;}
  bool isActive () const {return m_state != Idle;}
  void setSpread(double s) {m_fSpread=s;}

  Q_SLOT void start (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, double toneSpacing, SoundOutput *, Channel = Mono, bool synchronize = true, double dBSNR = 99.);
  Q_SLOT void stop (bool quick = false);
  Q_SLOT void tune (bool newState = true);
  Q_SLOT void setFrequency (unsigned newFrequency) {m_frequency = newFrequency;}
  Q_SIGNAL void stateChanged (ModulatorState) const;

protected:
  qint64 readData (char * data, qint64 maxSize);
  qint64 writeData (char const * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't consume data
  }

private:
  qint16 postProcessSample (qint16 sample) const;

  SoundOutput * m_stream;
  bool m_quickClose;

  unsigned m_symbolsLength;

  static double const m_twoPi;
  static unsigned const m_nspd;	// CW ID WPM factor

  double m_phi;
  double m_dphi;
  double m_amp;
  double m_nsps;
  double volatile m_frequency;
  double m_frequency0;
  double m_snr;
  double m_fac;
  double m_toneSpacing;
  double m_fSpread;

  qint64 m_silentFrames;

  unsigned m_frameRate;
  unsigned m_period;
  ModulatorState volatile m_state;

  bool volatile m_tuning;
  bool m_addNoise;

  bool m_cwLevel;
  unsigned m_ic;
  unsigned m_isym0;
  qint16 m_ramp;
};

#endif
