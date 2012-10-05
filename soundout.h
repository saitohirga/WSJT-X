#ifndef SOUNDOUT_H
#define SOUNDOUT_H
#include <QtCore>
#include <QDebug>

// An instance of this thread sends audio data to a specified soundcard.
// Output can be muted while underway, preserving waveform timing when
// transmission is resumed.

class SoundOutThread : public QThread
{
  Q_OBJECT

protected:
  virtual void run();

public:
// Constructs (but does not start) a SoundOutThread
  SoundOutThread()
    :   quitExecution(false)           // Initialize some private members
    ,   m_txOK(false)
    ,   m_txMute(false)
  {
  }

public:
  void setOutputDevice(qint32 n);
  void setPeriod(int ntrperiod, int nsps);
  bool quitExecution;           //If true, thread exits gracefully

// Private members
private:
  qint32  m_nDevOut;            //Output device number
  bool    m_txOK;               //Enable Tx audio
  bool    m_txMute;             //Mute temporarily
  qint32  m_TRperiod;           //T/R period (s)
  qint32  m_nsps;               //Samples per symbol (at 12000 Hz)
};

#endif
