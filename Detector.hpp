#ifndef DETECTOR_HPP__
#define DETECTOR_HPP__

#include <stdint.h>

#include <QIODevice>

//
// output device that distributes data in predefined chunks via a signal
//
// the underlying device for this abstraction is just the buffer that
// stores samples throughout a receiving period
//
class Detector : public QIODevice
{
  Q_OBJECT;

  Q_PROPERTY (bool monitoring READ isMonitoring WRITE setMonitoring);

private:
  Q_DISABLE_COPY (Detector);

public:
  //
  // if the data buffer were not global storage and fixed size then we
  // might want maximum size passed as constructor arguments
  //
  Detector (unsigned frameRate, unsigned periodLengthInSeconds, unsigned bytesPerSignal, QObject * parent = 0);

  bool open ()
  {
    // we only support data consumption and want it as fast as possible
    return QIODevice::open (QIODevice::WriteOnly | QIODevice::Unbuffered);
  }

  bool isSequential () const
  {
    return true;
  }

  bool isMonitoring () const {return m_monitoring;}
  void setMonitoring (bool newState) {m_monitoring = newState;}

  bool reset ();

protected:
  qint64 readData (char * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't produce data
  }

  qint64 writeData (char const * data, qint64 maxSize);

private:
  typedef qint16 frame_t;

  void clear ();		// discard buffer contents
  unsigned secondInPeriod () const;

  unsigned m_frameRate;
  unsigned m_period;
  unsigned m_bytesPerSignal;
  bool m_monitoring;
  bool m_starting;
};

#endif
