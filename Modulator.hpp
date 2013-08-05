#ifndef MODULATOR_HPP__
#define MODULATOR_HPP__

#include <vector>

#include <QIODevice>
#include <QScopedPointer>

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

  bool isTuning () const {return m_tuning;}
  Q_SLOT void tune (bool newState = true) {m_tuning = newState;}

  bool isMuted () const {return m_muted;}
  Q_SLOT void mute (bool newState = true) {m_muted = newState;}

  unsigned frequency () const {return m_frequency;}
  Q_SLOT void setFrequency (unsigned newFrequency) {m_frequency = newFrequency;}

  bool open (std::vector<int> const * symbols, std::vector<int> const * cw, double framesPerSymbol, unsigned frequency, double dBSNR = 99.);

  bool isSequential () const
  {
    return true;
  }

protected:
  qint64 readData (char * data, qint64 maxSize);
  qint64 writeData (char const * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't consume data
  }

private:
  typedef short frame_t;

  frame_t postProcessFrame (frame_t frame) const;

  QScopedPointer<std::vector<int> const> m_symbols;
  QScopedPointer<std::vector<int> const> m_cw;

  static double const m_twoPi;
  static unsigned const m_nspd;	// CW ID WPM factor

  int m_frameRate;
  int m_period;
  double m_nsps;
  double m_frequency;
  double m_snr;
  enum {Idle, Active, Done} m_state;
  bool m_tuning;
  bool m_muted;
  bool m_addNoise;
  double m_phi;
  double m_dphi;
  double m_amp;
  unsigned m_ic;
  double m_fac;
  unsigned m_isym0;
};

#endif
