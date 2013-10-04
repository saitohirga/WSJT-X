#ifndef DETECTOR_HPP__
#define DETECTOR_HPP__

#include "AudioDevice.hpp"

#include <QScopedArrayPointer>

//
// output device that distributes data in predefined chunks via a signal
//
// the underlying device for this abstraction is just the buffer that
// stores samples throughout a receiving period
//
class Detector : public AudioDevice
{
  Q_OBJECT;

  Q_PROPERTY (bool monitoring READ isMonitoring WRITE setMonitoring);

public:
  //
  // if the data buffer were not global storage and fixed size then we
  // might want maximum size passed as constructor arguments
  //
  // we down sample by a factor of 4
  //
  // the framesPerSignal argument is the number after down sampling
  //
  Detector (unsigned frameRate, unsigned periodLengthInSeconds, unsigned framesPerSignal, unsigned downSampleFactor = 4u, QObject * parent = 0);

  bool isMonitoring () const {return m_monitoring;}

protected:
  qint64 readData (char * /* data */, qint64 /* maxSize */)
  {
    return -1;			// we don't produce data
  }

  qint64 writeData (char const * data, qint64 maxSize);

private:
  // these are private because we want thread safety, must be called via Qt queued connections
  Q_SLOT void open (AudioDevice::Channel channel = Mono) {AudioDevice::open (QIODevice::WriteOnly, channel);}
  Q_SLOT void setMonitoring (bool newState) {m_monitoring = newState; m_bufferPos = 0;}
  Q_SLOT bool reset ();
  Q_SLOT void close () {AudioDevice::close ();}

  Q_SIGNAL void framesWritten (qint64);

  void clear ();		// discard buffer contents
  unsigned secondInPeriod () const;

  unsigned m_frameRate;
  unsigned m_period;
  unsigned m_downSampleFactor;
  qint32 m_framesPerSignal;	// after any down sampling
  bool volatile m_monitoring;
  bool m_starting;
  QScopedArrayPointer<short> m_buffer; // de-interleaved sample buffer
				       // big enough for all the
				       // samples for one increment of
				       // data (a signals worth) at
				       // the input sample rate
  unsigned m_bufferPos;
};

#endif
