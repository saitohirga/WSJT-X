#ifndef MODULATOR_HPP__
#define MODULATOR_HPP__

#include <QIODevice>

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
class Modulator : public QIODevice
{
  Q_OBJECT;

  Q_PROPERTY (unsigned frequency READ frequency WRITE setFrequency);
  Q_PROPERTY (bool tuning READ isTuning WRITE tune);
  Q_PROPERTY (bool muted READ isMuted WRITE mute);

private:
  Q_DISABLE_COPY (Modulator);

public:
  Modulator (unsigned frameRate, unsigned periodLengthInSeconds, QObject * parent = 0);

  bool open () {return QIODevice::open (QIODevice::ReadOnly | QIODevice::Unbuffered);}

  Q_SLOT void send (unsigned symbolsLength, double framesPerSymbol, unsigned frequency, bool synchronize = true, double dBSNR = 99.);

  Q_SLOT void stop () {Q_EMIT stateChanged ((m_state = Idle));}

  bool isTuning () const {return m_tuning;}
  Q_SLOT void tune (bool newState = true) {m_tuning = newState;}

  bool isMuted () const {return m_muted;}
  Q_SLOT void mute (bool newState = true) {m_muted = newState;}

  unsigned frequency () const {return m_frequency;}
  Q_SLOT void setFrequency (unsigned newFrequency) {m_frequency = newFrequency;}

  enum ModulatorState {Synchronizing, Active, Idle};
  Q_SIGNAL void stateChanged (ModulatorState);
  bool isActive () const {return m_state != Idle;}

  bool isSequential () const {return true;}

protected:
  qint64 readData (char * data, qint64 maxSize);
  qint64 writeData (char const * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't consume data
  }

private:
  typedef struct
  {
    qint16 channel[NUM_CHANNELS];
  } frame_t;

  frame_t postProcessFrame (frame_t frame) const;

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
};

#endif
