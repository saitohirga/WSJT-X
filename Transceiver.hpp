#ifndef TRANSCEIVER_HPP__
#define TRANSCEIVER_HPP__

#include <QObject>

#include "qt_helpers.hpp"
#include "Radio.hpp"

class QString;

//
// Abstract Transceiver Interface
//
//  This is  the minimal  generic interface  to a  rig as  required by
//  wsjtx.
//
// Responsibilities
//
//  Provides  Qt slots  to set  the frequency,  mode and  PTT of  some
//  transceiver. They are Qt slots so  that they may be invoked across
//  a thread boundary.
//
//  Provides a synchronisation Qt slot  which should be implemented in
//  sub-classes in such a way that  normal operation of the rig is not
//  disturbed.  This  is  intended  to   be  use  to  poll  rig  state
//  periodically and changing  VFO to read the other  VFO frequency or
//  mode for  example should  not be  done since  the operator  may be
//  tuning the VFO at the time and would be surprised by an unprompted
//  VFO change.
//
//  Provides a control interface using Qt  slots to start and stop the
//  rig control and PTT connections.
//
//  These  are Qt  slots rather  than the  constructor and  destructor
//  because   it   is   expected   that   the   concrete   Transceiver
//  implementations will run in a  separate thread from where they are
//  constructed.
//
//  Qt signals are defined to notify clients of asynchronous rig state
//  changes and failures.  These can and are expected  to cross thread
//  boundaries.
//
//  A  signal   finished()  is   defined  that   concrete  Transceiver
//  implementations must emit when they are ripe for destruction. This
//  is  intended to  be  used  by clients  that  move the  Transceiver
//  instance to  a thread  and need  to use  QObject::deleteLater() to
//  safely dispose of the Transceiver instance. Implementations should
//  expect Qt  slot calls  after emitting  finished, it  is up  to the
//  implementation whether these slot invocations are ignored.
//
class Transceiver
  : public QObject
{
  Q_OBJECT;
  Q_ENUMS (MODE);

public:
  using Frequency = Radio::Frequency;

protected:
  Transceiver ()
  {
  }

public:
  virtual ~Transceiver ()
  {
  }

  enum MODE {UNK, CW, CW_R, USB, LSB, FSK, FSK_R, DIG_U, DIG_L, AM, FM, DIG_FM};

  //
  // Aggregation of all of the rig and PTT state accessible via this
  // interface.
  class TransceiverState
  {
  public:
    TransceiverState ()
      : online_ {false}
      , frequency_ {0, 0}
      , mode_ {UNK}
      , split_ {unknown}
      , ptt_ {false}
    {
    }

    bool online () const {return online_;}
    Frequency frequency () const {return frequency_[0];}
    Frequency tx_frequency () const {return frequency_[1];}
    bool split () const {return on == split_;}
    MODE mode () const {return mode_;}
    bool ptt () const {return ptt_;}

    void online (bool state) {online_ = state;}
    void frequency (Frequency f) {frequency_[0] = f;}
    void tx_frequency (Frequency f) {frequency_[1] = f;}
    void split (bool state) {split_ = state ? on : off;}
    void mode (MODE m) {mode_ = m;}
    void ptt (bool state) {ptt_ = state;}

  private:
    bool online_;
    Frequency frequency_[2];  // [0] -> Rx; [1] -> Other
    MODE mode_;
    enum {unknown, off, on} split_;
    bool ptt_;
    // Don't forget to update the debug print and != operator if you
    // add more members here

    friend QDebug operator << (QDebug, TransceiverState const&);
    friend bool operator != (TransceiverState const&, TransceiverState const&);
  };

  //
  // The following slots and signals are expected to all run in the
  // same thread which is not necessarily the main GUI thread. It is
  // up to the client of the Transceiver class to organise the
  // allocation to a thread and the lifetime of the object instances.
  //

  // Connect and disconnect.
  Q_SLOT virtual void start () noexcept = 0;
  Q_SLOT virtual void stop () noexcept = 0;

  // Ready to be destroyed.
  Q_SIGNAL void finished () const;

  // Set frequency in Hertz.
  Q_SLOT virtual void frequency (Frequency, MODE = UNK) noexcept = 0;

  // Setting a non-zero TX frequency means split operation, the value
  // zero means simplex operation.
  //
  // Rationalise_mode means ensure TX uses same mode as RX.
  Q_SLOT virtual void tx_frequency (Frequency tx = 0, bool rationalise_mode = true) noexcept = 0;

  // Set mode.
  // Rationalise means ensure TX uses same mode as RX.
  Q_SLOT virtual void mode (MODE, bool rationalise = true) noexcept = 0;

  // Set/unset PTT.
  Q_SLOT virtual void ptt (bool = true) noexcept = 0;

  // Attempt to re-synchronise or query state.
  // Force_signal guarantees a update or failure signal.
  Q_SLOT virtual void sync (bool force_signal = false) noexcept = 0;

  // asynchronous status updates
  Q_SIGNAL void update (Transceiver::TransceiverState) const;
  Q_SIGNAL void failure (QString reason) const;
};

Q_DECLARE_METATYPE (Transceiver::TransceiverState);
Q_DECLARE_METATYPE (Transceiver::MODE);

#if !defined (QT_NO_DEBUG_STREAM)
ENUM_QDEBUG_OPS_DECL (Transceiver, MODE);

QDebug operator << (QDebug, Transceiver::TransceiverState const&);
#endif

ENUM_QDATASTREAM_OPS_DECL (Transceiver, MODE);

ENUM_CONVERSION_OPS_DECL (Transceiver, MODE);

bool operator != (Transceiver::TransceiverState const&, Transceiver::TransceiverState const&);
bool operator == (Transceiver::TransceiverState const&, Transceiver::TransceiverState const&);

#endif
